package com.mail.client.ui.thread

import android.view.MotionEvent
import android.webkit.WebResourceRequest
import android.webkit.WebView
import android.webkit.WebViewClient
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
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
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.viewinterop.AndroidView
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
    viewModel: ThreadDetailViewModel = koinViewModel(key = threadId, parameters = { parametersOf(threadId) }),
) {
    val uiState by viewModel.uiState.collectAsState()
    val snackbarHostState = remember { SnackbarHostState() }

    LaunchedEffect(uiState.error) {
        if (uiState.error != null) {
            snackbarHostState.showSnackbar(uiState.error!!)
            viewModel.clearError()
        }
    }

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
        when {
            uiState.isLoading && uiState.messages.isEmpty() -> {
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(paddingValues),
                    contentAlignment = Alignment.Center,
                ) {
                    CircularProgressIndicator(color = Accent)
                }
            }

            else -> {
                LazyColumn(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(paddingValues),
                ) {
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
    }
}

@Composable
private fun MessageCard(message: MessageEntity, initiallyExpanded: Boolean) {
    var expanded by remember { mutableStateOf(initiallyExpanded) }

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .background(Black),
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

        if (expanded) {
            HtmlBody(
                html = buildHtml(message.body),
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(bottom = 12.dp),
            )
        } else {
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

@Composable
private fun HtmlBody(html: String, modifier: Modifier = Modifier) {
    // CSS pixels (from JS scrollHeight) equal dp when the viewport is width=device-width.
    // Do NOT convert with density — that would divide by e.g. 2.75 and make the view too small.
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

                // WebView steals the gesture on ACTION_DOWN via requestDisallowInterceptTouchEvent(true).
                // Resetting it on ACTION_MOVE lets LazyColumn reclaim vertical scrolls.
                // ACTION_DOWN is untouched so link taps still fire.
                setOnTouchListener { v, event ->
                    if (event.action == MotionEvent.ACTION_MOVE) {
                        v.parent?.requestDisallowInterceptTouchEvent(false)
                    }
                    false
                }

                webViewClient = object : WebViewClient() {
                    override fun onPageFinished(view: WebView, url: String) {
                        // post() waits for the layout pass so scrollHeight is accurate.
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
            // Only reload when HTML actually changes, not on every recomposition.
            if (webView.tag != html) {
                webView.tag = html
                webView.loadDataWithBaseURL(null, html, "text/html", "UTF-8", null)
            }
        },
        modifier = modifier.height(heightDp.value),
    )
}

// ── HTML builder ──────────────────────────────────────────────────────────────

// HTML emails get a white background — that's what virtually all email templates expect.
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
    padding: 0;
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

// Plain text stays dark — it's rendered in our own chrome, not the email's.
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
    // Preserve <style> blocks from the original <head> — they contain responsive
    // @media queries that reformat the email layout for narrow screens.
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
        // Our base CSS first, then the email's own styles so its @media rules win.
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
