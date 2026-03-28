package com.mail.client.ui.settings

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.mail.client.data.local.SettingsPrefs
import com.mail.client.data.repository.AuthRepository
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch

data class SettingsUiState(
    val email: String = "",
    val syncIntervalMinutes: Int = SettingsPrefs.DEFAULT_SYNC_INTERVAL,
    val notificationsEnabled: Boolean = true,
)

class SettingsViewModel(
    private val authRepository: AuthRepository,
    private val settingsPrefs: SettingsPrefs,
) : ViewModel() {

    private val _uiState = MutableStateFlow(
        SettingsUiState(
            email = authRepository.getSignedInEmail() ?: "",
            syncIntervalMinutes = settingsPrefs.syncIntervalMinutes,
            notificationsEnabled = settingsPrefs.notificationsEnabled,
        )
    )
    val uiState: StateFlow<SettingsUiState> = _uiState

    fun setSyncInterval(minutes: Int) {
        settingsPrefs.syncIntervalMinutes = minutes
        _uiState.value = _uiState.value.copy(syncIntervalMinutes = minutes)
    }

    fun setNotificationsEnabled(enabled: Boolean) {
        settingsPrefs.notificationsEnabled = enabled
        _uiState.value = _uiState.value.copy(notificationsEnabled = enabled)
    }

    fun signOut(onComplete: () -> Unit) {
        viewModelScope.launch {
            authRepository.signOut()
            onComplete()
        }
    }
}
