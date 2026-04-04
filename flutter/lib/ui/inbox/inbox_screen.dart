import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/local/mail_database.dart';
import '../../providers/providers.dart';
import '../../router.dart';
import '../../util/email_parser.dart';
import '../../util/time_formatter.dart';
import '../theme/colors.dart';
import '../settings/settings_sheet.dart';
import '../thread/thread_detail_screen.dart';
import 'inbox_notifier.dart';

// ── Screen ────────────────────────────────────────────────────────────────────

class InboxScreen extends ConsumerStatefulWidget {
  const InboxScreen({super.key, this.initialSelectedThreadId});

  /// Non-null when launched from a notification tap in landscape mode.
  final String? initialSelectedThreadId;

  @override
  ConsumerState<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends ConsumerState<InboxScreen> {
  String? _selectedThreadId;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _selectedThreadId = widget.initialSelectedThreadId;
    _scrollController.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(InboxScreen old) {
    super.didUpdateWidget(old);
    if (widget.initialSelectedThreadId != old.initialSelectedThreadId &&
        widget.initialSelectedThreadId != null) {
      setState(() => _selectedThreadId = widget.initialSelectedThreadId);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 400) {
      ref.read(inboxNotifierProvider.notifier).loadNextPage();
    }
  }

  Future<void> _showSectionPicker() async {
    ref.read(inboxNotifierProvider.notifier).refreshLabels();
    final section = await showModalBottomSheet<Section>(
      context: context,
      backgroundColor: kSurfaceDark,
      builder: (_) => _SectionPickerSheet(
        currentSection: ref.read(inboxNotifierProvider).currentSection,
      ),
    );
    if (section != null && mounted) {
      ref.read(inboxNotifierProvider.notifier).setSection(section);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(inboxNotifierProvider);
    final notifier = ref.read(inboxNotifierProvider.notifier);
    final isSelectionMode = state.selectedIds.isNotEmpty;
    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;

    // Show errors via snackbar.
    ref.listen<InboxUiState>(inboxNotifierProvider, (_, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!)),
        );
        notifier.clearError();
      }
    });

    return PopScope(
      canPop: !isSelectionMode,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) notifier.exitSelectionMode();
      },
      child: Scaffold(
        backgroundColor: kBlack,
        // In landscape the AppBar lives inside the left pane's NestedScrollView
        // so it can scroll-hide independently of the right pane.
        appBar: isLandscape
            ? null
            : AppBar(
                backgroundColor: kBlack,
                surfaceTintColor: Colors.transparent,
                title: _titleWidget(state),
                actions: _appBarActions(state),
              ),
        body: isLandscape
            ? _buildLandscapeBody(state, isSelectionMode)
            : _InboxListContent(
                scrollController: _scrollController,
                onThreadClick: (id) => context.push(Routes.thread(id)),
                onSwipeMoveRequest: _showSwipeMovePicker,
              ),
      ),
    );
  }

  // ── AppBar content helpers (shared between portrait AppBar and landscape SliverAppBar) ──

  Widget _titleWidget(InboxUiState state) {
    return GestureDetector(
      onTap: _showSectionPicker,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            state.currentSection.displayName,
            style: const TextStyle(
              color: kTextPrimary,
              fontSize: 18,
              fontWeight: FontWeight.normal,
              letterSpacing: 1,
            ),
          ),
          const Icon(Icons.arrow_drop_down, color: kTextSecondary, size: 20),
        ],
      ),
    );
  }

  List<Widget> _appBarActions(InboxUiState state) {
    return [
      if (state.isRefreshing)
        const Center(
          child: Padding(
            padding: EdgeInsets.only(right: 16),
            child: SizedBox(
              width: 20,
              height: 20,
              child:
                  CircularProgressIndicator(color: kAccent, strokeWidth: 2),
            ),
          ),
        )
      else
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: kTextSecondary),
          color: kSurfaceDark,
          onSelected: (value) async {
            if (value == 'settings') {
              final signedOut = await showModalBottomSheet<bool>(
                context: context,
                backgroundColor: kSurfaceDark,
                isScrollControlled: true,
                builder: (_) => const SettingsSheet(),
              );
              if (signedOut == true && mounted) {
                context.go(Routes.signIn);
              }
            }
          },
          itemBuilder: (_) => [
            const PopupMenuItem(
              value: 'settings',
              child: Text('Settings',
                  style: TextStyle(color: kTextPrimary, fontSize: 14)),
            ),
          ],
        ),
    ];
  }

  // ── Landscape two-pane layout ─────────────────────────────────────────────

  Widget _buildLandscapeBody(InboxUiState state, bool isSelectionMode) {
    return Row(
      children: [
        Expanded(
          child: NotificationListener<ScrollUpdateNotification>(
            onNotification: (notification) {
              // Drive pagination from the inner list scroll.
              if (notification.depth == 0 &&
                  notification.metrics.pixels >=
                      notification.metrics.maxScrollExtent - 400) {
                ref.read(inboxNotifierProvider.notifier).loadNextPage();
              }
              return false;
            },
            child: NestedScrollView(
              headerSliverBuilder: (_, __) => [
                SliverAppBar(
                  floating: true,
                  snap: true,
                  automaticallyImplyLeading: false,
                  backgroundColor: kBlack,
                  surfaceTintColor: Colors.transparent,
                  title: _titleWidget(state),
                  actions: _appBarActions(state),
                ),
              ],
              // scrollController is null — NestedScrollView manages inner scroll.
              body: _InboxListContent(
                scrollController: null,
                onThreadClick: (id) =>
                    setState(() => _selectedThreadId = id),
                onSwipeMoveRequest: _showSwipeMovePicker,
              ),
            ),
          ),
        ),
        const VerticalDivider(width: 0.5, thickness: 0.5, color: kDivider),
        Expanded(
          child: _selectedThreadId != null
              ? KeyedSubtree(
                  key: ValueKey(_selectedThreadId),
                  child: ThreadDetailScreen(
                    threadId: _selectedThreadId!,
                    contentOnly: true,
                    onBack: () =>
                        setState(() => _selectedThreadId = null),
                  ),
                )
              : const Center(
                  child: Text(
                    'select a thread',
                    style: TextStyle(
                        color: kTextDisabled,
                        fontSize: 14,
                        letterSpacing: 0.5),
                  ),
                ),
        ),
      ],
    );
  }

  Future<void> _showSwipeMovePicker(Thread thread) async {
    final labels = ref.read(inboxNotifierProvider).availableLabels;
    final selected = await showModalBottomSheet<Label>(
      context: context,
      backgroundColor: kSurfaceDark,
      builder: (_) => LabelPickerSheet(labels: labels),
    );
    if (selected != null && mounted) {
      final notifier = ref.read(inboxNotifierProvider.notifier);
      notifier.hideThread(thread.id);
      _showMoveSnackbar(context, notifier, thread.id, selected);
    }
  }
}

// ── Thread list content ───────────────────────────────────────────────────────

class _InboxListContent extends ConsumerWidget {
  const _InboxListContent({
    required this.scrollController,
    required this.onThreadClick,
    required this.onSwipeMoveRequest,
  });

  /// Null in landscape — NestedScrollView's PrimaryScrollController is used instead.
  final ScrollController? scrollController;
  final void Function(String threadId) onThreadClick;

  /// Called when the user swipes right on a thread row.
  /// Parent is responsible for showing the label picker sheet.
  final Future<void> Function(Thread) onSwipeMoveRequest;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(inboxNotifierProvider);
    final notifier = ref.read(inboxNotifierProvider.notifier);
    final isSelectionMode = state.selectedIds.isNotEmpty;

    return Stack(
      children: [
        RefreshIndicator(
          color: kAccent,
          backgroundColor: kSurfaceDark,
          onRefresh: () async => notifier.refresh(),
          child: _buildList(context, ref, state, notifier, isSelectionMode),
        ),

        // Selection pill — slides in from bottom when selection mode is active.
        Align(
          alignment: Alignment.bottomCenter,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                        begin: const Offset(0, 1), end: Offset.zero)
                    .animate(animation),
                child: child,
              ),
            ),
            child: isSelectionMode
                ? Padding(
                    key: const ValueKey('pill'),
                    padding: EdgeInsets.only(
                      bottom: 16 + MediaQuery.viewPaddingOf(context).bottom,
                    ),
                    child: _SelectionPill(
                      count: state.selectedIds.size,
                      onClose: notifier.exitSelectionMode,
                      onDelete: () {
                        final ids = notifier.startBatchDelete();
                        final count = ids.length;
                        final batchTrashSb = SnackBar(
                          duration: const Duration(seconds: 5),
                          persist: false,
                          content: Text(
                              'Moved $count thread${count > 1 ? 's' : ''} to Trash'),
                          action: SnackBarAction(
                            label: 'Undo',
                            onPressed: () {
                              for (final id in ids) notifier.unhideThread(id);
                            },
                          ),
                        );
                        final ctrl =
                            ScaffoldMessenger.of(context).showSnackBar(batchTrashSb);
                        ctrl.closed.then((reason) {
                          if (reason != SnackBarClosedReason.action) {
                            notifier.confirmBatchDelete(ids);
                          }
                        });
                      },
                      onMoveRequest: () async {
                        final labels = ref
                            .read(inboxNotifierProvider)
                            .availableLabels;
                        if (!context.mounted) return;
                        final selected =
                            await showModalBottomSheet<Label>(
                          context: context,
                          backgroundColor: kSurfaceDark,
                          builder: (_) =>
                              LabelPickerSheet(labels: labels),
                        );
                        if (selected == null || !context.mounted) return;
                        final ids = notifier.startBatchMove();
                        final count = ids.length;
                        final batchMoveSb = SnackBar(
                          duration: const Duration(seconds: 5),
                          persist: false,
                          content: Text(
                              'Moved $count thread${count > 1 ? 's' : ''} to ${selected.name}'),
                          action: SnackBarAction(
                            label: 'Undo',
                            onPressed: () {
                              for (final id in ids) notifier.unhideThread(id);
                            },
                          ),
                        );
                        final ctrl =
                            ScaffoldMessenger.of(context).showSnackBar(batchMoveSb);
                        ctrl.closed.then((reason) {
                          if (reason != SnackBarClosedReason.action) {
                            notifier.confirmBatchMove(ids, selected.id);
                          }
                        });
                      },
                      onSpam: () {
                        final ids = notifier.startBatchSpam();
                        final count = ids.length;
                        final batchSpamSb = SnackBar(
                          duration: const Duration(seconds: 5),
                          persist: false,
                          content: Text(
                              'Marked $count thread${count > 1 ? 's' : ''} as spam'),
                          action: SnackBarAction(
                            label: 'Undo',
                            onPressed: () {
                              for (final id in ids) notifier.unhideThread(id);
                            },
                          ),
                        );
                        final ctrl =
                            ScaffoldMessenger.of(context).showSnackBar(batchSpamSb);
                        ctrl.closed.then((reason) {
                          if (reason != SnackBarClosedReason.action) {
                            notifier.confirmBatchSpam(ids);
                          }
                        });
                      },
                      onMarkRead: notifier.markSelectedRead,
                      onMarkUnread: notifier.markSelectedUnread,
                    ),
                  )
                : const SizedBox.shrink(key: ValueKey('empty')),
          ),
        ),
      ],
    );
  }

  Widget _buildList(
    BuildContext context,
    WidgetRef ref,
    InboxUiState state,
    InboxNotifier notifier,
    bool isSelectionMode,
  ) {
    if (state.isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: kAccent));
    }

    if (state.threads.isEmpty) {
      return ListView(
        // Wrap in ListView so RefreshIndicator works on empty state.
        padding: EdgeInsets.only(bottom: MediaQuery.viewPaddingOf(context).bottom),
        children: const [
          SizedBox(height: 200),
          Center(
            child: Text(
              'no messages',
              style: TextStyle(
                  color: kTextDisabled, fontSize: 14, letterSpacing: 0.5),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      controller: scrollController,
      primary: scrollController == null,
      padding: EdgeInsets.only(bottom: MediaQuery.viewPaddingOf(context).bottom),
      itemCount: state.threads.length + (state.isLoadingMore ? 1 : 0),
      itemBuilder: (_, i) {
        if (i == state.threads.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    color: kAccent, strokeWidth: 2),
              ),
            ),
          );
        }

        final thread = state.threads[i];
        final showDivider = i < state.threads.length - 1;

        if (isSelectionMode) {
          return Column(children: [
            ThreadListItem(
              thread: thread,
              isSelected: state.selectedIds.contains(thread.id),
              isSelectionMode: true,
              onTap: () => notifier.toggleSelection(thread.id),
            ),
            if (showDivider)
              const Divider(
                  height: 0.5, thickness: 0.5, color: kDivider),
          ]);
        }

        return _SwipeableThreadItem(
          thread: thread,
          showDivider: showDivider,
          onTap: () => onThreadClick(thread.id),
          onLongPress: () => notifier.enterSelectionMode(thread.id),
          onSwipeDelete: () {
            notifier.hideThread(thread.id);
            _showDeleteSnackbar(context, notifier, thread.id);
          },
          onSwipeMoveRequest: () {
            // Fire and forget: confirmDismiss returns false immediately,
            // Dismissible snaps back, then parent shows the sheet.
            Future.delayed(Duration.zero,
                () => onSwipeMoveRequest(thread));
          },
        );
      },
    );
  }
}

// ── Snackbar helpers ──────────────────────────────────────────────────────────

void _showDeleteSnackbar(
    BuildContext context, InboxNotifier notifier, String threadId) {
  final swipeTrashSb = SnackBar(
    duration: const Duration(seconds: 5),
    persist: false,
    content: const Text('Moved to Trash'),
    action: SnackBarAction(
      label: 'Undo',
      onPressed: () => notifier.unhideThread(threadId),
    ),
  );
  final ctrl = ScaffoldMessenger.of(context).showSnackBar(swipeTrashSb);
  ctrl.closed.then((reason) {
    if (reason != SnackBarClosedReason.action) {
      notifier.confirmDelete(threadId);
    }
  });
}

void _showMoveSnackbar(
    BuildContext context, InboxNotifier notifier, String threadId, Label label) {
  final swipeMoveSb = SnackBar(
    duration: const Duration(seconds: 5),
    persist: false,
    content: Text('Moved to ${label.name}'),
    action: SnackBarAction(
      label: 'Undo',
      onPressed: () => notifier.unhideThread(threadId),
    ),
  );
  final ctrl = ScaffoldMessenger.of(context).showSnackBar(swipeMoveSb);
  ctrl.closed.then((reason) {
    if (reason != SnackBarClosedReason.action) {
      notifier.confirmMove(threadId, label.id);
    }
  });
}

// ── Swipeable thread item ─────────────────────────────────────────────────────

class _SwipeableThreadItem extends StatelessWidget {
  const _SwipeableThreadItem({
    required this.thread,
    required this.showDivider,
    required this.onTap,
    required this.onLongPress,
    required this.onSwipeDelete,
    required this.onSwipeMoveRequest,
  });

  final Thread thread;
  final bool showDivider;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onSwipeDelete;

  /// Called synchronously when user swipes right; should fire-and-forget
  /// the label picker so [Dismissible.confirmDismiss] can return false
  /// immediately (snapping the item back).
  final VoidCallback onSwipeMoveRequest;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(thread.id),
      background: _swipeBackground(
          alignment: Alignment.centerLeft,
          color: kAccent,
          icon: Icons.label),
      secondaryBackground: _swipeBackground(
          alignment: Alignment.centerRight,
          color: kDanger,
          icon: Icons.delete),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          onSwipeMoveRequest(); // snap back immediately; sheet shown async
          return false;
        }
        return true; // allow delete animation
      },
      onDismissed: (_) => onSwipeDelete(),
      child: Column(
        children: [
          ThreadListItem(
            thread: thread,
            onTap: onTap,
            onLongPress: onLongPress,
          ),
          if (showDivider)
            const Divider(height: 0.5, thickness: 0.5, color: kDivider),
        ],
      ),
    );
  }

  Widget _swipeBackground({
    required Alignment alignment,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      color: color,
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Icon(icon, color: Colors.white),
    );
  }
}

// ── Thread list item ──────────────────────────────────────────────────────────

class ThreadListItem extends StatelessWidget {
  const ThreadListItem({
    super.key,
    required this.thread,
    this.onTap,
    this.onLongPress,
    this.isSelected = false,
    this.isSelectionMode = false,
  });

  final Thread thread;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isSelected;
  final bool isSelectionMode;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        color: isSelected ? kSurfaceVariant : kBlack,
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        child: Row(
          children: [
            // Unread dot or selection indicator
            if (isSelectionMode)
              Icon(
                isSelected
                    ? Icons.check_circle
                    : Icons.radio_button_unchecked,
                size: 16,
                color: isSelected ? kAccent : kTextSecondary,
              )
            else
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: thread.isRead ? kBlack : kUnreadDot,
                ),
              ),

            SizedBox(width: isSelectionMode ? 8 : 10),

            // Sender (fixed width)
            SizedBox(
              width: 110,
              child: Text(
                EmailParser.displayName(thread.fromAddress).isEmpty
                    ? '?'
                    : EmailParser.displayName(thread.fromAddress),
                style: TextStyle(
                  color:
                      thread.isRead ? kTextSecondary : kTextPrimary,
                  fontSize: 14,
                  fontWeight: thread.isRead
                      ? FontWeight.normal
                      : FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            const SizedBox(width: 8),

            // Subject (expands)
            Expanded(
              child: Text(
                thread.subject,
                style: TextStyle(
                  color:
                      thread.isRead ? kTextSecondary : kTextPrimary,
                  fontSize: 14,
                  fontWeight: thread.isRead
                      ? FontWeight.normal
                      : FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            const SizedBox(width: 8),

            // Timestamp
            Text(
              TimeFormatter.format(thread.lastMessageTimestamp),
              style: const TextStyle(
                  color: kTextSecondary, fontSize: 13),
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Selection pill ────────────────────────────────────────────────────────────

class _SelectionPill extends StatelessWidget {
  const _SelectionPill({
    required this.count,
    required this.onClose,
    required this.onDelete,
    required this.onMoveRequest,
    required this.onSpam,
    required this.onMarkRead,
    required this.onMarkUnread,
  });

  final int count;
  final VoidCallback onClose;
  final VoidCallback onDelete;
  final VoidCallback onMoveRequest;
  final VoidCallback onSpam;
  final VoidCallback onMarkRead;
  final VoidCallback onMarkUnread;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: kSurfaceDark,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
              color: Colors.black45, blurRadius: 8, offset: Offset(0, 2))
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PillIconButton(
              icon: Icons.close,
              tooltip: 'Exit selection',
              onPressed: onClose),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text(
              '$count selected',
              style: const TextStyle(color: kTextPrimary, fontSize: 13),
            ),
          ),
          // Overflow menu
          SizedBox(
            width: 48,
            height: 48,
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert,
                  size: 20, color: kTextSecondary),
              color: kSurfaceDark,
              onSelected: (value) {
                if (value == 'spam') onSpam();
                if (value == 'read') onMarkRead();
                if (value == 'unread') onMarkUnread();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                    value: 'spam',
                    child: Text('Mark as spam',
                        style: TextStyle(
                            color: kTextPrimary, fontSize: 14))),
                PopupMenuItem(
                    value: 'read',
                    child: Text('Mark as read',
                        style: TextStyle(
                            color: kTextPrimary, fontSize: 14))),
                PopupMenuItem(
                    value: 'unread',
                    child: Text('Mark as unread',
                        style: TextStyle(
                            color: kTextPrimary, fontSize: 14))),
              ],
            ),
          ),
          _PillIconButton(
              icon: Icons.label_outline,
              tooltip: 'Move to label',
              onPressed: onMoveRequest),
          _PillIconButton(
              icon: Icons.delete_outline,
              tooltip: 'Delete',
              onPressed: onDelete),
        ],
      ),
    );
  }
}

class _PillIconButton extends StatelessWidget {
  const _PillIconButton({
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

// ── Section picker sheet ──────────────────────────────────────────────────────

class _SectionPickerSheet extends ConsumerWidget {
  const _SectionPickerSheet({required this.currentSection});

  final Section currentSection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allLabels =
        ref.watch(inboxNotifierProvider.select((s) => s.availableLabels));
    final userLabels = allLabels
        .where((l) => l.type != 'system')
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          ...systemSections.map((section) => _SectionRow(
                name: section.displayName,
                isSelected: section.labelId == currentSection.labelId,
                onTap: () => Navigator.pop(context, section),
              )),
          if (userLabels.isNotEmpty) ...[
            const Divider(height: 1, thickness: 0.5, color: kDivider),
            ...userLabels.map((label) => _SectionRow(
                  name: label.name.toLowerCase(),
                  isSelected: label.id == currentSection.labelId,
                  onTap: () => Navigator.pop(
                      context, Section(label.id, label.name.toLowerCase())),
                )),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _SectionRow extends StatelessWidget {
  const _SectionRow({
    required this.name,
    required this.isSelected,
    required this.onTap,
  });

  final String name;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Text(
          name,
          style: TextStyle(
            color: isSelected ? kAccent : kTextPrimary,
            fontSize: 15,
            fontWeight:
                isSelected ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

// ── Label picker sheet ────────────────────────────────────────────────────────

/// Exported — used from inbox swipe/batch and from thread detail (Phase 7).
class LabelPickerSheet extends StatelessWidget {
  const LabelPickerSheet({super.key, required this.labels});

  final List<Label> labels;

  @override
  Widget build(BuildContext context) {
    final userLabels = labels
        .where((l) => l.type != 'system')
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 4),
            child: Text(
              'Move to label',
              style: TextStyle(
                  color: kTextPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w500),
            ),
          ),
          if (userLabels.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Text(
                'No labels found. Create labels in Gmail to use this feature.',
                style: TextStyle(color: kTextSecondary, fontSize: 13),
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: userLabels.length,
                separatorBuilder: (_, __) => const Divider(
                    height: 0.5, thickness: 0.5, color: kDivider),
                itemBuilder: (_, i) {
                  final label = userLabels[i];
                  return InkWell(
                    onTap: () => Navigator.pop(context, label),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                      child: Row(
                        children: [
                          const Icon(Icons.label_outline,
                              size: 18, color: kAccent),
                          const SizedBox(width: 14),
                          Text(
                            label.name,
                            style: const TextStyle(
                                color: kTextPrimary, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ── Extension ─────────────────────────────────────────────────────────────────

extension on Set<String> {
  int get size => length;
}
