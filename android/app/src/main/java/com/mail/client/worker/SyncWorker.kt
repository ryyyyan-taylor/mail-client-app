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
import com.mail.client.R
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

        val notificationId = id.hashCode()

        val tapIntent = Intent(applicationContext, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra(MainActivity.EXTRA_THREAD_ID, id)
        }
        val tapPendingIntent = PendingIntent.getActivity(
            applicationContext,
            notificationId,
            tapIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        val trashIntent = Intent(applicationContext, NotificationActionReceiver::class.java).apply {
            action = ACTION_TRASH_THREAD
            putExtra(MainActivity.EXTRA_THREAD_ID, id)
            putExtra(EXTRA_NOTIFICATION_ID, notificationId)
        }
        val trashPendingIntent = PendingIntent.getBroadcast(
            applicationContext,
            // Use a different request code from the tap intent to avoid collisions
            notificationId xor Int.MIN_VALUE,
            trashIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        val notification = NotificationCompat.Builder(applicationContext, NOTIFICATION_CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_notification_email)
            .setContentTitle(sender)
            .setContentText(subject)
            .setContentIntent(tapPendingIntent)
            .setAutoCancel(true)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .addAction(
                android.R.drawable.ic_menu_delete,
                "Delete",
                trashPendingIntent,
            )
            .build()

        NotificationManagerCompat.from(applicationContext).notify(notificationId, notification)
    }
}
