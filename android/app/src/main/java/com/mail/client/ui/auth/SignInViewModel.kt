package com.mail.client.ui.auth

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.google.android.gms.auth.api.signin.GoogleSignIn
import com.google.android.gms.auth.api.signin.GoogleSignInAccount
import com.google.android.gms.common.api.ApiException
import com.google.android.gms.tasks.Task
import com.mail.client.data.repository.AuthRepository
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch

sealed class SignInState {
    object Idle : SignInState()
    object Loading : SignInState()
    object Success : SignInState()
    data class Error(val message: String) : SignInState()
}

class SignInViewModel(private val authRepository: AuthRepository) : ViewModel() {

    private val _state = MutableStateFlow<SignInState>(SignInState.Idle)
    val state: StateFlow<SignInState> = _state

    fun handleSignInResult(task: Task<GoogleSignInAccount>) {
        viewModelScope.launch {
            _state.value = SignInState.Loading
            try {
                val account = task.getResult(ApiException::class.java)
                authRepository.handleSignInResult(account)
                _state.value = SignInState.Success
            } catch (e: ApiException) {
                _state.value = SignInState.Error("Sign-in failed (code ${e.statusCode})")
            } catch (e: Exception) {
                _state.value = SignInState.Error(e.message ?: "Unknown error")
            }
        }
    }
}
