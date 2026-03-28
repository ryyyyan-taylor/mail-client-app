package com.mail.client.ui.inbox

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.mail.client.data.local.LabelEntity
import com.mail.client.data.local.ThreadEntity
import com.mail.client.data.repository.MailRepository
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.flatMapLatest
import kotlinx.coroutines.flow.launchIn
import kotlinx.coroutines.flow.onEach
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

data class Section(val labelId: String, val displayName: String)

val SYSTEM_SECTIONS = listOf(
    Section("INBOX", "inbox"),
    Section("SENT",  "sent"),
    Section("TRASH", "trash"),
    Section("SPAM",  "spam"),
)

data class InboxUiState(
    val threads: List<ThreadEntity> = emptyList(),
    val isLoading: Boolean = false,
    val isRefreshing: Boolean = false,
    val error: String? = null,
    val nextPageToken: String? = null,
    val isLoadingMore: Boolean = false,
    val availableLabels: List<LabelEntity> = emptyList(),
    val selectedIds: Set<String> = emptySet(),
    val currentSection: Section = SYSTEM_SECTIONS[0],
)

class InboxViewModel(
    private val mailRepository: MailRepository,
) : ViewModel() {

    private val _uiState = MutableStateFlow(InboxUiState())
    val uiState: StateFlow<InboxUiState> = _uiState.asStateFlow()

    // IDs hidden from the list while their undo snackbar is showing
    private val _hiddenIds = MutableStateFlow<Set<String>>(emptySet())

    private val _currentSection = MutableStateFlow(SYSTEM_SECTIONS[0])

    init {
        combine(
            _currentSection.flatMapLatest { section ->
                mailRepository.observeForLabel(section.labelId)
            },
            _hiddenIds,
        ) { threads, hiddenIds ->
            threads.filterNot { it.id in hiddenIds }
        }.onEach { filtered ->
            _uiState.update { it.copy(threads = filtered) }
        }.launchIn(viewModelScope)

        syncSection(isRefresh = false)
        loadLabels()
    }

    fun refresh() = syncSection(isRefresh = true)

    fun setSection(section: Section) {
        _currentSection.value = section
        _hiddenIds.value = emptySet()
        _uiState.update {
            it.copy(
                currentSection = section,
                selectedIds = emptySet(),
                nextPageToken = null,
                error = null,
            )
        }
        syncSection(isRefresh = false)
    }

    fun loadNextPage() {
        val state = _uiState.value
        if (state.isLoadingMore || state.nextPageToken == null) return
        val labelId = _currentSection.value.labelId
        viewModelScope.launch {
            _uiState.update { it.copy(isLoadingMore = true) }
            try {
                val nextToken = mailRepository.syncSection(labelId = labelId, pageToken = state.nextPageToken)
                _uiState.update { it.copy(nextPageToken = nextToken, isLoadingMore = false) }
            } catch (e: Exception) {
                _uiState.update { it.copy(isLoadingMore = false, error = e.message) }
            }
        }
    }

    fun clearError() = _uiState.update { it.copy(error = null) }

    // ── Thread actions ─────────────────────────────────────────────────────────

    fun hideThread(threadId: String) {
        _hiddenIds.update { it + threadId }
    }

    fun unhideThread(threadId: String) {
        _hiddenIds.update { it - threadId }
    }

    fun confirmDelete(threadId: String) {
        viewModelScope.launch {
            try {
                mailRepository.trashThread(threadId)
            } catch (e: Exception) {
                _hiddenIds.update { it - threadId }
                _uiState.update { it.copy(error = "Failed to delete") }
            }
        }
    }

    fun confirmMove(threadId: String, labelId: String) {
        viewModelScope.launch {
            try {
                mailRepository.moveThread(
                    threadId = threadId,
                    addLabels = listOf(labelId),
                    removeLabels = listOf("INBOX"),
                )
            } catch (e: Exception) {
                _hiddenIds.update { it - threadId }
                _uiState.update { it.copy(error = "Failed to move thread") }
            }
        }
    }

    // ── Batch selection ────────────────────────────────────────────────────────

    fun enterSelectionMode(threadId: String) {
        _uiState.update { it.copy(selectedIds = it.selectedIds + threadId) }
    }

    fun toggleSelection(threadId: String) {
        _uiState.update { state ->
            val ids = state.selectedIds
            state.copy(selectedIds = if (threadId in ids) ids - threadId else ids + threadId)
        }
    }

    fun exitSelectionMode() = _uiState.update { it.copy(selectedIds = emptySet()) }

    private fun hideSelectedAndClear(): Set<String> {
        val ids = _uiState.value.selectedIds.toSet()
        _hiddenIds.update { it + ids }
        _uiState.update { it.copy(selectedIds = emptySet()) }
        return ids
    }

    fun startBatchDelete() = hideSelectedAndClear()
    fun startBatchMove()   = hideSelectedAndClear()
    fun startBatchSpam()   = hideSelectedAndClear()

    fun confirmBatchDelete(ids: Set<String>) {
        viewModelScope.launch {
            ids.forEach { id ->
                try { mailRepository.trashThread(id) }
                catch (_: Exception) { /* best effort */ }
            }
        }
    }

    fun confirmBatchMove(ids: Set<String>, labelId: String) {
        viewModelScope.launch {
            ids.forEach { id ->
                try {
                    mailRepository.moveThread(
                        threadId = id,
                        addLabels = listOf(labelId),
                        removeLabels = listOf("INBOX"),
                    )
                } catch (e: Exception) {
                    _hiddenIds.update { it - id }
                    _uiState.update { it.copy(error = "Failed to move some threads") }
                }
            }
        }
    }

    fun confirmBatchSpam(ids: Set<String>) {
        viewModelScope.launch {
            ids.forEach { id ->
                try { mailRepository.spamThread(id) }
                catch (_: Exception) { /* best effort */ }
            }
        }
    }

    fun markSelectedRead() {
        val ids = _uiState.value.selectedIds.toSet()
        _uiState.update { it.copy(selectedIds = emptySet()) }
        viewModelScope.launch {
            ids.forEach { id ->
                try { mailRepository.markRead(id) }
                catch (_: Exception) { /* best effort */ }
            }
        }
    }

    fun markSelectedUnread() {
        val ids = _uiState.value.selectedIds.toSet()
        _uiState.update { it.copy(selectedIds = emptySet()) }
        viewModelScope.launch {
            ids.forEach { id ->
                try { mailRepository.markUnread(id) }
                catch (_: Exception) { /* best effort */ }
            }
        }
    }

    // ── Private ────────────────────────────────────────────────────────────────

    fun refreshLabels() {
        viewModelScope.launch {
            try {
                mailRepository.syncLabels(force = true)
            } catch (_: Exception) { /* fall through to cached */ }
            val labels = mailRepository.getLabels()
            _uiState.update { it.copy(availableLabels = labels) }
        }
    }

    private fun loadLabels() {
        viewModelScope.launch {
            try {
                mailRepository.syncLabels()
            } catch (_: Exception) { /* fall through to cached */ }
            val labels = mailRepository.getLabels()
            _uiState.update { it.copy(availableLabels = labels) }
        }
    }

    private fun syncSection(isRefresh: Boolean) {
        val labelId = _currentSection.value.labelId
        viewModelScope.launch {
            _uiState.update {
                if (isRefresh) it.copy(isRefreshing = true, error = null)
                else it.copy(isLoading = it.threads.isEmpty(), error = null)
            }
            try {
                val nextToken = mailRepository.syncSection(labelId = labelId, pageToken = null)
                _uiState.update {
                    it.copy(isLoading = false, isRefreshing = false, nextPageToken = nextToken)
                }
            } catch (e: Exception) {
                _uiState.update {
                    it.copy(
                        isLoading = false,
                        isRefreshing = false,
                        error = e.message ?: "Sync failed",
                    )
                }
            }
        }
    }
}
