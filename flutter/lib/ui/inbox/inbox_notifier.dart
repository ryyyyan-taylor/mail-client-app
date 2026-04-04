import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/local/mail_database.dart';
import '../../providers/providers.dart';

// ── Section ───────────────────────────────────────────────────────────────────

class Section {
  const Section(this.labelId, this.displayName);
  final String labelId;
  final String displayName;

  @override
  bool operator ==(Object other) =>
      other is Section && other.labelId == labelId;

  @override
  int get hashCode => labelId.hashCode;
}

const inboxSection = Section('INBOX', 'inbox');

const systemSections = [
  inboxSection,
  Section('SENT', 'sent'),
  Section('TRASH', 'trash'),
  Section('SPAM', 'spam'),
];

// ── State ─────────────────────────────────────────────────────────────────────

class InboxUiState {
  const InboxUiState({
    this.threads = const [],
    this.isLoading = false,
    this.isRefreshing = false,
    this.error,
    this.nextPageToken,
    this.isLoadingMore = false,
    this.availableLabels = const [],
    this.selectedIds = const {},
    this.currentSection = inboxSection,
  });

  final List<Thread> threads;
  final bool isLoading;
  final bool isRefreshing;
  final String? error;
  final String? nextPageToken;
  final bool isLoadingMore;
  final List<Label> availableLabels;
  final Set<String> selectedIds;
  final Section currentSection;

  InboxUiState copyWith({
    List<Thread>? threads,
    bool? isLoading,
    bool? isRefreshing,
    Object? error = _sentinel,
    Object? nextPageToken = _sentinel,
    bool? isLoadingMore,
    List<Label>? availableLabels,
    Set<String>? selectedIds,
    Section? currentSection,
  }) {
    return InboxUiState(
      threads: threads ?? this.threads,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      error: identical(error, _sentinel) ? this.error : error as String?,
      nextPageToken: identical(nextPageToken, _sentinel)
          ? this.nextPageToken
          : nextPageToken as String?,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      availableLabels: availableLabels ?? this.availableLabels,
      selectedIds: selectedIds ?? this.selectedIds,
      currentSection: currentSection ?? this.currentSection,
    );
  }
}

const _sentinel = Object();

// ── Notifier ──────────────────────────────────────────────────────────────────

class InboxNotifier extends Notifier<InboxUiState> {
  final _hiddenIds = <String>{};
  var _rawThreads = <Thread>[];
  StreamSubscription<List<Thread>>? _sub;

  @override
  InboxUiState build() {
    ref.onDispose(() => _sub?.cancel());
    _subscribeToSection(inboxSection.labelId);
    Future.microtask(() => _syncSection(isRefresh: false));
    Future.microtask(_loadLabels);
    return const InboxUiState();
  }

  // ── Stream ────────────────────────────────────────────────────────────────

  void _subscribeToSection(String labelId) {
    _sub?.cancel();
    _sub = ref
        .read(mailRepositoryProvider)
        .observeForLabel(labelId)
        .listen((threads) {
      _rawThreads = threads;
      state = state.copyWith(threads: _filtered());
    });
  }

  List<Thread> _filtered() =>
      _rawThreads.where((t) => !_hiddenIds.contains(t.id)).toList();

  // ── Public ────────────────────────────────────────────────────────────────

  void refresh() => _syncSection(isRefresh: true);

  void setSection(Section section) {
    _hiddenIds.clear();
    _rawThreads = [];
    state = state.copyWith(
      currentSection: section,
      selectedIds: const {},
      nextPageToken: null,
      error: null,
      threads: const [],
    );
    _subscribeToSection(section.labelId);
    _syncSection(isRefresh: false);
  }

  void loadNextPage() {
    final s = state;
    if (s.isLoadingMore || s.nextPageToken == null) return;
    final labelId = s.currentSection.labelId;
    final pageToken = s.nextPageToken;
    state = state.copyWith(isLoadingMore: true);
    _async(() async {
      try {
        final token = await ref
            .read(mailRepositoryProvider)
            .syncSection(labelId, pageToken: pageToken);
        state = state.copyWith(nextPageToken: token, isLoadingMore: false);
      } catch (e) {
        state = state.copyWith(isLoadingMore: false, error: e.toString());
      }
    });
  }

  void clearError() => state = state.copyWith(error: null);

  // ── Thread actions ────────────────────────────────────────────────────────

  void hideThread(String id) {
    _hiddenIds.add(id);
    state = state.copyWith(threads: _filtered());
  }

  void unhideThread(String id) {
    _hiddenIds.remove(id);
    state = state.copyWith(threads: _filtered());
  }

  void confirmDelete(String id) {
    _async(() async {
      try {
        await ref.read(mailRepositoryProvider).trashThread(id);
      } catch (_) {
        unhideThread(id);
        state = state.copyWith(error: 'Failed to delete');
      }
    });
  }

  void confirmMove(String id, String labelId) {
    _async(() async {
      try {
        await ref.read(mailRepositoryProvider).moveThread(
          id,
          addLabels: [labelId],
          removeLabels: ['INBOX'],
        );
      } catch (_) {
        unhideThread(id);
        state = state.copyWith(error: 'Failed to move thread');
      }
    });
  }

  // ── Batch selection ───────────────────────────────────────────────────────

  void enterSelectionMode(String id) =>
      state = state.copyWith(selectedIds: {...state.selectedIds, id});

  void toggleSelection(String id) {
    final ids = state.selectedIds;
    state = state.copyWith(
      selectedIds:
          ids.contains(id) ? (Set.of(ids)..remove(id)) : {...ids, id},
    );
  }

  void exitSelectionMode() => state = state.copyWith(selectedIds: const {});

  Set<String> _hideSelectedAndClear() {
    final ids = Set<String>.of(state.selectedIds);
    _hiddenIds.addAll(ids);
    state = state.copyWith(selectedIds: const {}, threads: _filtered());
    return ids;
  }

  Set<String> startBatchDelete() => _hideSelectedAndClear();
  Set<String> startBatchMove() => _hideSelectedAndClear();
  Set<String> startBatchSpam() => _hideSelectedAndClear();

  void confirmBatchDelete(Set<String> ids) {
    final repo = ref.read(mailRepositoryProvider);
    _async(() async {
      for (final id in ids) {
        try {
          await repo.trashThread(id);
        } catch (_) {
          /* best effort */
        }
      }
    });
  }

  void confirmBatchMove(Set<String> ids, String labelId) {
    final repo = ref.read(mailRepositoryProvider);
    _async(() async {
      for (final id in ids) {
        try {
          await repo.moveThread(
              id, addLabels: [labelId], removeLabels: ['INBOX']);
        } catch (_) {
          unhideThread(id);
          state = state.copyWith(error: 'Failed to move some threads');
        }
      }
    });
  }

  void confirmBatchSpam(Set<String> ids) {
    final repo = ref.read(mailRepositoryProvider);
    _async(() async {
      for (final id in ids) {
        try {
          await repo.spamThread(id);
        } catch (_) {
          /* best effort */
        }
      }
    });
  }

  void markSelectedRead() {
    final ids = Set<String>.of(state.selectedIds);
    exitSelectionMode();
    final repo = ref.read(mailRepositoryProvider);
    _async(() async {
      for (final id in ids) {
        try {
          await repo.markRead(id);
        } catch (_) {
          /* best effort */
        }
      }
    });
  }

  void markSelectedUnread() {
    final ids = Set<String>.of(state.selectedIds);
    exitSelectionMode();
    final repo = ref.read(mailRepositoryProvider);
    _async(() async {
      for (final id in ids) {
        try {
          await repo.markUnread(id);
        } catch (_) {
          /* best effort */
        }
      }
    });
  }

  void refreshLabels() {
    _async(() async {
      try {
        await ref.read(mailRepositoryProvider).syncLabels(force: true);
      } catch (_) {}
      final labels = await ref.read(mailRepositoryProvider).getLabels();
      state = state.copyWith(availableLabels: labels);
    });
  }

  // ── Private ───────────────────────────────────────────────────────────────

  Future<void> _loadLabels() async {
    try {
      await ref.read(mailRepositoryProvider).syncLabels();
    } catch (_) {}
    final labels = await ref.read(mailRepositoryProvider).getLabels();
    state = state.copyWith(availableLabels: labels);
  }

  void _syncSection({required bool isRefresh}) {
    final labelId = state.currentSection.labelId;
    state = state.copyWith(
      isRefreshing: isRefresh,
      isLoading: !isRefresh && state.threads.isEmpty,
      error: null,
    );
    _async(() async {
      try {
        final token =
            await ref.read(mailRepositoryProvider).syncSection(labelId);
        state = state.copyWith(
          isLoading: false,
          isRefreshing: false,
          nextPageToken: token,
        );
      } catch (e) {
        state = state.copyWith(
          isLoading: false,
          isRefreshing: false,
          // Only surface errors on explicit pull-to-refresh; background sync
          // failures are silent (avoids persistent error snackbars).
          error: isRefresh ? 'Could not refresh. Check your connection.' : null,
        );
      }
    });
  }

  // Runs an async closure; errors are handled within the body.
  void _async(Future<void> Function() fn) => fn();
}
