package com.mail.client

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInHorizontally
import androidx.compose.animation.slideOutHorizontally
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import com.mail.client.data.repository.AuthRepository
import com.mail.client.ui.auth.SignInScreen
import com.mail.client.ui.inbox.InboxScreen
import com.mail.client.ui.thread.ThreadDetailScreen
import com.mail.client.ui.theme.MailClientTheme
import org.koin.android.ext.android.inject

private sealed class NavScreen {
    object Auth : NavScreen()
    object Inbox : NavScreen()
    data class Thread(val threadId: String) : NavScreen()
}

class MainActivity : ComponentActivity() {

    private val authRepository: AuthRepository by inject()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            MailClientTheme {
                var isSignedIn by remember { mutableStateOf(authRepository.isSignedIn()) }
                var openThreadId by remember { mutableStateOf<String?>(null) }

                val screen: NavScreen = when {
                    !isSignedIn -> NavScreen.Auth
                    openThreadId != null -> NavScreen.Thread(openThreadId!!)
                    else -> NavScreen.Inbox
                }

                AnimatedContent(
                    targetState = screen,
                    transitionSpec = {
                        when {
                            // Forward: sign-in complete, or opening a thread
                            initialState is NavScreen.Auth || targetState is NavScreen.Thread ->
                                slideInHorizontally(
                                    tween(280, easing = FastOutSlowInEasing)
                                ) { it / 7 } + fadeIn(tween(220)) togetherWith
                                        fadeOut(tween(180))
                            // Back: closing a thread
                            else ->
                                fadeIn(tween(220)) togetherWith
                                        slideOutHorizontally(
                                            tween(280, easing = FastOutSlowInEasing)
                                        ) { it / 7 } + fadeOut(tween(180))
                        }
                    },
                    modifier = Modifier.fillMaxSize(),
                    label = "screenNav",
                ) { navScreen ->
                    when (navScreen) {
                        NavScreen.Auth -> SignInScreen(
                            authRepository = authRepository,
                            onSignedIn = { isSignedIn = true },
                        )
                        NavScreen.Inbox -> InboxScreen(
                            onThreadClick = { threadId -> openThreadId = threadId },
                        )
                        is NavScreen.Thread -> ThreadDetailScreen(
                            threadId = navScreen.threadId,
                            onBack = { openThreadId = null },
                        )
                    }
                }
            }
        }
    }
}
