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
    val availableLabels: List<LabelEntity> = emptyList(),
)

class InboxViewModel(
    private val mailRepository: MailRepository,
) : ViewModel() {

    private val _uiState = MutableStateFlow(InboxUiState())
    val uiState: StateFlow<InboxUiState> = _uiState.asStateFlow()

    // IDs hidden from the list while their undo snackbar is showing
    private val _hiddenIds = MutableStateFlow<Set<String>>(emptySet())

    init {
        combine(mailRepository.observeInbox(), _hiddenIds) { threads, hiddenIds ->
            threads.filterNot { it.id in hiddenIds }
        }.onEach { filtered ->
            _uiState.update { it.copy(threads = filtered) }
        }.launchIn(viewModelScope)

        syncInbox(isRefresh = false)
        loadLabels()
    }

    fun refresh() = syncInbox(isRefresh = true)

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

    fun clearError() = _uiState.update { it.copy(error = null) }

    // ── Thread actions ─────────────────────────────────────────────────────────

    /** Remove thread from the visible list immediately (optimistic). */
    fun hideThread(threadId: String) {
        _hiddenIds.update { it + threadId }
    }

    /** Restore a hidden thread — called on undo. */
    fun unhideThread(threadId: String) {
        _hiddenIds.update { it - threadId }
    }

    /** Trash the thread via API — called when the undo snackbar times out. */
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

    /**
     * Apply [labelId] to the thread and remove it from INBOX —
     * called when the undo snackbar times out.
     */
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

    // ── Private ────────────────────────────────────────────────────────────────

    private fun loadLabels() {
        viewModelScope.launch {
            try {
                mailRepository.syncLabels()
            } catch (_: Exception) { /* fall through to cached */ }
            val labels = mailRepository.getLabels()
            _uiState.update { it.copy(availableLabels = labels) }
        }
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
