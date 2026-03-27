package com.mail.client.ui.inbox

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.mail.client.data.local.ThreadEntity
import com.mail.client.data.repository.MailRepository
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.launchIn
import kotlinx.coroutines.flow.onEach
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

data class InboxUiState(
    val threads: List<ThreadEntity> = emptyList(),
    val isLoading: Boolean = false,
    val isRefreshing: Boolean = false,
    val error: String? = null,
    val nextPageToken: String? = null,
    val isLoadingMore: Boolean = false,
)

class InboxViewModel(
    private val mailRepository: MailRepository,
) : ViewModel() {

    private val _uiState = MutableStateFlow(InboxUiState())
    val uiState: StateFlow<InboxUiState> = _uiState.asStateFlow()

    init {
        // Observe Room cache — UI always reflects local DB
        mailRepository.observeInbox()
            .onEach { threads ->
                _uiState.update { it.copy(threads = threads) }
            }
            .launchIn(viewModelScope)

        // Initial sync on launch
        syncInbox(isRefresh = false)
    }

    fun refresh() {
        syncInbox(isRefresh = true)
    }

    fun loadNextPage() {
        val state = _uiState.value
        if (state.isLoadingMore || state.nextPageToken == null) return
        viewModelScope.launch {
            _uiState.update { it.copy(isLoadingMore = true) }
            try {
                val nextToken = mailRepository.syncInbox(pageToken = state.nextPageToken)
                _uiState.update { it.copy(nextPageToken = nextToken, isLoadingMore = false) }
            } catch (e: Exception) {
                _uiState.update { it.copy(isLoadingMore = false, error = e.message) }
            }
        }
    }

    fun clearError() {
        _uiState.update { it.copy(error = null) }
    }

    private fun syncInbox(isRefresh: Boolean) {
        viewModelScope.launch {
            _uiState.update {
                if (isRefresh) it.copy(isRefreshing = true, error = null)
                else it.copy(isLoading = it.threads.isEmpty(), error = null)
            }
            try {
                val nextToken = mailRepository.syncInbox(pageToken = null)
                _uiState.update {
                    it.copy(
                        isLoading = false,
                        isRefreshing = false,
                        nextPageToken = nextToken,
                    )
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
