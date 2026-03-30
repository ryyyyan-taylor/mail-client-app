package com.mail.client.ui.inbox

import android.content.res.Configuration
import androidx.activity.compose.BackHandler
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.slideOutVertically
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.Label
import androidx.compose.material.icons.filled.ArrowDropDown
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.MoreVert
import androidx.compose.material.icons.filled.RadioButtonUnchecked
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MenuDefaults
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarDuration
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.SnackbarResult
import androidx.compose.material3.Surface
import androidx.compose.material3.SwipeToDismissBox
import androidx.compose.material3.SwipeToDismissBoxValue
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.material3.VerticalDivider
import androidx.compose.material3.pulltorefresh.PullToRefreshBox
import androidx.compose.material3.rememberSwipeToDismissBoxState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.key
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.runtime.snapshotFlow
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.input.nestedscroll.nestedScroll
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.mail.client.data.local.LabelEntity
import com.mail.client.data.local.ThreadEntity
import com.mail.client.ui.settings.SettingsSheet
import com.mail.client.ui.theme.Accent
import com.mail.client.ui.theme.Black
import com.mail.client.ui.theme.Danger
import com.mail.client.ui.theme.Divider
import com.mail.client.ui.theme.SurfaceDark
import com.mail.client.ui.theme.SurfaceVariant
import com.mail.client.ui.theme.TextDisabled
import com.mail.client.ui.theme.TextPrimary
import com.mail.client.ui.theme.TextSecondary
import com.mail.client.ui.theme.UnreadDot
import com.mail.client.ui.thread.ThreadDetailScreen
import com.mail.client.util.EmailParser
import com.mail.client.util.TimeFormatter
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.launch
import org.koin.androidx.compose.koinViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun InboxScreen(
    onThreadClick: (threadId: String) -> Unit,
    onSignOut: () -> Unit,
    initialSelectedThreadId: String? = null,
    viewModel: InboxViewModel = koinViewModel(),
) {
    val uiState by viewModel.uiState.collectAsState()
    val snackbarHostState = remember { SnackbarHostState() }
    val listState = rememberLazyListState()
    val scope = rememberCoroutineScope()
    val isLandscape = LocalConfiguration.current.orientation == Configuration.ORIENTATION_LANDSCAPE
    val isSelectionMode = uiState.selectedIds.isNotEmpty()

    var selectedThreadId by remember { mutableStateOf(initialSelectedThreadId) }
    var labelPickerThread by remember { mutableStateOf<ThreadEntity?>(null) }
    var showBatchLabelPicker by remember { mutableStateOf(false) }
    var showSettings by remember { mutableStateOf(false) }
    var showSectionPicker by remember { mutableStateOf(false) }

    // Sync notification-tap thread (e.g. arrives while app is in landscape)
    LaunchedEffect(initialSelectedThreadId) {
        if (initialSelectedThreadId != null) selectedThreadId = initialSelectedThreadId
    }

    BackHandler(enabled = isSelectionMode) { viewModel.exitSelectionMode() }

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
            .collect { nearBottom -> if (nearBottom) viewModel.loadNextPage() }
    }

    // ── Sheets ────────────────────────────────────────────────────────────────

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
                    if (result == SnackbarResult.ActionPerformed) viewModel.unhideThread(thread.id)
                    else viewModel.confirmMove(thread.id, label.id)
                }
            },
        )
    }

    if (showBatchLabelPicker) {
        LabelPickerSheet(
            labels = uiState.availableLabels,
            onDismiss = { showBatchLabelPicker = false },
            onLabelSelected = { label ->
                showBatchLabelPicker = false
                val ids = viewModel.startBatchMove()
                scope.launch {
                    val result = snackbarHostState.showSnackbar(
                        message = "Moved ${ids.size} thread${if (ids.size > 1) "s" else ""} to ${label.name}",
                        actionLabel = "Undo",
                        duration = SnackbarDuration.Short,
                    )
                    if (result == SnackbarResult.ActionPerformed) ids.forEach { viewModel.unhideThread(it) }
                    else viewModel.confirmBatchMove(ids, label.id)
                }
            },
        )
    }

    if (showSectionPicker) {
        LaunchedEffect(Unit) { viewModel.refreshLabels() }
        SectionPickerSheet(
            currentSection = uiState.currentSection,
            userLabels = uiState.availableLabels,
            onSectionSelected = { section ->
                showSectionPicker = false
                viewModel.setSection(section)
            },
            onDismiss = { showSectionPicker = false },
        )
    }

    if (showSettings) {
        SettingsSheet(
            onDismiss = { showSettings = false },
            onSignOut = { showSettings = false; onSignOut() },
        )
    }

    // ── Scaffold ──────────────────────────────────────────────────────────────

    val scrollBehavior = if (isLandscape) TopAppBarDefaults.enterAlwaysScrollBehavior() else null

    Scaffold(
        modifier = scrollBehavior?.let { Modifier.nestedScroll(it.nestedScrollConnection) } ?: Modifier,
        containerColor = Black,
        snackbarHost = { SnackbarHost(snackbarHostState) },
        topBar = {
            TopAppBar(
                title = {
                    Row(
                        modifier = Modifier.clickable { showSectionPicker = true },
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        Text(
                            text = uiState.currentSection.displayName,
                            color = TextPrimary,
                            fontSize = 18.sp,
                            fontWeight = FontWeight.Normal,
                            letterSpacing = 1.sp,
                        )
                        Icon(
                            imageVector = Icons.Default.ArrowDropDown,
                            contentDescription = "Switch section",
                            tint = TextSecondary,
                            modifier = Modifier.size(20.dp),
                        )
                    }
                },
                actions = {
                    if (uiState.isRefreshing) {
                        CircularProgressIndicator(
                            modifier = Modifier.padding(end = 12.dp).size(20.dp),
                            color = Accent,
                            strokeWidth = 2.dp,
                        )
                    } else {
                        Box {
                            var showOverflow by remember { mutableStateOf(false) }
                            IconButton(onClick = { showOverflow = true }) {
                                Icon(Icons.Default.MoreVert, contentDescription = "More", tint = TextSecondary)
                            }
                            DropdownMenu(
                                expanded = showOverflow,
                                onDismissRequest = { showOverflow = false },
                                containerColor = SurfaceDark,
                            ) {
                                DropdownMenuItem(
                                    text = { Text("Settings", color = TextPrimary, fontSize = 14.sp) },
                                    onClick = { showOverflow = false; showSettings = true },
                                    colors = MenuDefaults.itemColors(textColor = TextPrimary),
                                )
                            }
                        }
                    }
                },
                scrollBehavior = scrollBehavior,
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = Black,
                    scrolledContainerColor = SurfaceDark,
                ),
            )
        },
    ) { paddingValues ->
        if (isLandscape) {
            Row(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(paddingValues),
            ) {
                // Left pane — thread list
                InboxListContent(
                    uiState = uiState,
                    viewModel = viewModel,
                    snackbarHostState = snackbarHostState,
                    listState = listState,
                    scope = scope,
                    onThreadClick = { selectedThreadId = it },
                    onSwipeMoveRequest = { labelPickerThread = it },
                    onBatchMoveRequest = { showBatchLabelPicker = true },
                    modifier = Modifier.weight(1f).fillMaxHeight(),
                )

                VerticalDivider(color = Divider, thickness = 0.5.dp)

                // Right pane — thread detail or placeholder
                Box(
                    modifier = Modifier
                        .weight(1f)
                        .fillMaxHeight()
                        .background(Black),
                ) {
                    if (selectedThreadId != null) {
                        key(selectedThreadId) {
                            ThreadDetailScreen(
                                threadId = selectedThreadId!!,
                                onBack = { selectedThreadId = null },
                                contentOnly = true,
                            )
                        }
                    } else {
                        Box(
                            modifier = Modifier.fillMaxSize(),
                            contentAlignment = Alignment.Center,
                        ) {
                            Text(
                                text = "select a thread",
                                color = TextDisabled,
                                fontSize = 14.sp,
                                letterSpacing = 0.5.sp,
                            )
                        }
                    }
                }
            }
        } else {
            InboxListContent(
                uiState = uiState,
                viewModel = viewModel,
                snackbarHostState = snackbarHostState,
                listState = listState,
                scope = scope,
                onThreadClick = onThreadClick,
                onSwipeMoveRequest = { labelPickerThread = it },
                onBatchMoveRequest = { showBatchLabelPicker = true },
                modifier = Modifier
                    .fillMaxSize()
                    .padding(paddingValues),
            )
        }
    }
}

// ── Thread list content ───────────────────────────────────────────────────────

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun InboxListContent(
    uiState: InboxUiState,
    viewModel: InboxViewModel,
    snackbarHostState: SnackbarHostState,
    listState: androidx.compose.foundation.lazy.LazyListState,
    scope: CoroutineScope,
    onThreadClick: (String) -> Unit,
    onSwipeMoveRequest: (ThreadEntity) -> Unit,
    onBatchMoveRequest: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val isSelectionMode = uiState.selectedIds.isNotEmpty()

    PullToRefreshBox(
        isRefreshing = uiState.isRefreshing,
        onRefresh = { viewModel.refresh() },
        modifier = modifier,
    ) {
        when {
            uiState.isLoading -> {
                Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                    CircularProgressIndicator(color = Accent)
                }
            }

            uiState.threads.isEmpty() -> {
                Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                    Text(text = "no messages", color = TextDisabled, fontSize = 14.sp, letterSpacing = 0.5.sp)
                }
            }

            else -> {
                LazyColumn(state = listState, modifier = Modifier.fillMaxSize()) {
                    itemsIndexed(
                        items = uiState.threads,
                        key = { _, thread -> thread.id },
                    ) { index, thread ->
                        val showDivider = index < uiState.threads.lastIndex
                        if (isSelectionMode) {
                            Column(modifier = Modifier.animateItem()) {
                                ThreadListItem(
                                    thread = thread,
                                    isSelected = thread.id in uiState.selectedIds,
                                    isSelectionMode = true,
                                    onClick = { viewModel.toggleSelection(thread.id) },
                                    onLongPress = {},
                                )
                                if (showDivider) HorizontalDivider(color = Divider, thickness = 0.5.dp)
                            }
                        } else {
                            SwipeableThreadItem(
                                thread = thread,
                                showDivider = showDivider,
                                onClick = { onThreadClick(thread.id) },
                                onLongPress = { viewModel.enterSelectionMode(thread.id) },
                                onSwipeDelete = {
                                    viewModel.hideThread(thread.id)
                                    scope.launch {
                                        val result = snackbarHostState.showSnackbar(
                                            message = "Moved to Trash",
                                            actionLabel = "Undo",
                                            duration = SnackbarDuration.Short,
                                        )
                                        if (result == SnackbarResult.ActionPerformed) viewModel.unhideThread(thread.id)
                                        else viewModel.confirmDelete(thread.id)
                                    }
                                },
                                onSwipeMoveRequest = { onSwipeMoveRequest(thread) },
                                modifier = Modifier.animateItem(),
                            )
                        }
                    }

                    if (uiState.isLoadingMore) {
                        item {
                            Box(
                                modifier = Modifier.fillMaxWidth().padding(16.dp),
                                contentAlignment = Alignment.Center,
                            ) {
                                CircularProgressIndicator(modifier = Modifier.size(20.dp), color = Accent, strokeWidth = 2.dp)
                            }
                        }
                    }
                }
            }
        }

        AnimatedVisibility(
            visible = isSelectionMode,
            enter = fadeIn() + slideInVertically { it },
            exit = fadeOut() + slideOutVertically { it },
            modifier = Modifier
                .align(Alignment.BottomCenter)
                .navigationBarsPadding()
                .padding(bottom = 16.dp),
        ) {
            SelectionPill(
                count = uiState.selectedIds.size,
                onClose = { viewModel.exitSelectionMode() },
                onMoveRequest = onBatchMoveRequest,
                onDelete = {
                    val ids = viewModel.startBatchDelete()
                    scope.launch {
                        val result = snackbarHostState.showSnackbar(
                            message = "Moved ${ids.size} thread${if (ids.size > 1) "s" else ""} to Trash",
                            actionLabel = "Undo",
                            duration = SnackbarDuration.Short,
                        )
                        if (result == SnackbarResult.ActionPerformed) ids.forEach { viewModel.unhideThread(it) }
                        else viewModel.confirmBatchDelete(ids)
                    }
                },
                onSpam = {
                    val ids = viewModel.startBatchSpam()
                    scope.launch {
                        val result = snackbarHostState.showSnackbar(
                            message = "Marked ${ids.size} thread${if (ids.size > 1) "s" else ""} as spam",
                            actionLabel = "Undo",
                            duration = SnackbarDuration.Short,
                        )
                        if (result == SnackbarResult.ActionPerformed) ids.forEach { viewModel.unhideThread(it) }
                        else viewModel.confirmBatchSpam(ids)
                    }
                },
                onMarkRead = { viewModel.markSelectedRead() },
                onMarkUnread = { viewModel.markSelectedUnread() },
            )
        }
    }
}

// ── Selection pill ────────────────────────────────────────────────────────────

@Composable
private fun SelectionPill(
    count: Int,
    onClose: () -> Unit,
    onMoveRequest: () -> Unit,
    onDelete: () -> Unit,
    onSpam: () -> Unit,
    onMarkRead: () -> Unit,
    onMarkUnread: () -> Unit,
) {
    var showOverflow by remember { mutableStateOf(false) }

    Surface(
        shape = RoundedCornerShape(50),
        color = SurfaceDark,
        shadowElevation = 8.dp,
    ) {
        Row(
            verticalAlignment = Alignment.CenterVertically,
            modifier = Modifier.height(48.dp),
        ) {
            PillIconButton(icon = Icons.Default.Close, description = "Exit selection", onClick = onClose)
            Text(
                text = "$count selected",
                color = TextPrimary,
                fontSize = 13.sp,
                modifier = Modifier.padding(end = 8.dp),
            )
            Box {
                PillIconButton(icon = Icons.Default.MoreVert, description = "More", onClick = { showOverflow = true })
                DropdownMenu(
                    expanded = showOverflow,
                    onDismissRequest = { showOverflow = false },
                    containerColor = SurfaceDark,
                ) {
                    DropdownMenuItem(
                        text = { Text("Mark as spam", color = TextPrimary, fontSize = 14.sp) },
                        onClick = { showOverflow = false; onSpam() },
                        colors = MenuDefaults.itemColors(textColor = TextPrimary),
                    )
                    DropdownMenuItem(
                        text = { Text("Mark as read", color = TextPrimary, fontSize = 14.sp) },
                        onClick = { showOverflow = false; onMarkRead() },
                        colors = MenuDefaults.itemColors(textColor = TextPrimary),
                    )
                    DropdownMenuItem(
                        text = { Text("Mark as unread", color = TextPrimary, fontSize = 14.sp) },
                        onClick = { showOverflow = false; onMarkUnread() },
                        colors = MenuDefaults.itemColors(textColor = TextPrimary),
                    )
                }
            }
            PillIconButton(icon = Icons.AutoMirrored.Filled.Label, description = "Move to label", onClick = onMoveRequest)
            PillIconButton(icon = Icons.Default.Delete, description = "Delete", onClick = onDelete)
        }
    }
}

@Composable
private fun PillIconButton(icon: ImageVector, description: String, onClick: () -> Unit) {
    Box(
        modifier = Modifier.size(48.dp).clickable(onClick = onClick),
        contentAlignment = Alignment.Center,
    ) {
        Icon(imageVector = icon, contentDescription = description, tint = TextSecondary, modifier = Modifier.size(20.dp))
    }
}

// ── Swipeable row ─────────────────────────────────────────────────────────────

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun SwipeableThreadItem(
    thread: ThreadEntity,
    showDivider: Boolean,
    onClick: () -> Unit,
    onLongPress: () -> Unit,
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
                modifier = Modifier.fillMaxSize().background(bgColor).padding(horizontal = 20.dp),
                contentAlignment = when (dismissState.targetValue) {
                    SwipeToDismissBoxValue.EndToStart -> Alignment.CenterEnd
                    else -> Alignment.CenterStart
                },
            ) {
                when (dismissState.targetValue) {
                    SwipeToDismissBoxValue.EndToStart -> Icon(Icons.Default.Delete, contentDescription = "Delete", tint = Color.White)
                    SwipeToDismissBoxValue.StartToEnd -> Icon(Icons.AutoMirrored.Filled.Label, contentDescription = "Move to label", tint = Color.White)
                    SwipeToDismissBoxValue.Settled -> {}
                }
            }
        },
    ) {
        Column(modifier = Modifier.background(Black)) {
            ThreadListItem(thread = thread, onClick = onClick, onLongPress = onLongPress)
            if (showDivider) HorizontalDivider(color = Divider, thickness = 0.5.dp)
        }
    }
}

// ── Section picker bottom sheet ───────────────────────────────────────────────

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun SectionPickerSheet(
    currentSection: Section,
    userLabels: List<LabelEntity>,
    onSectionSelected: (Section) -> Unit,
    onDismiss: () -> Unit,
) {
    val sortedUserLabels = remember(userLabels) {
        userLabels.filter { it.type != "system" }.sortedBy { it.name.lowercase() }
    }

    ModalBottomSheet(
        onDismissRequest = onDismiss,
        containerColor = SurfaceDark,
        dragHandle = null,
    ) {
        LazyColumn(modifier = Modifier.navigationBarsPadding()) {
            items(SYSTEM_SECTIONS, key = { it.labelId }) { section ->
                SectionRow(
                    name = section.displayName,
                    isSelected = section.labelId == currentSection.labelId,
                    onClick = { onSectionSelected(section) },
                )
            }
            if (sortedUserLabels.isNotEmpty()) {
                item {
                    HorizontalDivider(color = Divider, thickness = 0.5.dp, modifier = Modifier.padding(vertical = 4.dp))
                }
                items(sortedUserLabels, key = { it.id }) { label ->
                    SectionRow(
                        name = label.name.lowercase(),
                        isSelected = label.id == currentSection.labelId,
                        onClick = { onSectionSelected(Section(label.id, label.name.lowercase())) },
                    )
                }
            }
            item { Spacer(modifier = Modifier.height(8.dp)) }
        }
    }
}

@Composable
private fun SectionRow(name: String, isSelected: Boolean, onClick: () -> Unit) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick)
            .padding(horizontal = 20.dp, vertical = 14.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(
            text = name,
            color = if (isSelected) Accent else TextPrimary,
            fontSize = 15.sp,
            fontWeight = if (isSelected) FontWeight.Medium else FontWeight.Normal,
        )
    }
}

// ── Label picker bottom sheet ─────────────────────────────────────────────────

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun LabelPickerSheet(
    labels: List<LabelEntity>,
    onDismiss: () -> Unit,
    onLabelSelected: (LabelEntity) -> Unit,
) {
    val userLabels = remember(labels) { labels.filter { it.type != "system" }.sortedBy { it.name.lowercase() } }

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
            modifier = Modifier.padding(horizontal = 20.dp).padding(top = 20.dp, bottom = 4.dp),
        )

        if (userLabels.isEmpty()) {
            Text(
                text = "No labels found. Create labels in Gmail to use this feature.",
                color = TextSecondary,
                fontSize = 13.sp,
                modifier = Modifier.fillMaxWidth().padding(horizontal = 20.dp, vertical = 16.dp),
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
                            imageVector = Icons.AutoMirrored.Filled.Label,
                            contentDescription = null,
                            tint = Accent,
                            modifier = Modifier.size(18.dp),
                        )
                        Spacer(modifier = Modifier.width(14.dp))
                        Text(text = label.name, color = TextPrimary, fontSize = 14.sp)
                    }
                    HorizontalDivider(color = Divider, thickness = 0.5.dp)
                }
            }
        }
    }
}

// ── Thread list item ──────────────────────────────────────────────────────────

@OptIn(ExperimentalFoundationApi::class)
@Composable
fun ThreadListItem(
    thread: ThreadEntity,
    onClick: () -> Unit,
    isSelected: Boolean = false,
    isSelectionMode: Boolean = false,
    onLongPress: () -> Unit = {},
) {
    val isRead = thread.isRead
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .combinedClickable(onClick = onClick, onLongClick = onLongPress)
            .background(if (isSelected) SurfaceVariant else Black)
            .padding(horizontal = 16.dp, vertical = 11.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        if (isSelectionMode) {
            Icon(
                imageVector = if (isSelected) Icons.Default.CheckCircle else Icons.Default.RadioButtonUnchecked,
                contentDescription = if (isSelected) "Selected" else "Not selected",
                tint = if (isSelected) Accent else TextSecondary,
                modifier = Modifier.size(16.dp),
            )
        } else {
            Box(
                modifier = Modifier.size(6.dp).background(
                    color = if (isRead) Black else UnreadDot,
                    shape = CircleShape,
                ),
            )
        }

        Spacer(modifier = Modifier.width(if (isSelectionMode) 8.dp else 10.dp))

        Text(
            text = EmailParser.displayName(thread.from).ifEmpty { "?" },
            color = if (isRead) TextSecondary else TextPrimary,
            fontSize = 14.sp,
            fontWeight = if (isRead) FontWeight.Normal else FontWeight.SemiBold,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
            modifier = Modifier.width(110.dp),
        )

        Spacer(modifier = Modifier.width(8.dp))

        Text(
            text = thread.subject,
            color = if (isRead) TextSecondary else TextPrimary,
            fontSize = 14.sp,
            fontWeight = if (isRead) FontWeight.Normal else FontWeight.Medium,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
            modifier = Modifier.weight(1f),
        )

        Spacer(modifier = Modifier.width(8.dp))

        Text(text = TimeFormatter.format(thread.lastMessageTimestamp), color = TextSecondary, fontSize = 13.sp, maxLines = 1)
    }
}
