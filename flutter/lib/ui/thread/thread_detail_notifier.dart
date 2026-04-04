import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/local/mail_database.dart';
import '../../providers/providers.dart';

// ── State ─────────────────────────────────────────────────────────────────────

class ThreadDetailUiState {
  const ThreadDetailUiState({
    this.subject = '',
    this.messages = const [],
    this.isLoading = true,
    this.error,
    this.isRead = true,
    this.availableLabels = const [],
    this.navigateBack = false,
  });

  final String subject;
  final List<Message> messages;
  final bool isLoading;
  final String? error;
  final bool isRead;
  final List<Label> availableLabels;
  final bool navigateBack;

  ThreadDetailUiState copyWith({
    String? subject,
    List<Message>? messages,
    bool? isLoading,
    Object? error = _sentinel,
    bool? isRead,
    List<Label>? availableLabels,
    bool? navigateBack,
  }) {
    return ThreadDetailUiState(
      subject: subject ?? this.subject,
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: identical(error, _sentinel) ? this.error : error as String?,
      isRead: isRead ?? this.isRead,
      availableLabels: availableLabels ?? this.availableLabels,
      navigateBack: navigateBack ?? this.navigateBack,
    );
  }
}

const _sentinel = Object();

// ── Notifier ──────────────────────────────────────────────────────────────────

class ThreadDetailNotifier
    extends FamilyNotifier<ThreadDetailUiState, String> {
  late String _threadId;
  StreamSubscription<List<Message>>? _sub;

  @override
  ThreadDetailUiState build(String arg) {
    _threadId = arg;
    ref.onDispose(() => _sub?.cancel());

    _sub = ref
        .read(mailRepositoryProvider)
        .observeMessages(_threadId)
        .listen((msgs) {
      state = state.copyWith(
        messages: msgs,
        subject: msgs.isNotEmpty ? msgs.first.subject : state.subject,
      );
    });

    Future.microtask(() => _load());
    Future.microtask(() => _loadLabels());
    return const ThreadDetailUiState();
  }

  void clearError() => state = state.copyWith(error: null);

  // ── Actions ───────────────────────────────────────────────────────────────

  void delete() {
    _async(() async {
      try {
        await ref.read(mailRepositoryProvider).trashThread(_threadId);
        state = state.copyWith(navigateBack: true);
      } catch (_) {
        state = state.copyWith(error: 'Failed to delete');
      }
    });
  }

  void spam() {
    _async(() async {
      try {
        await ref.read(mailRepositoryProvider).spamThread(_threadId);
        state = state.copyWith(navigateBack: true);
      } catch (_) {
        state = state.copyWith(error: 'Failed to mark as spam');
      }
    });
  }

  void moveToLabel(String labelId) {
    _async(() async {
      try {
        await ref.read(mailRepositoryProvider).moveThread(
          _threadId,
          addLabels: [labelId],
          removeLabels: ['INBOX'],
        );
        state = state.copyWith(navigateBack: true);
      } catch (_) {
        state = state.copyWith(error: 'Failed to move thread');
      }
    });
  }

  void toggleRead() {
    final wasRead = state.isRead;
    state = state.copyWith(isRead: !wasRead);
    _async(() async {
      try {
        if (wasRead) {
          await ref.read(mailRepositoryProvider).markUnread(_threadId);
        } else {
          await ref.read(mailRepositoryProvider).markRead(_threadId);
        }
      } catch (_) {
        state = state.copyWith(
            isRead: wasRead, error: 'Failed to update read state');
      }
    });
  }

  // ── Private ───────────────────────────────────────────────────────────────

  Future<void> _load() async {
    try {
      final repo = ref.read(mailRepositoryProvider);
      // loadFullThread and markRead are independent — run in parallel.
      // markRead is best-effort: its failure must not prevent messages rendering.
      await Future.wait([
        repo.loadFullThread(_threadId),
        repo.markRead(_threadId).catchError((_) {}),
      ]);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> _loadLabels() async {
    try {
      await ref.read(mailRepositoryProvider).syncLabels();
    } catch (_) {}
    final labels = await ref.read(mailRepositoryProvider).getLabels();
    state = state.copyWith(availableLabels: labels);
  }

  void _async(Future<void> Function() fn) => fn();
}
