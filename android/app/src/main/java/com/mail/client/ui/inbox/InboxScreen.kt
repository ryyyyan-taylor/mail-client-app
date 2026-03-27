package com.mail.client.ui.inbox

import androidx.compose.animation.animateColorAsState
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Label
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarDuration
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.SnackbarResult
import androidx.compose.material3.SwipeToDismissBox
import androidx.compose.material3.SwipeToDismissBoxValue
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.material3.pulltorefresh.PullToRefreshBox
import androidx.compose.material3.rememberSwipeToDismissBoxState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.runtime.snapshotFlow
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.mail.client.data.local.LabelEntity
import com.mail.client.data.local.ThreadEntity
import com.mail.client.ui.theme.Accent
import com.mail.client.ui.theme.Black
import com.mail.client.ui.theme.Danger
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
import kotlinx.coroutines.launch
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
    val scope = rememberCoroutineScope()

    // Thread waiting for a label selection via the bottom sheet
    var labelPickerThread by remember { mutableStateOf<ThreadEntity?>(null) }

    LaunchedEffect(uiState.error) {
        if (uiState.error != null) {
            snackbarHostState.showSnackbar(uiState.error!!)
            viewModel.clearError()
        }
    }

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

    // Label picker — shown on swipe-right
    labelPickerThread?.let { thread ->
        LabelPickerSheet(
            labels = uiState.availableLabels,
            onDismiss = { labelPickerThread = null },
            onLabelSelected = { label ->
                labelPickerThread = null
                viewModel.hideThread(thread.id)
                scope.launch {
                    val result = snackbarHostState.showSnackbar(
                        message = "Moved to ${label.name}",
                        actionLabel = "Undo",
                        duration = SnackbarDuration.Short,
                    )
                    if (result == SnackbarResult.ActionPerformed) {
                        viewModel.unhideThread(thread.id)
                    } else {
                        viewModel.confirmMove(thread.id, label.id)
                    }
                }
            },
        )
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
                            SwipeableThreadItem(
                                thread = thread,
                                showDivider = index < uiState.threads.lastIndex,
                                onClick = { onThreadClick(thread.id) },
                                onSwipeDelete = {
                                    viewModel.hideThread(thread.id)
                                    scope.launch {
                                        val result = snackbarHostState.showSnackbar(
                                            message = "Moved to Trash",
                                            actionLabel = "Undo",
                                            duration = SnackbarDuration.Short,
                                        )
                                        if (result == SnackbarResult.ActionPerformed) {
                                            viewModel.unhideThread(thread.id)
                                        } else {
                                            viewModel.confirmDelete(thread.id)
                                        }
                                    }
                                },
                                onSwipeMoveRequest = { labelPickerThread = thread },
                                modifier = Modifier.animateItem(),
                            )
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

// ── Swipeable row ─────────────────────────────────────────────────────────────

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun SwipeableThreadItem(
    thread: ThreadEntity,
    showDivider: Boolean,
    onClick: () -> Unit,
    onSwipeDelete: () -> Unit,
    onSwipeMoveRequest: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val dismissState = rememberSwipeToDismissBoxState(
        confirmValueChange = { value ->
            when (value) {
                SwipeToDismissBoxValue.EndToStart -> { onSwipeDelete(); true }
                SwipeToDismissBoxValue.StartToEnd -> { onSwipeMoveRequest(); false }
                SwipeToDismissBoxValue.Settled -> true
            }
        },
    )

    SwipeToDismissBox(
        state = dismissState,
        modifier = modifier,
        backgroundContent = {
            val bgColor by animateColorAsState(
                targetValue = when (dismissState.targetValue) {
                    SwipeToDismissBoxValue.EndToStart -> Danger
                    SwipeToDismissBoxValue.StartToEnd -> Accent
                    SwipeToDismissBoxValue.Settled -> Black
                },
                label = "swipeBg",
            )
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .background(bgColor)
                    .padding(horizontal = 20.dp),
                contentAlignment = when (dismissState.targetValue) {
                    SwipeToDismissBoxValue.EndToStart -> Alignment.CenterEnd
                    else -> Alignment.CenterStart
                },
            ) {
                when (dismissState.targetValue) {
                    SwipeToDismissBoxValue.EndToStart -> Icon(
                        imageVector = Icons.Default.Delete,
                        contentDescription = "Delete",
                        tint = Color.White,
                    )
                    SwipeToDismissBoxValue.StartToEnd -> Icon(
                        imageVector = Icons.Default.Label,
                        contentDescription = "Move to label",
                        tint = Color.White,
                    )
                    SwipeToDismissBoxValue.Settled -> {}
                }
            }
        },
    ) {
        Column(modifier = Modifier.background(Black)) {
            ThreadListItem(thread = thread, onClick = onClick)
            if (showDivider) {
                HorizontalDivider(color = Divider, thickness = 0.5.dp)
            }
        }
    }
}

// ── Label picker bottom sheet ─────────────────────────────────────────────────

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun LabelPickerSheet(
    labels: List<LabelEntity>,
    onDismiss: () -> Unit,
    onLabelSelected: (LabelEntity) -> Unit,
) {
    val userLabels = remember(labels) { labels.filter { it.type == "user" } }

    ModalBottomSheet(
        onDismissRequest = onDismiss,
        containerColor = SurfaceDark,
        dragHandle = null,
    ) {
        Text(
            text = "Move to label",
            color = TextPrimary,
            fontSize = 15.sp,
            fontWeight = FontWeight.Medium,
            modifier = Modifier
                .padding(horizontal = 20.dp)
                .padding(top = 20.dp, bottom = 4.dp),
        )

        if (userLabels.isEmpty()) {
            Text(
                text = "No labels found. Create labels in Gmail to use this feature.",
                color = TextSecondary,
                fontSize = 13.sp,
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 20.dp, vertical = 16.dp),
            )
        } else {
            LazyColumn(modifier = Modifier.navigationBarsPadding()) {
                items(userLabels, key = { it.id }) { label ->
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clickable { onLabelSelected(label) }
                            .padding(horizontal = 20.dp, vertical = 14.dp),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        Icon(
                            imageVector = Icons.Default.Label,
                            contentDescription = null,
                            tint = Accent,
                            modifier = Modifier.size(18.dp),
                        )
                        Spacer(modifier = Modifier.width(14.dp))
                        Text(
                            text = label.name,
                            color = TextPrimary,
                            fontSize = 14.sp,
                        )
                    }
                    HorizontalDivider(color = Divider, thickness = 0.5.dp)
                }
            }
        }
    }
}

// ── Thread list item ──────────────────────────────────────────────────────────

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

        // Sender — fixed width so subject always starts at the same column
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
