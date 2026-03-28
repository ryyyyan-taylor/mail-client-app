package com.mail.client.worker

import android.Manifest
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters
import com.mail.client.MainActivity
import com.mail.client.data.local.SettingsPrefs
import com.mail.client.data.repository.AuthRepository
import com.mail.client.data.repository.MailRepository
import com.mail.client.util.EmailParser
import org.koin.core.component.KoinComponent
import org.koin.core.component.inject

const val NOTIFICATION_CHANNEL_ID = "new_mail"

class SyncWorker(
    appContext: Context,
    params: WorkerParameters,
) : CoroutineWorker(appContext, params), KoinComponent {

    private val authRepository: AuthRepository by inject()
    private val mailRepository: MailRepository by inject()
    private val settingsPrefs: SettingsPrefs by lazy { SettingsPrefs(applicationContext) }

    override suspend fun doWork(): Result {
        if (!authRepository.isSignedIn()) return Result.success()

        return try {
            val knownIds = mailRepository.getInboxIds().toSet()

            mailRepository.syncInbox()

            // Skip notifications on first sync (no baseline) or when disabled by user
            if (knownIds.isEmpty() || !settingsPrefs.notificationsEnabled) return Result.success()

            val newIds = mailRepository.getInboxIds().toSet() - knownIds
            newIds.forEach { id ->
                val thread = mailRepository.getThreadById(id) ?: return@forEach
                notifyNewThread(
                    id = thread.id,
                    sender = EmailParser.displayName(thread.from).ifEmpty { thread.from },
                    subject = thread.subject,
                )
            }

            Result.success()
        } catch (_: Exception) {
            Result.retry()
        }
    }

    private fun notifyNewThread(id: String, sender: String, subject: String) {
        if (ContextCompat.checkSelfPermission(
                applicationContext,
                Manifest.permission.POST_NOTIFICATIONS,
            ) != PackageManager.PERMISSION_GRANTED
        ) return

        val tapIntent = Intent(applicationContext, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra(MainActivity.EXTRA_THREAD_ID, id)
        }
        val pendingIntent = PendingIntent.getActivity(
            applicationContext,
            id.hashCode(),
            tapIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        val notification = NotificationCompat.Builder(applicationContext, NOTIFICATION_CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_dialog_email)
            .setContentTitle(sender)
            .setContentText(subject)
            .setContentIntent(pendingIntent)
            .setAutoCancel(true)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .build()

        NotificationManagerCompat.from(applicationContext).notify(id.hashCode(), notification)
    }
}
