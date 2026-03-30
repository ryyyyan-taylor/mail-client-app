package com.mail.client.data.repository

import com.mail.client.data.local.LabelDao
import com.mail.client.data.local.LabelEntity
import com.mail.client.data.local.MessageDao
import com.mail.client.data.local.MessageEntity
import com.mail.client.data.local.ThreadDao
import com.mail.client.data.local.ThreadEntity
import com.mail.client.data.remote.GmailApiService
import com.mail.client.data.remote.dto.MessageDto
import com.mail.client.data.remote.dto.ModifyRequest
import com.mail.client.data.remote.dto.ThreadDetailDto
import com.mail.client.util.EmailParser
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitAll
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.flow.Flow

class MailRepository(
    private val api: GmailApiService,
    private val threadDao: ThreadDao,
    private val messageDao: MessageDao,
    private val labelDao: LabelDao,
) {

    // ── Observe (UI subscribes to these) ─────────────────────────────────────

    fun observeInbox(): Flow<List<ThreadEntity>> = threadDao.observeInbox()

    fun observeForLabel(labelId: String): Flow<List<ThreadEntity>> =
        threadDao.observeForLabel("%$labelId%")

    fun observeMessages(threadId: String): Flow<List<MessageEntity>> =
        messageDao.observeForThread(threadId)

    suspend fun getInboxIds(): List<String> = threadDao.getInboxIds()

    suspend fun getThreadById(id: String): ThreadEntity? = threadDao.getById(id)

    // ── Sync inbox from API ───────────────────────────────────────────────────

    /**
     * Fetch threads for the given label from the Gmail API and cache in Room.
     * Uses format=metadata (fast, no body). Returns the nextPageToken if more pages exist.
     */
    suspend fun syncSection(labelId: String, pageToken: String? = null): String? {
        val response = api.listThreads(labelId = labelId, pageToken = pageToken, maxResults = 50)
        val summaries = response.threads ?: return null

        val entities = coroutineScope {
            summaries.map { summary ->
                async {
                    try {
                        api.getThread(summary.id, format = "metadata").toThreadEntity()
                    } catch (e: Exception) {
                        null
                    }
                }
            }.awaitAll().filterNotNull()
        }

        threadDao.insertAll(entities)
        return response.nextPageToken
    }

    /** Convenience wrapper used by SyncWorker. */
    suspend fun syncInbox(pageToken: String? = null): String? = syncSection("INBOX", pageToken)

    // ── Load full thread (opens message bodies) ───────────────────────────────

    /**
     * Fetch a thread with full message bodies from the API and cache in Room.
     * Called when the user opens a thread.
     */
    suspend fun loadFullThread(threadId: String) {
        val detail = api.getThread(threadId, format = "full")

        // Update the thread entity with the fresh data
        threadDao.insertAll(listOf(detail.toThreadEntity()))

        // Replace messages atomically — @Transaction prevents the Flow from emitting
        // an intermediate empty state, which would briefly re-show the spinner on revisit.
        val messages = detail.messages?.map { it.toMessageEntity() } ?: emptyList()
        messageDao.replaceForThread(threadId, messages)
    }

    // ── Thread actions ────────────────────────────────────────────────────────

    suspend fun archiveThread(threadId: String) {
        api.modifyThread(threadId, ModifyRequest(removeLabelIds = listOf("INBOX")))
        updateLocalLabels(threadId, add = emptyList(), remove = listOf("INBOX"))
    }

    suspend fun trashThread(threadId: String) {
        api.trashThread(threadId)
        val thread = threadDao.getById(threadId) ?: return
        threadDao.delete(thread)
    }

    suspend fun spamThread(threadId: String) {
        api.modifyThread(threadId, ModifyRequest(
            addLabelIds = listOf("SPAM"),
            removeLabelIds = listOf("INBOX"),
        ))
        val thread = threadDao.getById(threadId) ?: return
        threadDao.delete(thread)
    }

    suspend fun markRead(threadId: String) {
        api.modifyThread(threadId, ModifyRequest(removeLabelIds = listOf("UNREAD")))
        updateLocalLabels(threadId, add = emptyList(), remove = listOf("UNREAD"))
    }

    suspend fun markUnread(threadId: String) {
        api.modifyThread(threadId, ModifyRequest(addLabelIds = listOf("UNREAD")))
        updateLocalLabels(threadId, add = listOf("UNREAD"), remove = emptyList())
    }

    suspend fun moveThread(threadId: String, addLabels: List<String>, removeLabels: List<String>) {
        api.modifyThread(threadId, ModifyRequest(
            addLabelIds = addLabels,
            removeLabelIds = removeLabels,
        ))
        updateLocalLabels(threadId, add = addLabels, remove = removeLabels)
    }

    // ── Labels ────────────────────────────────────────────────────────────────

    private var lastLabelSyncMs = 0L

    suspend fun syncLabels(force: Boolean = false) {
        val now = System.currentTimeMillis()
        if (!force && lastLabelSyncMs > 0 && now - lastLabelSyncMs < LABEL_SYNC_THROTTLE_MS) return
        val response = api.listLabels()
        val entities = response.labels
            ?.mapNotNull { dto ->
                val name = dto.name ?: return@mapNotNull null
                LabelEntity(dto.id, name, dto.type ?: "")
            }
            ?: return
        labelDao.insertAll(entities)
        lastLabelSyncMs = now
    }

    companion object {
        private const val LABEL_SYNC_THROTTLE_MS = 60 * 60 * 1000L // 1 hour
    }

    suspend fun getLabels(): List<LabelEntity> = labelDao.getAll()

    // ── Private helpers ───────────────────────────────────────────────────────

    private suspend fun updateLocalLabels(
        threadId: String,
        add: List<String>,
        remove: List<String>,
    ) {
        val thread = threadDao.getById(threadId) ?: return
        val current: MutableSet<String> = if (thread.labelIds.isBlank()) mutableSetOf()
                      else thread.labelIds.split(",").toMutableSet()
        current.addAll(add)
        current.removeAll(remove.toSet())
        val isRead = "UNREAD" !in current
        threadDao.insertAll(listOf(thread.copy(labelIds = current.joinToString(","), isRead = isRead)))
    }
}

// ── DTO → Entity mappers ──────────────────────────────────────────────────────

fun ThreadDetailDto.toThreadEntity(): ThreadEntity {
    val messages = this.messages ?: emptyList()
    val last = messages.lastOrNull()
    val headers = last?.payload?.headers

    val subject = EmailParser.extractHeader(headers, "Subject").ifEmpty { "(no subject)" }
    val from = EmailParser.extractHeader(headers, "From")
    val timestamp = last?.internalDate?.toLongOrNull() ?: 0L

    val allLabels = messages.flatMap { it.labelIds ?: emptyList() }.toSet()
    val isRead = "UNREAD" !in allLabels

    return ThreadEntity(
        id = id,
        snippet = snippet ?: "",
        historyId = historyId ?: "",
        subject = subject,
        from = from,
        labelIds = allLabels.joinToString(","),
        lastMessageTimestamp = timestamp,
        messageCount = messages.size,
        isRead = isRead,
    )
}

fun MessageDto.toMessageEntity(): MessageEntity {
    val headers = payload?.headers
    val from = EmailParser.extractHeader(headers, "From")
    val to = EmailParser.extractHeader(headers, "To")
    val subject = EmailParser.extractHeader(headers, "Subject").ifEmpty { "(no subject)" }
    val date = internalDate?.toLongOrNull() ?: 0L
    val labels = labelIds?.joinToString(",") ?: ""
    val isRead = "UNREAD" !in (labelIds ?: emptyList())
    val body = EmailParser.extractBody(payload)

    return MessageEntity(
        id = id,
        threadId = threadId ?: "",
        from = from,
        to = to,
        subject = subject,
        snippet = snippet ?: "",
        body = body,
        date = date,
        labelIds = labels,
        isRead = isRead,
    )
}
