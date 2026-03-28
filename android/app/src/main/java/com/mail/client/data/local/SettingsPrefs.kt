package com.mail.client.data.local

import android.content.Context

class SettingsPrefs(context: Context) {

    private val prefs = context.getSharedPreferences("app_settings", Context.MODE_PRIVATE)

    var syncIntervalMinutes: Int
        get() = prefs.getInt(KEY_SYNC_INTERVAL, DEFAULT_SYNC_INTERVAL)
        set(value) { prefs.edit().putInt(KEY_SYNC_INTERVAL, value).apply() }

    var notificationsEnabled: Boolean
        get() = prefs.getBoolean(KEY_NOTIFICATIONS, true)
        set(value) { prefs.edit().putBoolean(KEY_NOTIFICATIONS, value).apply() }

    companion object {
        const val DEFAULT_SYNC_INTERVAL = 15
        private const val KEY_SYNC_INTERVAL = "sync_interval_minutes"
        private const val KEY_NOTIFICATIONS = "notifications_enabled"
    }
}
