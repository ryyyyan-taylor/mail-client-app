package com.mail.client.worker

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import androidx.core.app.NotificationManagerCompat
import com.mail.client.data.repository.MailRepository
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import org.koin.core.component.KoinComponent
import org.koin.core.component.inject

const val ACTION_TRASH_THREAD = "com.mail.client.action.TRASH_THREAD"
const val EXTRA_NOTIFICATION_ID = "extra_notification_id"

class NotificationActionReceiver : BroadcastReceiver(), KoinComponent {

    private val mailRepository: MailRepository by inject()

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != ACTION_TRASH_THREAD) return

        val threadId = intent.getStringExtra(com.mail.client.MainActivity.EXTRA_THREAD_ID) ?: return
        val notificationId = intent.getIntExtra(EXTRA_NOTIFICATION_ID, 0)

        // Cancel the notification immediately so the user gets instant feedback
        NotificationManagerCompat.from(context).cancel(notificationId)

        val pendingResult = goAsync()
        CoroutineScope(Dispatchers.IO).launch {
            try {
                mailRepository.trashThread(threadId)
            } finally {
                pendingResult.finish()
            }
        }
    }
}
