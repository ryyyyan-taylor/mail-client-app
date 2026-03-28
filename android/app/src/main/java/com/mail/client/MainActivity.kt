package com.mail.client

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInHorizontally
import androidx.compose.animation.slideOutHorizontally
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.Text
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import android.content.res.Configuration
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.sp
import androidx.core.content.ContextCompat
import com.mail.client.data.repository.AuthRepository
import com.mail.client.ui.auth.SignInScreen
import com.mail.client.ui.inbox.InboxScreen
import com.mail.client.ui.thread.ThreadDetailScreen
import com.mail.client.ui.theme.Black
import com.mail.client.ui.theme.MailClientTheme
import com.mail.client.ui.theme.TextDisabled
import kotlinx.coroutines.delay
import org.koin.android.ext.android.inject

private sealed class NavScreen {
    object Splash : NavScreen()
    object Auth : NavScreen()
    object Inbox : NavScreen()
    data class Thread(val threadId: String) : NavScreen()
}

class MainActivity : ComponentActivity() {

    private val authRepository: AuthRepository by inject()

    // Updated from onNewIntent when a notification is tapped while the app is running
    private var notificationThreadId by mutableStateOf<String?>(null)

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        notificationThreadId = intent.getStringExtra(EXTRA_THREAD_ID)
        enableEdgeToEdge()
        setContent {
            MailClientTheme {

                // Request POST_NOTIFICATIONS permission on first run (Android 13+)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    val context = LocalContext.current
                    val permissionLauncher = rememberLauncherForActivityResult(
                        ActivityResultContracts.RequestPermission()
                    ) { /* user chose granted or denied — notifications silently skipped if denied */ }
                    LaunchedEffect(Unit) {
                        if (ContextCompat.checkSelfPermission(
                                context,
                                Manifest.permission.POST_NOTIFICATIONS,
                            ) != PackageManager.PERMISSION_GRANTED
                        ) {
                            permissionLauncher.launch(Manifest.permission.POST_NOTIFICATIONS)
                        }
                    }
                }

                val isLandscape = LocalConfiguration.current.orientation == Configuration.ORIENTATION_LANDSCAPE

                var splashDone by remember { mutableStateOf(false) }
                var isSignedIn by remember { mutableStateOf(false) }
                var openThreadId by remember { mutableStateOf<String?>(null) }

                // Brief splash delay so the dark background paints before auth check resolves
                LaunchedEffect(Unit) {
                    delay(350)
                    isSignedIn = authRepository.isSignedIn()
                    splashDone = true
                }

                // When a notification is tapped, navigate directly to that thread
                LaunchedEffect(notificationThreadId) {
                    notificationThreadId?.let { openThreadId = it }
                }

                val screen: NavScreen = when {
                    !splashDone -> NavScreen.Splash
                    !isSignedIn -> NavScreen.Auth
                    openThreadId != null && !isLandscape -> NavScreen.Thread(openThreadId!!)
                    else -> NavScreen.Inbox
                }

                AnimatedContent(
                    targetState = screen,
                    transitionSpec = {
                        when {
                            initialState is NavScreen.Auth || targetState is NavScreen.Thread ->
                                slideInHorizontally(
                                    tween(280, easing = FastOutSlowInEasing)
                                ) { it / 7 } + fadeIn(tween(220)) togetherWith
                                        fadeOut(tween(180))
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
                        NavScreen.Splash -> Box(
                            modifier = Modifier.fillMaxSize(),
                            contentAlignment = Alignment.Center,
                        ) {
                            Text(
                                text = "mail",
                                color = TextDisabled,
                                fontSize = 18.sp,
                                fontWeight = FontWeight.Light,
                                letterSpacing = 4.sp,
                            )
                        }

                        NavScreen.Auth -> SignInScreen(
                            authRepository = authRepository,
                            onSignedIn = { isSignedIn = true },
                        )

                        NavScreen.Inbox -> InboxScreen(
                            onThreadClick = { threadId -> openThreadId = threadId },
                            onSignOut = {
                                openThreadId = null
                                isSignedIn = false
                            },
                            initialSelectedThreadId = if (isLandscape) openThreadId else null,
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

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        intent.getStringExtra(EXTRA_THREAD_ID)?.let { notificationThreadId = it }
    }

    companion object {
        const val EXTRA_THREAD_ID = "extra_thread_id"
    }
}
