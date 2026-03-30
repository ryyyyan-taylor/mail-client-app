package com.mail.client.ui.thread

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.mail.client.data.local.LabelEntity
import com.mail.client.data.local.MessageEntity
import com.mail.client.data.repository.MailRepository
import kotlinx.coroutines.async
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.launchIn
import kotlinx.coroutines.flow.onEach
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

data class ThreadDetailUiState(
    val subject: String = "",
    val messages: List<MessageEntity> = emptyList(),
    val isLoading: Boolean = true,
    val error: String? = null,
    val isRead: Boolean = true,
    val availableLabels: List<LabelEntity> = emptyList(),
    val navigateBack: Boolean = false,
)

class ThreadDetailViewModel(
    private val threadId: String,
    private val mailRepository: MailRepository,
) : ViewModel() {

    private val _uiState = MutableStateFlow(ThreadDetailUiState())
    val uiState: StateFlow<ThreadDetailUiState> = _uiState.asStateFlow()

    init {
        mailRepository.observeMessages(threadId)
            .onEach { messages ->
                _uiState.update {
                    it.copy(
                        messages = messages,
                        subject = messages.firstOrNull()?.subject ?: it.subject,
                    )
                }
            }
            .launchIn(viewModelScope)

        viewModelScope.launch {
            try {
                // Load body and mark-read are independent — run in parallel
                coroutineScope {
                    async { mailRepository.loadFullThread(threadId) }
                    async { mailRepository.markRead(threadId) }
                }
            } catch (e: Exception) {
                _uiState.update { it.copy(error = e.message ?: "Failed to load thread") }
            } finally {
                _uiState.update { it.copy(isLoading = false) }
            }
        }

        loadLabels()
    }

    fun clearError() = _uiState.update { it.copy(error = null) }

    // ── Thread actions ─────────────────────────────────────────────────────────

    fun delete() {
        viewModelScope.launch {
            try {
                mailRepository.trashThread(threadId)
                _uiState.update { it.copy(navigateBack = true) }
            } catch (e: Exception) {
                _uiState.update { it.copy(error = "Failed to delete") }
            }
        }
    }

    fun spam() {
        viewModelScope.launch {
            try {
                mailRepository.spamThread(threadId)
                _uiState.update { it.copy(navigateBack = true) }
            } catch (e: Exception) {
                _uiState.update { it.copy(error = "Failed to mark as spam") }
            }
        }
    }

    fun toggleRead() {
        val currentlyRead = _uiState.value.isRead
        _uiState.update { it.copy(isRead = !currentlyRead) }
        viewModelScope.launch {
            try {
                if (currentlyRead) mailRepository.markUnread(threadId)
                else mailRepository.markRead(threadId)
            } catch (e: Exception) {
                _uiState.update { it.copy(isRead = currentlyRead, error = "Failed to update read state") }
            }
        }
    }

    fun moveToLabel(labelId: String) {
        viewModelScope.launch {
            try {
                mailRepository.moveThread(
                    threadId = threadId,
                    addLabels = listOf(labelId),
                    removeLabels = listOf("INBOX"),
                )
                _uiState.update { it.copy(navigateBack = true) }
            } catch (e: Exception) {
                _uiState.update { it.copy(error = "Failed to move thread") }
            }
        }
    }

    // ── Private ────────────────────────────────────────────────────────────────

    private fun loadLabels() {
        viewModelScope.launch {
            try { mailRepository.syncLabels() } catch (_: Exception) { }
            val labels = mailRepository.getLabels()
            _uiState.update { it.copy(availableLabels = labels) }
        }
    }
}
