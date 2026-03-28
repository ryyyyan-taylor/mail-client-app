package com.mail.client

import android.app.Application
import android.app.NotificationChannel
import android.app.NotificationManager
import androidx.work.BackoffPolicy
import androidx.work.Constraints
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.NetworkType
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import com.mail.client.data.local.SettingsPrefs
import com.mail.client.di.appModule
import com.mail.client.worker.NOTIFICATION_CHANNEL_ID
import com.mail.client.worker.SyncWorker
import org.koin.android.ext.koin.androidContext
import org.koin.core.context.startKoin
import java.util.concurrent.TimeUnit

class MailClientApp : Application() {

    override fun onCreate() {
        super.onCreate()
        startKoin {
            androidContext(this@MailClientApp)
            modules(appModule)
        }
        createNotificationChannel()
        scheduleSyncWorker()
    }

    private fun createNotificationChannel() {
        val channel = NotificationChannel(
            NOTIFICATION_CHANNEL_ID,
            "New Mail",
            NotificationManager.IMPORTANCE_DEFAULT,
        ).apply {
            description = "Notifications for new emails"
        }
        getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
    }

    private fun scheduleSyncWorker() {
        val intervalMinutes = SettingsPrefs(this).syncIntervalMinutes.toLong()
        val request = PeriodicWorkRequestBuilder<SyncWorker>(intervalMinutes, TimeUnit.MINUTES)
            .setConstraints(
                Constraints.Builder()
                    .setRequiredNetworkType(NetworkType.CONNECTED)
                    .build()
            )
            .setBackoffCriteria(BackoffPolicy.EXPONENTIAL, 1, TimeUnit.MINUTES)
            .build()

        // UPDATE: applies the new interval at the next run without resetting the current timer
        WorkManager.getInstance(this).enqueueUniquePeriodicWork(
            SYNC_WORK_NAME,
            ExistingPeriodicWorkPolicy.UPDATE,
            request,
        )
    }

    companion object {
        const val SYNC_WORK_NAME = "mail_sync"
    }
}
