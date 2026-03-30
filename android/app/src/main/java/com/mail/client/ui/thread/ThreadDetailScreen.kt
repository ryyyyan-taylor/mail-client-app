package com.mail.client.ui.thread

import android.view.MotionEvent
import android.webkit.WebResourceRequest
import android.webkit.WebView
import android.webkit.WebViewClient
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.slideOutVertically
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.animation.animateContentSize
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
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.Label
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.MoreVert
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
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.viewinterop.AndroidView
import com.mail.client.data.local.LabelEntity
import com.mail.client.data.local.MessageEntity
import com.mail.client.ui.theme.Accent
import com.mail.client.ui.theme.Black
import com.mail.client.ui.theme.Divider
import com.mail.client.ui.theme.SurfaceDark
import com.mail.client.ui.theme.TextDisabled
import com.mail.client.ui.theme.TextPrimary
import com.mail.client.ui.theme.TextSecondary
import com.mail.client.util.EmailParser
import com.mail.client.util.TimeFormatter
import org.koin.androidx.compose.koinViewModel
import org.koin.core.parameter.parametersOf

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ThreadDetailScreen(
    threadId: String,
    onBack: () -> Unit,
    contentOnly: Boolean = false,
    viewModel: ThreadDetailViewModel = koinViewModel(key = threadId, parameters = { parametersOf(threadId) }),
) {
    val uiState by viewModel.uiState.collectAsState()
    val snackbarHostState = remember { SnackbarHostState() }
    var showMoveSheet by remember { mutableStateOf(false) }

    LaunchedEffect(uiState.navigateBack) {
        if (uiState.navigateBack) onBack()
    }

    LaunchedEffect(uiState.error) {
        if (uiState.error != null) {
            snackbarHostState.showSnackbar(uiState.error!!)
            viewModel.clearError()
        }
    }

    if (showMoveSheet) {
        LabelPickerSheet(
            labels = uiState.availableLabels,
            onDismiss = { showMoveSheet = false },
            onLabelSelected = { label ->
                showMoveSheet = false
                viewModel.moveToLabel(label.id)
            },
        )
    }

    if (contentOnly) {
        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(Black),
        ) {
            when {
                uiState.isLoading && uiState.messages.isEmpty() -> {
                    Box(
                        modifier = Modifier.fillMaxSize(),
                        contentAlignment = Alignment.Center,
                    ) {
                        CircularProgressIndicator(color = Accent)
                    }
                }
                else -> {
                    LazyColumn(modifier = Modifier.fillMaxSize()) {
                        itemsIndexed(
                            items = uiState.messages,
                            key = { _, msg -> msg.id },
                        ) { index, message ->
                            val isLast = index == uiState.messages.lastIndex
                            MessageCard(message = message, initiallyExpanded = isLast)
                            HorizontalDivider(color = Divider, thickness = 0.5.dp)
                        }
                    }
                }
            }

            SnackbarHost(
                hostState = snackbarHostState,
                modifier = Modifier
                    .align(Alignment.BottomStart)
                    .navigationBarsPadding(),
            )

            AnimatedVisibility(
                visible = !uiState.isLoading || uiState.messages.isNotEmpty(),
                enter = fadeIn(tween(220)) + slideInVertically(tween(220)) { it / 3 },
                exit = fadeOut(tween(160)),
                modifier = Modifier
                    .align(Alignment.BottomEnd)
                    .navigationBarsPadding()
                    .padding(16.dp),
            ) {
                ThreadActionsPill(
                    isRead = uiState.isRead,
                    onMove = { showMoveSheet = true },
                    onDelete = { viewModel.delete() },
                    onSpam = { viewModel.spam() },
                    onToggleRead = { viewModel.toggleRead() },
                )
            }
        }
    } else {
        Scaffold(
            containerColor = Black,
            snackbarHost = { SnackbarHost(snackbarHostState) },
            topBar = {
                TopAppBar(
                    navigationIcon = {
                        IconButton(onClick = onBack) {
                            Icon(
                                imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                                contentDescription = "Back",
                                tint = TextSecondary,
                            )
                        }
                    },
                    title = {
                        Text(
                            text = uiState.subject,
                            color = TextPrimary,
                            fontSize = 15.sp,
                            fontWeight = FontWeight.Normal,
                            maxLines = 1,
                            overflow = TextOverflow.Ellipsis,
                        )
                    },
                    colors = TopAppBarDefaults.topAppBarColors(
                        containerColor = Black,
                        scrolledContainerColor = SurfaceDark,
                    ),
                )
            },
        ) { paddingValues ->
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(paddingValues),
            ) {
                when {
                    uiState.isLoading && uiState.messages.isEmpty() -> {
                        Box(
                            modifier = Modifier.fillMaxSize(),
                            contentAlignment = Alignment.Center,
                        ) {
                            CircularProgressIndicator(color = Accent)
                        }
                    }

                    else -> {
                        LazyColumn(modifier = Modifier.fillMaxSize()) {
                            itemsIndexed(
                                items = uiState.messages,
                                key = { _, msg -> msg.id },
                            ) { index, message ->
                                val isLast = index == uiState.messages.lastIndex
                                MessageCard(message = message, initiallyExpanded = isLast)
                                HorizontalDivider(color = Divider, thickness = 0.5.dp)
                            }
                        }
                    }
                }

                AnimatedVisibility(
                    visible = !uiState.isLoading || uiState.messages.isNotEmpty(),
                    enter = fadeIn(tween(220)) + slideInVertically(tween(220)) { it / 3 },
                    exit = fadeOut(tween(160)),
                    modifier = Modifier
                        .align(Alignment.BottomEnd)
                        .navigationBarsPadding()
                        .padding(16.dp),
                ) {
                    ThreadActionsPill(
                        isRead = uiState.isRead,
                        onMove = { showMoveSheet = true },
                        onDelete = { viewModel.delete() },
                        onSpam = { viewModel.spam() },
                        onToggleRead = { viewModel.toggleRead() },
                    )
                }
            }
        }
    }
}

// ── Thread actions pill ───────────────────────────────────────────────────────

@Composable
private fun ThreadActionsPill(
    isRead: Boolean,
    onMove: () -> Unit,
    onDelete: () -> Unit,
    onSpam: () -> Unit,
    onToggleRead: () -> Unit,
) {
    var showOverflow by remember { mutableStateOf(false) }

    Surface(
        shape = RoundedCornerShape(20.dp),
        color = SurfaceDark,
        shadowElevation = 8.dp,
    ) {
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Box {
                PillIconButton(
                    icon = Icons.Default.MoreVert,
                    description = "More",
                    onClick = { showOverflow = true },
                )
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
                        text = {
                            Text(
                                text = if (isRead) "Mark as unread" else "Mark as read",
                                color = TextPrimary,
                                fontSize = 14.sp,
                            )
                        },
                        onClick = { showOverflow = false; onToggleRead() },
                        colors = MenuDefaults.itemColors(textColor = TextPrimary),
                    )
                }
            }
            HorizontalDivider(
                color = Divider,
                thickness = 0.5.dp,
                modifier = Modifier.width(24.dp),
            )
            PillIconButton(
                icon = Icons.AutoMirrored.Filled.Label,
                description = "Move to label",
                onClick = onMove,
            )
            HorizontalDivider(
                color = Divider,
                thickness = 0.5.dp,
                modifier = Modifier.width(24.dp),
            )
            PillIconButton(
                icon = Icons.Default.Delete,
                description = "Delete",
                onClick = onDelete,
            )
        }
    }
}

@Composable
private fun PillIconButton(
    icon: ImageVector,
    description: String,
    onClick: () -> Unit,
) {
    Box(
        modifier = Modifier
            .size(48.dp)
            .clickable(onClick = onClick),
        contentAlignment = Alignment.Center,
    ) {
        Icon(
            imageVector = icon,
            contentDescription = description,
            tint = TextSecondary,
            modifier = Modifier.size(20.dp),
        )
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
                            imageVector = Icons.AutoMirrored.Filled.Label,
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

// ── Message card ──────────────────────────────────────────────────────────────

@Composable
private fun MessageCard(message: MessageEntity, initiallyExpanded: Boolean) {
    var expanded by remember { mutableStateOf(initiallyExpanded) }

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .background(Black)
            .animateContentSize(),
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .clickable { expanded = !expanded }
                .padding(horizontal = 16.dp, vertical = 12.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Text(
                text = EmailParser.displayName(message.from).ifEmpty { message.from },
                color = TextPrimary,
                fontSize = 13.sp,
                fontWeight = FontWeight.SemiBold,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
                modifier = Modifier.weight(1f),
            )
            Spacer(modifier = Modifier.width(8.dp))
            Text(
                text = TimeFormatter.format(message.date),
                color = TextSecondary,
                fontSize = 12.sp,
            )
        }

        AnimatedVisibility(
            visible = expanded,
            enter = fadeIn(tween(220)),
            exit = fadeOut(tween(160)),
        ) {
            HtmlBody(
                html = buildHtml(message.body),
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(bottom = 12.dp),
            )
        }

        AnimatedVisibility(
            visible = !expanded,
            enter = fadeIn(tween(220)),
            exit = fadeOut(tween(160)),
        ) {
            Text(
                text = message.snippet,
                color = TextDisabled,
                fontSize = 12.sp,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp)
                    .padding(bottom = 12.dp),
            )
        }
    }
}

// ── WebView body ──────────────────────────────────────────────────────────────

@Composable
private fun HtmlBody(html: String, modifier: Modifier = Modifier) {
    val heightDp = remember { mutableStateOf(1.dp) }

    AndroidView(
        factory = { context ->
            WebView(context).apply {
                setBackgroundColor(android.graphics.Color.WHITE)
                settings.javaScriptEnabled = true
                settings.domStorageEnabled = false
                settings.useWideViewPort = true
                isScrollContainer = false
                overScrollMode = WebView.OVER_SCROLL_NEVER

                setOnTouchListener { v, event ->
                    if (event.action == MotionEvent.ACTION_MOVE) {
                        v.parent?.requestDisallowInterceptTouchEvent(false)
                    }
                    false
                }

                webViewClient = object : WebViewClient() {
                    override fun onPageFinished(view: WebView, url: String) {
                        view.post {
                            view.evaluateJavascript("""
                                (function() {
                                    document.querySelectorAll('[width]').forEach(function(el) {
                                        el.removeAttribute('width');
                                    });
                                    return Math.max(document.body.scrollHeight, document.documentElement.scrollHeight);
                                })()
                            """.trimIndent()) { result ->
                                result.toFloatOrNull()?.let { cssPixels ->
                                    heightDp.value = cssPixels.dp
                                }
                            }
                        }
                    }

                    override fun shouldOverrideUrlLoading(
                        view: WebView,
                        request: WebResourceRequest,
                    ): Boolean = true
                }
            }
        },
        update = { webView ->
            if (webView.tag != html) {
                webView.tag = html
                webView.loadDataWithBaseURL(null, html, "text/html", "UTF-8", null)
            }
        },
        modifier = modifier.height(heightDp.value),
    )
}

// ── HTML builder ──────────────────────────────────────────────────────────────

private val CSS_HTML = """
<style>
* {
    max-width: 100% !important;
    min-width: 0 !important;
    box-sizing: border-box !important;
}
html, body {
    background-color: #ffffff;
    color: #000000;
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
    font-size: 14px;
    line-height: 1.6;
    margin: 0;
    padding: 0 12px;
    word-wrap: break-word;
    overflow-wrap: break-word;
}
img, video {
    max-width: 100% !important;
    height: auto !important;
}
table {
    max-width: 100% !important;
    word-break: break-word;
}
pre, code {
    white-space: pre-wrap;
    font-size: 12px;
}
</style>
""".trimIndent()

private val CSS_PLAIN = """
<style>
* { box-sizing: border-box; }
html, body {
    background-color: #000000;
    color: #E8E8E8;
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
    font-size: 14px;
    line-height: 1.6;
    margin: 0;
    padding: 12px;
    word-wrap: break-word;
    overflow-wrap: break-word;
}
a { color: #7A9BB5; }
pre {
    white-space: pre-wrap;
    margin: 0;
}
</style>
""".trimIndent()

private val STYLE_BLOCK_RE = Regex("(?is)<style[^>]*>.*?</style>")
private val HEAD_RE        = Regex("(?is)<head[^>]*>.*?</head>")

private fun buildHtml(body: String): String {
    val emailStyles = HEAD_RE.find(body)?.let { head ->
        STYLE_BLOCK_RE.findAll(head.value).joinToString("\n") { it.value }
    } ?: ""

    val stripped = body
        .replace(Regex("(?is)<!DOCTYPE[^>]*>"), "")
        .replace(Regex("(?is)<html[^>]*>"), "")
        .replace(Regex("(?is)</html>"), "")
        .replace(HEAD_RE, "")
        .replace(Regex("(?is)<body[^>]*>"), "")
        .replace(Regex("(?is)</body>"), "")
        .trim()

    val isHtml = stripped.contains(Regex("<[a-zA-Z]"))

    val (css, content) = if (isHtml) {
        "$CSS_HTML\n$emailStyles" to stripped
    } else {
        val escaped = stripped
            .replace("&", "&amp;")
            .replace("<", "&lt;")
            .replace(">", "&gt;")
        CSS_PLAIN to "<pre>$escaped</pre>"
    }

    return """<!DOCTYPE html>
<html><head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
$css
</head><body>$content</body></html>"""
}
