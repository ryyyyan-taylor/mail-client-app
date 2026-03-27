package com.mail.client.ui.inbox

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.material3.pulltorefresh.PullToRefreshBox
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.runtime.snapshotFlow
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.mail.client.data.local.ThreadEntity
import com.mail.client.ui.theme.Accent
import com.mail.client.ui.theme.Black
import com.mail.client.ui.theme.Divider
import com.mail.client.ui.theme.SurfaceDark
import com.mail.client.ui.theme.TextDisabled
import com.mail.client.ui.theme.TextPrimary
import com.mail.client.ui.theme.TextSecondary
import com.mail.client.ui.theme.UnreadDot
import com.mail.client.util.EmailParser
import com.mail.client.util.TimeFormatter
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.map
import org.koin.androidx.compose.koinViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun InboxScreen(
    onThreadClick: (threadId: String) -> Unit,
    viewModel: InboxViewModel = koinViewModel(),
) {
    val uiState by viewModel.uiState.collectAsState()
    val snackbarHostState = remember { SnackbarHostState() }
    val listState = rememberLazyListState()

    // Show errors as snackbar
    LaunchedEffect(uiState.error) {
        if (uiState.error != null) {
            snackbarHostState.showSnackbar(uiState.error!!)
            viewModel.clearError()
        }
    }

    // Infinite scroll: load next page when near bottom
    LaunchedEffect(listState) {
        snapshotFlow { listState.layoutInfo }
            .map { info ->
                val lastVisible = info.visibleItemsInfo.lastOrNull()?.index ?: 0
                val total = info.totalItemsCount
                total > 0 && lastVisible >= total - 5
            }
            .distinctUntilChanged()
            .collect { nearBottom ->
                if (nearBottom) viewModel.loadNextPage()
            }
    }

    Scaffold(
        containerColor = Black,
        snackbarHost = { SnackbarHost(snackbarHostState) },
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        text = "inbox",
                        color = TextPrimary,
                        fontSize = 18.sp,
                        fontWeight = FontWeight.Normal,
                        letterSpacing = 1.sp,
                    )
                },
                actions = {
                    if (uiState.isRefreshing) {
                        CircularProgressIndicator(
                            modifier = Modifier
                                .size(24.dp)
                                .padding(end = 16.dp),
                            color = Accent,
                            strokeWidth = 2.dp,
                        )
                    } else {
                        IconButton(onClick = { viewModel.refresh() }) {
                            Icon(
                                imageVector = Icons.Default.Refresh,
                                contentDescription = "Refresh",
                                tint = TextSecondary,
                            )
                        }
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = Black,
                    scrolledContainerColor = SurfaceDark,
                ),
            )
        },
    ) { paddingValues ->
        PullToRefreshBox(
            isRefreshing = uiState.isRefreshing,
            onRefresh = { viewModel.refresh() },
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues),
        ) {
            when {
                uiState.isLoading -> {
                    Box(
                        modifier = Modifier.fillMaxSize(),
                        contentAlignment = Alignment.Center,
                    ) {
                        CircularProgressIndicator(color = Accent)
                    }
                }

                uiState.threads.isEmpty() -> {
                    Box(
                        modifier = Modifier.fillMaxSize(),
                        contentAlignment = Alignment.Center,
                    ) {
                        Text(
                            text = "no messages",
                            color = TextDisabled,
                            fontSize = 14.sp,
                            letterSpacing = 0.5.sp,
                        )
                    }
                }

                else -> {
                    LazyColumn(
                        state = listState,
                        modifier = Modifier.fillMaxSize(),
                    ) {
                        itemsIndexed(
                            items = uiState.threads,
                            key = { _, thread -> thread.id },
                        ) { index, thread ->
                            ThreadListItem(
                                thread = thread,
                                onClick = { onThreadClick(thread.id) },
                            )
                            if (index < uiState.threads.lastIndex) {
                                HorizontalDivider(
                                    color = Divider,
                                    thickness = 0.5.dp,
                                )
                            }
                        }

                        if (uiState.isLoadingMore) {
                            item {
                                Box(
                                    modifier = Modifier
                                        .fillMaxWidth()
                                        .padding(16.dp),
                                    contentAlignment = Alignment.Center,
                                ) {
                                    CircularProgressIndicator(
                                        modifier = Modifier.size(20.dp),
                                        color = Accent,
                                        strokeWidth = 2.dp,
                                    )
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

@Composable
fun ThreadListItem(
    thread: ThreadEntity,
    onClick: () -> Unit,
) {
    val isRead = thread.isRead
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick)
            .background(Black)
            .padding(horizontal = 16.dp, vertical = 11.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        // Unread dot
        Box(
            modifier = Modifier
                .size(6.dp)
                .background(
                    color = if (isRead) Black else UnreadDot,
                    shape = CircleShape,
                ),
        )

        Spacer(modifier = Modifier.width(10.dp))

        // Sender — fixed width so title always starts at the same column
        Text(
            text = EmailParser.displayName(thread.from).ifEmpty { "?" },
            color = if (isRead) TextSecondary else TextPrimary,
            fontSize = 13.sp,
            fontWeight = if (isRead) FontWeight.Normal else FontWeight.SemiBold,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
            modifier = Modifier.width(110.dp),
        )

        Spacer(modifier = Modifier.width(8.dp))

        // Subject — fills remaining space, ellipsed before the date
        Text(
            text = thread.subject,
            color = if (isRead) TextSecondary else TextPrimary,
            fontSize = 13.sp,
            fontWeight = if (isRead) FontWeight.Normal else FontWeight.Medium,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
            modifier = Modifier.weight(1f),
        )

        Spacer(modifier = Modifier.width(8.dp))

        // Timestamp — intrinsic width, never truncated
        Text(
            text = TimeFormatter.format(thread.lastMessageTimestamp),
            color = TextSecondary,
            fontSize = 12.sp,
            maxLines = 1,
        )
    }
}
