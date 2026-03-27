package com.mail.client

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import com.mail.client.data.repository.AuthRepository
import com.mail.client.ui.auth.SignInScreen
import com.mail.client.ui.inbox.InboxScreen
import com.mail.client.ui.thread.ThreadDetailScreen
import com.mail.client.ui.theme.MailClientTheme
import org.koin.android.ext.android.inject

class MainActivity : ComponentActivity() {

    private val authRepository: AuthRepository by inject()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            MailClientTheme {
                var isSignedIn by remember { mutableStateOf(authRepository.isSignedIn()) }
                var openThreadId by remember { mutableStateOf<String?>(null) }

                when {
                    !isSignedIn -> SignInScreen(
                        authRepository = authRepository,
                        onSignedIn = { isSignedIn = true },
                    )

                    openThreadId != null -> ThreadDetailScreen(
                        threadId = openThreadId!!,
                        onBack = { openThreadId = null },
                    )

                    else -> InboxScreen(
                        onThreadClick = { threadId -> openThreadId = threadId },
                    )
                }
            }
        }
    }
}
