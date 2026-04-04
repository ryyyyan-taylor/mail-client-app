import 'package:drift/drift.dart' show Value;
import '../local/mail_database.dart';
import '../remote/gmail_api_service.dart';
import '../remote/gmail_dtos.dart';
import '../../util/email_parser.dart';

/// Mirrors MailRepository.kt — single source of truth coordinating the Gmail
/// API and the local Drift database.
class MailRepository {
  MailRepository({
    required GmailApiService api,
    required ThreadDao threadDao,
    required MessageDao messageDao,
    required LabelDao labelDao,
  })  : _api = api,
        _threadDao = threadDao,
        _messageDao = messageDao,
        _labelDao = labelDao;

  final GmailApiService _api;
  final ThreadDao _threadDao;
  final MessageDao _messageDao;
  final LabelDao _labelDao;

  // ── Observe (UI subscribes to these) ─────────────────────────────────────

  Stream<List<Thread>> observeInbox() => _threadDao.watchInbox();

  Stream<List<Thread>> observeForLabel(String labelId) =>
      _threadDao.watchForLabel('%$labelId%');

  Stream<List<Message>> observeMessages(String threadId) =>
      _messageDao.watchForThread(threadId);

  Future<List<String>> getInboxIds() => _threadDao.getInboxIds();

  Future<Thread?> getThreadById(String id) => _threadDao.getById(id);

  // ── Sync inbox from API ───────────────────────────────────────────────────

  /// Fetches threads for [labelId] (format=metadata) and caches them locally.
  /// Returns the [nextPageToken] if more pages exist.
  Future<String?> syncSection(
    String labelId, {
    String? pageToken,
  }) async {
    final response = await _api.listThreads(
      labelId: labelId,
      pageToken: pageToken,
      maxResults: 50,
    );
    final summaries = response.threads;
    if (summaries == null || summaries.isEmpty) return null;

    // Fetch metadata for each thread in parallel (same as Kotlin coroutineScope+async).
    final results = await Future.wait(
      summaries.map((s) async {
        try {
          return await _api.getThread(s.id, format: 'metadata');
        } catch (_) {
          return null;
        }
      }),
    );

    final companions = results
        .whereType<ThreadDetailDto>()
        .map(_threadDetailToCompanion)
        .toList();

    await _threadDao.upsertAll(companions);
    return response.nextPageToken;
  }

  Future<String?> syncInbox({String? pageToken}) =>
      syncSection('INBOX', pageToken: pageToken);

  // ── Load full thread ──────────────────────────────────────────────────────

  /// Fetches a thread with full message bodies and atomically replaces the
  /// local cache. Called when the user opens a thread.
  Future<void> loadFullThread(String threadId) async {
    final detail = await _api.getThread(threadId, format: 'full');
    await _threadDao.upsertAll([_threadDetailToCompanion(detail)]);

    final messageCompanions = (detail.messages ?? [])
        .map(_messageDtoToCompanion)
        .toList();
    await _messageDao.replaceForThread(threadId, messageCompanions);
  }

  // ── Thread actions ────────────────────────────────────────────────────────

  Future<void> archiveThread(String threadId) async {
    await _api.modifyThread(
        threadId, const ModifyRequest(removeLabelIds: ['INBOX']));
    await _updateLocalLabels(threadId, add: [], remove: ['INBOX']);
  }

  Future<void> trashThread(String threadId) async {
    await _api.trashThread(threadId);
    final thread = await _threadDao.getById(threadId);
    if (thread != null) await _threadDao.deleteThread(thread);
  }

  Future<void> spamThread(String threadId) async {
    await _api.modifyThread(
      threadId,
      const ModifyRequest(
        addLabelIds: ['SPAM'],
        removeLabelIds: ['INBOX'],
      ),
    );
    final thread = await _threadDao.getById(threadId);
    if (thread != null) await _threadDao.deleteThread(thread);
  }

  Future<void> markRead(String threadId) async {
    await _api.modifyThread(
        threadId, const ModifyRequest(removeLabelIds: ['UNREAD']));
    await _updateLocalLabels(threadId, add: [], remove: ['UNREAD']);
  }

  Future<void> markUnread(String threadId) async {
    await _api.modifyThread(
        threadId, const ModifyRequest(addLabelIds: ['UNREAD']));
    await _updateLocalLabels(threadId, add: ['UNREAD'], remove: []);
  }

  Future<void> moveThread(
    String threadId, {
    required List<String> addLabels,
    required List<String> removeLabels,
  }) async {
    await _api.modifyThread(
      threadId,
      ModifyRequest(addLabelIds: addLabels, removeLabelIds: removeLabels),
    );
    await _updateLocalLabels(threadId, add: addLabels, remove: removeLabels);
  }

  // ── Labels ────────────────────────────────────────────────────────────────

  static const _labelSyncThrottleMs = 60 * 60 * 1000; // 1 hour
  int _lastLabelSyncMs = 0;

  Future<void> syncLabels({bool force = false}) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (!force &&
        _lastLabelSyncMs > 0 &&
        now - _lastLabelSyncMs < _labelSyncThrottleMs) {
      return;
    }

    final response = await _api.listLabels();
    final companions = (response.labels ?? [])
        .where((dto) => dto.name != null)
        .map((dto) => LabelsCompanion(
              id: Value(dto.id),
              name: Value(dto.name!),
              type: Value(dto.type ?? ''),
            ))
        .toList();

    await _labelDao.upsertAll(companions);
    _lastLabelSyncMs = now;
  }

  Future<List<Label>> getLabels() => _labelDao.getAll();

  // ── Private helpers ───────────────────────────────────────────────────────

  Future<void> _updateLocalLabels(
    String threadId, {
    required List<String> add,
    required List<String> remove,
  }) async {
    final thread = await _threadDao.getById(threadId);
    if (thread == null) return;

    final current = thread.labelIds.isEmpty
        ? <String>{}
        : thread.labelIds.split(',').toSet();
    current.addAll(add);
    current.removeAll(remove);

    final isRead = !current.contains('UNREAD');
    await _threadDao.upsertAll([
      thread.toCompanion(true).copyWith(
            labelIds: Value(current.join(',')),
            isRead: Value(isRead),
          ),
    ]);
  }
}

// ── DTO → Drift companion mappers ─────────────────────────────────────────────

ThreadsCompanion _threadDetailToCompanion(ThreadDetailDto dto) {
  final messages = dto.messages ?? [];
  final last = messages.isNotEmpty ? messages.last : null;
  final headers = last?.payload?.headers;

  final subject =
      EmailParser.extractHeader(headers, 'Subject').let((s) => s.isEmpty ? '(no subject)' : s);
  final from = EmailParser.extractHeader(headers, 'From');
  final timestamp = last?.internalDate != null
      ? int.tryParse(last!.internalDate!) ?? 0
      : 0;

  final allLabels =
      messages.expand((m) => m.labelIds ?? <String>[]).toSet();
  final isRead = !allLabels.contains('UNREAD');

  return ThreadsCompanion(
    id: Value(dto.id),
    snippet: Value(dto.snippet ?? ''),
    historyId: Value(dto.historyId ?? ''),
    subject: Value(subject),
    fromAddress: Value(from),
    labelIds: Value(allLabels.join(',')),
    lastMessageTimestamp: Value(timestamp),
    messageCount: Value(messages.length),
    isRead: Value(isRead),
  );
}

MessagesCompanion _messageDtoToCompanion(MessageDto dto) {
  final headers = dto.payload?.headers;
  final from = EmailParser.extractHeader(headers, 'From');
  final to = EmailParser.extractHeader(headers, 'To');
  final subject = EmailParser.extractHeader(headers, 'Subject')
      .let((s) => s.isEmpty ? '(no subject)' : s);
  final date =
      dto.internalDate != null ? int.tryParse(dto.internalDate!) ?? 0 : 0;
  final labelIds = dto.labelIds?.join(',') ?? '';
  final isRead = !(dto.labelIds?.contains('UNREAD') ?? false);
  final body = EmailParser.extractBody(dto.payload);

  return MessagesCompanion(
    id: Value(dto.id),
    threadId: Value(dto.threadId ?? ''),
    fromAddress: Value(from),
    toAddress: Value(to),
    subject: Value(subject),
    snippet: Value(dto.snippet ?? ''),
    body: Value(body),
    date: Value(date),
    labelIds: Value(labelIds),
    isRead: Value(isRead),
  );
}

// Dart doesn't have Kotlin's .let{} — add a minimal inline version.
extension _LetX<T> on T {
  R let<R>(R Function(T) block) => block(this);
}
