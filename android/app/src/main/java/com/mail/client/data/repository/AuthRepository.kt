package com.mail.client.data.repository

import android.content.Context
import android.content.Intent
import com.google.android.gms.auth.GoogleAuthUtil
import com.google.android.gms.auth.api.signin.GoogleSignIn
import com.google.android.gms.auth.api.signin.GoogleSignInAccount
import com.google.android.gms.auth.api.signin.GoogleSignInOptions
import com.google.android.gms.common.api.Scope
import com.mail.client.data.local.TokenStorage
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

class AuthRepository(
    private val context: Context,
    private val tokenStorage: TokenStorage,
) {
    companion object {
        private val GMAIL_SCOPES = listOf(
            "https://www.googleapis.com/auth/gmail.readonly",
            "https://www.googleapis.com/auth/gmail.modify",
            "https://www.googleapis.com/auth/gmail.labels",
        )
        val SCOPE_STRING = "oauth2:${GMAIL_SCOPES.joinToString(" ")}"
    }

    private val signInClient by lazy {
        val options = GoogleSignInOptions.Builder(GoogleSignInOptions.DEFAULT_SIGN_IN)
            .requestEmail()
            .requestScopes(
                Scope(GMAIL_SCOPES[0]),
                *GMAIL_SCOPES.drop(1).map { Scope(it) }.toTypedArray(),
            )
            .build()
        GoogleSignIn.getClient(context, options)
    }

    fun getSignInIntent(): Intent = signInClient.signInIntent

    fun isSignedIn(): Boolean =
        GoogleSignIn.getLastSignedInAccount(context) != null && tokenStorage.isSignedIn()

    fun getSignedInEmail(): String? = tokenStorage.getAccountEmail()

    suspend fun handleSignInResult(account: GoogleSignInAccount) {
        withContext(Dispatchers.IO) {
            // Eagerly fetch the token to verify scopes are granted and cache it
            val androidAccount = account.account
                ?: error("No Android account on GoogleSignInAccount")
            GoogleAuthUtil.getToken(context, androidAccount, SCOPE_STRING)
            tokenStorage.saveAccountEmail(account.email ?: "")
        }
    }

    suspend fun getAccessToken(): String? {
        val account = GoogleSignIn.getLastSignedInAccount(context) ?: return null
        val androidAccount = account.account ?: return null
        return withContext(Dispatchers.IO) {
            try {
                GoogleAuthUtil.getToken(context, androidAccount, SCOPE_STRING)
            } catch (e: Exception) {
                null
            }
        }
    }

    // Call this after a 401 to force a token refresh on the next getAccessToken() call
    suspend fun invalidateToken() {
        val account = GoogleSignIn.getLastSignedInAccount(context) ?: return
        val androidAccount = account.account ?: return
        withContext(Dispatchers.IO) {
            try {
                val token = GoogleAuthUtil.getToken(context, androidAccount, SCOPE_STRING)
                GoogleAuthUtil.invalidateToken(context, token)
            } catch (e: Exception) {
                // best-effort
            }
        }
    }

    suspend fun signOut() {
        withContext(Dispatchers.IO) { tokenStorage.clear() }
        signInClient.signOut()
    }
}
