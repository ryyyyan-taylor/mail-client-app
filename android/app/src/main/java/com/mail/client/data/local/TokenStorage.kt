package com.mail.client.data.local

import android.content.Context
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey

class TokenStorage(context: Context) {

    private val masterKey = MasterKey.Builder(context)
        .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
        .build()

    private val prefs = EncryptedSharedPreferences.create(
        context,
        "mail_client_secure_prefs",
        masterKey,
        EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
        EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM,
    )

    fun saveAccountEmail(email: String) {
        prefs.edit().putString(KEY_EMAIL, email).apply()
    }

    fun getAccountEmail(): String? = prefs.getString(KEY_EMAIL, null)

    fun isSignedIn(): Boolean = getAccountEmail() != null

    fun clear() {
        prefs.edit().clear().apply()
    }

    companion object {
        private const val KEY_EMAIL = "account_email"
    }
}
