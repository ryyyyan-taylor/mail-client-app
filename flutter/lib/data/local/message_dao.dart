part of 'mail_database.dart';

@DriftAccessor(tables: [Messages])
class MessageDao extends DatabaseAccessor<MailDatabase> with _$MessageDaoMixin {
  MessageDao(super.db);

  /// Live stream of messages for a thread, oldest first.
  Stream<List<Message>> watchForThread(String threadId) =>
      (select(messages)
            ..where((m) => m.threadId.equals(threadId))
            ..orderBy([(m) => OrderingTerm.asc(m.date)]))
          .watch();

  Future<List<Message>> getForThread(String threadId) =>
      (select(messages)
            ..where((m) => m.threadId.equals(threadId))
            ..orderBy([(m) => OrderingTerm.asc(m.date)]))
          .get();

  Future<void> insertAll(List<MessagesCompanion> rows) =>
      batch((b) => b.insertAllOnConflictUpdate(messages, rows));

  Future<void> deleteForThread(String threadId) =>
      (delete(messages)..where((m) => m.threadId.equals(threadId))).go();

  /// Atomically replaces all messages for a thread.
  /// Wrapping in a transaction means Flow observers never see an intermediate
  /// empty state — mirrors MessageDao.replaceForThread() in Room.
  Future<void> replaceForThread(
    String threadId,
    List<MessagesCompanion> rows,
  ) =>
      transaction(() async {
        await deleteForThread(threadId);
        await insertAll(rows);
      });
}

// ── Extension helpers (mirrors MessageEntity.labelList()) ─────────────────────

extension MessageX on Message {
  List<String> get labelList =>
      labelIds.isEmpty ? [] : labelIds.split(',');
}
