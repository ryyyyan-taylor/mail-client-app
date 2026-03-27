package com.mail.client.ui.thread

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.mail.client.data.local.MessageEntity
import com.mail.client.data.repository.MailRepository
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
                mailRepository.loadFullThread(threadId)
                mailRepository.markRead(threadId)
            } catch (e: Exception) {
                _uiState.update { it.copy(error = e.message ?: "Failed to load thread") }
            } finally {
                _uiState.update { it.copy(isLoading = false) }
            }
        }
    }

    fun clearError() = _uiState.update { it.copy(error = null) }
}
