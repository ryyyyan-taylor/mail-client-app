package com.mail.client.ui.settings

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Notifications
import androidx.compose.material.icons.filled.NotificationsOff
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.RadioButton
import androidx.compose.material3.RadioButtonDefaults
import androidx.compose.material3.Switch
import androidx.compose.material3.SwitchDefaults
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.mail.client.ui.theme.Accent
import com.mail.client.ui.theme.Danger
import com.mail.client.ui.theme.Divider
import com.mail.client.ui.theme.SurfaceDark
import com.mail.client.ui.theme.TextPrimary
import com.mail.client.ui.theme.TextSecondary
import org.koin.androidx.compose.koinViewModel

private val SYNC_OPTIONS = listOf(15 to "15 minutes", 30 to "30 minutes", 60 to "1 hour")

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsSheet(
    onDismiss: () -> Unit,
    onSignOut: () -> Unit,
    viewModel: SettingsViewModel = koinViewModel(),
) {
    val uiState by viewModel.uiState.collectAsState()

    ModalBottomSheet(
        onDismissRequest = onDismiss,
        containerColor = SurfaceDark,
        dragHandle = null,
    ) {
        Column(modifier = Modifier.navigationBarsPadding()) {

            Text(
                text = "Settings",
                color = TextPrimary,
                fontSize = 17.sp,
                fontWeight = FontWeight.SemiBold,
                modifier = Modifier
                    .padding(horizontal = 20.dp)
                    .padding(top = 24.dp, bottom = 16.dp),
            )

            HorizontalDivider(color = Divider, thickness = 0.5.dp)
            SectionLabel("Account")

            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 20.dp, vertical = 14.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Column(modifier = Modifier.weight(1f)) {
                    Text(text = "Signed in as", color = TextSecondary, fontSize = 12.sp)
                    Spacer(modifier = Modifier.height(2.dp))
                    Text(
                        text = uiState.email.ifEmpty { "—" },
                        color = TextPrimary,
                        fontSize = 14.sp,
                    )
                }
                TextButton(
                    onClick = { viewModel.signOut(onSignOut) },
                    colors = ButtonDefaults.textButtonColors(contentColor = Danger),
                ) {
                    Text("Sign out", fontSize = 14.sp)
                }
            }

            HorizontalDivider(color = Divider, thickness = 0.5.dp)
            SectionLabel("Background sync interval")

            SYNC_OPTIONS.forEach { (minutes, label) ->
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clickable { viewModel.setSyncInterval(minutes) }
                        .padding(horizontal = 12.dp, vertical = 4.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    RadioButton(
                        selected = uiState.syncIntervalMinutes == minutes,
                        onClick = { viewModel.setSyncInterval(minutes) },
                        colors = RadioButtonDefaults.colors(
                            selectedColor = Accent,
                            unselectedColor = TextSecondary,
                        ),
                    )
                    Spacer(modifier = Modifier.width(4.dp))
                    Text(text = label, color = TextPrimary, fontSize = 14.sp)
                }
            }

            HorizontalDivider(color = Divider, thickness = 0.5.dp)
            SectionLabel("Notifications")

            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .clickable { viewModel.setNotificationsEnabled(!uiState.notificationsEnabled) }
                    .padding(horizontal = 20.dp, vertical = 14.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Icon(
                    imageVector = if (uiState.notificationsEnabled) Icons.Default.Notifications
                                  else Icons.Default.NotificationsOff,
                    contentDescription = null,
                    tint = if (uiState.notificationsEnabled) Accent else TextSecondary,
                    modifier = Modifier.size(20.dp),
                )
                Spacer(modifier = Modifier.width(12.dp))
                Text(
                    text = "New mail notifications",
                    color = TextPrimary,
                    fontSize = 14.sp,
                    modifier = Modifier.weight(1f),
                )
                Switch(
                    checked = uiState.notificationsEnabled,
                    onCheckedChange = { viewModel.setNotificationsEnabled(it) },
                    colors = SwitchDefaults.colors(
                        checkedThumbColor = Accent,
                        checkedTrackColor = Accent.copy(alpha = 0.3f),
                        uncheckedThumbColor = TextSecondary,
                        uncheckedTrackColor = TextSecondary.copy(alpha = 0.2f),
                    ),
                )
            }

            Spacer(modifier = Modifier.height(8.dp))
        }
    }
}

@Composable
private fun SectionLabel(text: String) {
    Text(
        text = text.uppercase(),
        color = TextSecondary,
        fontSize = 11.sp,
        letterSpacing = 0.8.sp,
        modifier = Modifier.padding(horizontal = 20.dp, vertical = 10.dp),
    )
}
