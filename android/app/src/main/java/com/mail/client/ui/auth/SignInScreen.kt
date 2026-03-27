package com.mail.client.ui.auth

import android.app.Activity
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.google.android.gms.auth.api.signin.GoogleSignIn
import com.mail.client.data.repository.AuthRepository
import com.mail.client.ui.theme.Accent
import com.mail.client.ui.theme.Black
import com.mail.client.ui.theme.Danger
import com.mail.client.ui.theme.Divider
import com.mail.client.ui.theme.White
import org.koin.androidx.compose.koinViewModel

@Composable
fun SignInScreen(
    authRepository: AuthRepository,
    onSignedIn: () -> Unit,
) {
    val viewModel: SignInViewModel = koinViewModel()
    val state by viewModel.state.collectAsState()

    val signInLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.StartActivityForResult(),
    ) { result ->
        if (result.resultCode == Activity.RESULT_OK) {
            val task = GoogleSignIn.getSignedInAccountFromIntent(result.data)
            viewModel.handleSignInResult(task)
        }
    }

    LaunchedEffect(state) {
        if (state is SignInState.Success) onSignedIn()
    }

    Surface(
        modifier = Modifier.fillMaxSize(),
        color = Black,
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(horizontal = 40.dp),
            verticalArrangement = Arrangement.Center,
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Text(
                text = "mail",
                fontSize = 52.sp,
                fontWeight = FontWeight.Light,
                color = White,
            )
            Text(
                text = "client",
                fontSize = 52.sp,
                fontWeight = FontWeight.Light,
                color = Accent,
                modifier = Modifier.offset(y = (-14).dp),
            )

            Spacer(modifier = Modifier.height(72.dp))

            when (state) {
                is SignInState.Loading -> CircularProgressIndicator(color = Accent)
                else -> OutlinedButton(
                    onClick = { signInLauncher.launch(authRepository.getSignInIntent()) },
                    modifier = Modifier.fillMaxWidth(),
                    colors = ButtonDefaults.outlinedButtonColors(contentColor = White),
                    border = BorderStroke(1.dp, Divider),
                ) {
                    Text(
                        text = "Sign in with Google",
                        modifier = Modifier.padding(vertical = 8.dp),
                        fontSize = 15.sp,
                    )
                }
            }

            if (state is SignInState.Error) {
                Spacer(modifier = Modifier.height(16.dp))
                Text(
                    text = (state as SignInState.Error).message,
                    color = Danger,
                    fontSize = 13.sp,
                )
            }
        }
    }
}
