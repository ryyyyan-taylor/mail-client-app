import 'dart:convert';
import 'dart:io';
import 'dart:math' show min;

import 'package:flutter/foundation.dart' show Factory;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../data/local/mail_database.dart';
import '../../providers/providers.dart';
import '../../util/email_parser.dart';
import '../../util/time_formatter.dart';
import '../inbox/inbox_screen.dart' show LabelPickerSheet;
import '../theme/colors.dart';
import 'thread_detail_notifier.dart';

// #region agent log
void _agentLog6480a1Td(
    String hypothesisId, String location, String message, Map<String, Object?> data) {
  final line = jsonEncode({
    'sessionId': '6480a1',
    'timestamp': DateTime.now().millisecondsSinceEpoch,
    'hypothesisId': hypothesisId,
    'location': location,
    'message': message,
    'data': data,
  });
  try {
    File('/home/rt/Code/mail-client-app/.cursor/debug-6480a1.log').writeAsStringSync(
      '$line\n',
      mode: FileMode.append,
    );
  } catch (_) {}
  debugPrint('DEBUG6480a1 $line');
}
// #endregion

// ── Screen ────────────────────────────────────────────────────────────────────

class ThreadDetailScreen extends ConsumerStatefulWidget {
  const ThreadDetailScreen({
    super.key,
    required this.threadId,
    this.contentOnly = false,
    this.onBack,
  });

  final String threadId;

  /// When true, skips Scaffold/AppBar for use in landscape two-pane layout.
  final bool contentOnly;

  /// Called when the user navigates back (used in landscape two-pane mode).
  final VoidCallback? onBack;

  @override
  ConsumerState<ThreadDetailScreen> createState() =>
      _ThreadDetailScreenState();
}

class _ThreadDetailScreenState extends ConsumerState<ThreadDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final notifier =
        ref.read(threadDetailNotifierProvider(widget.threadId).notifier);
    final state = ref.watch(threadDetailNotifierProvider(widget.threadId));

    // Navigate back when an action removes the thread from inbox.
    ref.listen<ThreadDetailUiState>(
      threadDetailNotifierProvider(widget.threadId),
      (prev, next) {
        if (next.navigateBack && prev?.navigateBack == false) {
          if (widget.contentOnly) {
            widget.onBack?.call();
          } else if (context.mounted) {
            context.pop();
          }
        }
        if (next.error != null && prev?.error == null) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(next.error!)));
          notifier.clearError();
        }
      },
    );

    final showPill = !state.isLoading || state.messages.isNotEmpty;

    if (widget.contentOnly) {
      return ColoredBox(
        color: kBlack,
        child: Stack(
          children: [
            _buildBody(context, state, notifier),
            Positioned(
              bottom: 16 + MediaQuery.viewPaddingOf(context).bottom,
              right: 16,
              child: _pillVisibility(showPill, state, notifier),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: kBlack,
      appBar: AppBar(
        backgroundColor: kBlack,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kTextSecondary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          state.subject,
          style: const TextStyle(
            color: kTextPrimary,
            fontSize: 15,
            fontWeight: FontWeight.normal,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: Stack(
        children: [
          _buildBody(context, state, notifier),
          Positioned(
            bottom: 16,
            right: 16,
            child: _pillVisibility(showPill, state, notifier),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ThreadDetailUiState state,
    ThreadDetailNotifier notifier,
  ) {
    if (state.isLoading && state.messages.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: kAccent));
    }

    return ListView.separated(
      padding: EdgeInsets.only(bottom: MediaQuery.viewPaddingOf(context).bottom),
      cacheExtent: 2000,
      itemCount: state.messages.length,
      separatorBuilder: (context, index) =>
          const Divider(height: 0.5, thickness: 0.5, color: kDivider),
      itemBuilder: (_, i) {
        final isLast = i == state.messages.length - 1;
        return _MessageCard(
          key: ValueKey(state.messages[i].id),
          message: state.messages[i],
          initiallyExpanded: isLast,
        );
      },
    );
  }

  Widget _pillVisibility(
    bool visible,
    ThreadDetailUiState state,
    ThreadDetailNotifier notifier,
  ) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.33),
            end: Offset.zero,
          ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOut)),
          child: child,
        ),
      ),
      child: visible
          ? _ThreadActionsPill(
              key: const ValueKey('pill'),
              isRead: state.isRead,
              onMove: () async {
                final selected = await showModalBottomSheet<Label>(
                  context: context,
                  backgroundColor: kSurfaceDark,
                  builder: (_) =>
                      LabelPickerSheet(labels: state.availableLabels),
                );
                if (selected != null) notifier.moveToLabel(selected.id);
              },
              onDelete: notifier.delete,
              onSpam: notifier.spam,
              onToggleRead: notifier.toggleRead,
            )
          : const SizedBox.shrink(key: ValueKey('empty')),
    );
  }
}

// ── Thread actions pill ───────────────────────────────────────────────────────

class _ThreadActionsPill extends StatelessWidget {
  const _ThreadActionsPill({
    super.key,
    required this.isRead,
    required this.onMove,
    required this.onDelete,
    required this.onSpam,
    required this.onToggleRead,
  });

  final bool isRead;
  final VoidCallback onMove;
  final VoidCallback onDelete;
  final VoidCallback onSpam;
  final VoidCallback onToggleRead;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kSurfaceDark,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
              color: Colors.black45,
              blurRadius: 8,
              offset: Offset(0, 2))
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // More — overflow menu
          SizedBox(
            width: 48,
            height: 48,
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert,
                  size: 20, color: kTextSecondary),
              color: kSurfaceDark,
              onSelected: (v) {
                if (v == 'spam') onSpam();
                if (v == 'toggle_read') onToggleRead();
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'spam',
                  child: Text('Mark as spam',
                      style:
                          TextStyle(color: kTextPrimary, fontSize: 14)),
                ),
                PopupMenuItem(
                  value: 'toggle_read',
                  child: Text(
                    isRead ? 'Mark as unread' : 'Mark as read',
                    style:
                        const TextStyle(color: kTextPrimary, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
          Container(width: 24, height: 0.5, color: kDivider),
          _PillButton(
              icon: Icons.label_outline,
              tooltip: 'Move to label',
              onPressed: onMove),
          Container(width: 24, height: 0.5, color: kDivider),
          _PillButton(
              icon: Icons.delete_outline,
              tooltip: 'Delete',
              onPressed: onDelete),
        ],
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: IconButton(
        icon: Icon(icon, size: 20, color: kTextSecondary),
        tooltip: tooltip,
        onPressed: onPressed,
      ),
    );
  }
}

// ── Message card ──────────────────────────────────────────────────────────────

class _MessageCard extends StatefulWidget {
  const _MessageCard({
    super.key,
    required this.message,
    required this.initiallyExpanded,
  });
  final Message message;
  final bool initiallyExpanded;

  @override
  State<_MessageCard> createState() => _MessageCardState();
}

class _MessageCardState extends State<_MessageCard>
    with AutomaticKeepAliveClientMixin {
  late bool _expanded;

  @override
  void initState() {
    // Before super: AutomaticKeepAliveClientMixin.initState reads wantKeepAlive.
    _expanded = widget.initiallyExpanded;
    super.initState();
  }

  @override
  bool get wantKeepAlive => _expanded;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final msg = widget.message;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row — tap to toggle
        InkWell(
          onTap: () {
            setState(() => _expanded = !_expanded);
            updateKeepAlive();
          },
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    EmailParser.displayName(msg.fromAddress).isNotEmpty
                        ? EmailParser.displayName(msg.fromAddress)
                        : msg.fromAddress,
                    style: const TextStyle(
                      color: kTextPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  TimeFormatter.format(msg.date),
                  style:
                      const TextStyle(color: kTextSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
        ),

        // Body or snippet
        if (_expanded)
          _HtmlBody(html: _buildHtml(msg.body))
        else
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Text(
              msg.snippet,
              style: const TextStyle(
                  color: kTextDisabled, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }
}

// ── WebView HTML body ─────────────────────────────────────────────────────────

class _HtmlBody extends StatefulWidget {
  const _HtmlBody({required this.html});
  final String html;

  @override
  State<_HtmlBody> createState() => _HtmlBodyState();
}

class _HtmlBodyState extends State<_HtmlBody> {
  /// WebView inside [ListView]: the list's vertical drag recognizer wins unless
  /// we register these so the WebView can claim drags (see [WebViewWidget] docs).
  static final Set<Factory<OneSequenceGestureRecognizer>> _gestureRecognizers =
      <Factory<OneSequenceGestureRecognizer>>{
    Factory<VerticalDragGestureRecognizer>(() => VerticalDragGestureRecognizer()),
    Factory<HorizontalDragGestureRecognizer>(() => HorizontalDragGestureRecognizer()),
  };

  late final WebViewController _controller;
  // null = not yet measured; use screen height as placeholder so the WebView
  // has a real viewport and scrollHeight is computed correctly.
  double? _measuredHeight;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) async {
          // Brief delay lets images and CSS settle before measuring layout.
          await Future.delayed(const Duration(milliseconds: 200));
          if (mounted) _measureHeight();
        },
        onNavigationRequest: (_) => NavigationDecision.prevent,
      ))
      ..loadHtmlString(widget.html);
  }

  @override
  void didUpdateWidget(_HtmlBody old) {
    super.didUpdateWidget(old);
    // Reload guard — only load if html changed.
    if (widget.html != old.html) {
      _measuredHeight = null;
      _controller.loadHtmlString(widget.html);
    }
  }

  Future<void> _measureHeight() async {
    final result = await _controller.runJavaScriptReturningResult(
      '(function(){'
      'document.querySelectorAll("[width]").forEach(function(el){'
      '  el.removeAttribute("width");'
      '});'
      'return Math.max('
      '  document.body ? document.body.scrollHeight : 0,'
      '  document.documentElement.scrollHeight'
      ');'
      '})()',
    );
    final raw = result.toString();
    final h = double.tryParse(raw) ?? 0;
    if (mounted && h > 0) setState(() => _measuredHeight = h);
    // #region agent log
    _agentLog6480a1Td('H1', 'thread_detail_screen:_measureHeight', 'js measure', {
      'rawLen': raw.length,
      'rawPrefix': raw.length > 80 ? raw.substring(0, 80) : raw,
      'parsedH': h,
      'willApply': h > 0,
    });
    // #endregion
  }

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.sizeOf(context).height;
    // Cap height so each list row stays ~one viewport tall; long HTML scrolls
    // inside the WebView. Uncapped scrollHeight (often 10–25k css px) made
    // ListView children enormous and caused WebView recycle / viewport flashes.
    final maxBodyH = screenH * 0.95;
    final contentH = _measuredHeight ?? screenH;
    final height = min(contentH, maxBodyH);
    // #region agent log
    _agentLog6480a1Td('H3', 'thread_detail_screen:_HtmlBody.build', 'layout', {
      'screenH': screenH,
      'maxBodyH': maxBodyH,
      'measuredNull': _measuredHeight == null,
      'measuredH': _measuredHeight,
      'contentH': contentH,
      'finalHeight': height,
      'nestedGestureFix': true,
    });
    // #endregion
    return SizedBox(
      height: height,
      child: WebViewWidget(
        controller: _controller,
        gestureRecognizers: _gestureRecognizers,
      ),
    );
  }
}

// ── HTML builder ──────────────────────────────────────────────────────────────

const _cssHtml = '''
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
</style>''';

const _cssPlain = '''
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
</style>''';

final _styleBlockRe =
    RegExp(r'<style[^>]*>.*?</style>', caseSensitive: false, dotAll: true);
final _headRe =
    RegExp(r'<head[^>]*>.*?</head>', caseSensitive: false, dotAll: true);

String _buildHtml(String body) {
  // Extract <style> blocks from the original <head> (contains @media rules etc.)
  final emailStyles = _headRe.firstMatch(body)?.group(0)?.let((head) {
        return _styleBlockRe
            .allMatches(head)
            .map((m) => m.group(0)!)
            .join('\n');
      }) ??
      '';

  final stripped = body
      .replaceAll(RegExp(r'<!DOCTYPE[^>]*>', caseSensitive: false), '')
      .replaceAll(RegExp(r'<html[^>]*>', caseSensitive: false), '')
      .replaceAll(RegExp(r'</html>', caseSensitive: false), '')
      .replaceAll(_headRe, '')
      .replaceAll(RegExp(r'<body[^>]*>', caseSensitive: false), '')
      .replaceAll(RegExp(r'</body>', caseSensitive: false), '')
      .trim();

  final isHtml = stripped.contains(RegExp(r'<[a-zA-Z]'));

  final String css;
  final String content;
  if (isHtml) {
    css = '$_cssHtml\n$emailStyles';
    content = stripped;
  } else {
    css = _cssPlain;
    final escaped = stripped
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;');
    content = '<pre>$escaped</pre>';
  }

  return '<!DOCTYPE html>'
      '<html><head>'
      '<meta charset="UTF-8">'
      '<meta name="viewport" content="width=device-width, initial-scale=1.0">'
      '$css'
      '</head><body>$content</body></html>';
}

extension _LetX<T> on T {
  R let<R>(R Function(T) f) => f(this);
}
