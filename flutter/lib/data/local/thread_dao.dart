part of 'mail_database.dart';

@DriftAccessor(tables: [Threads])
class ThreadDao extends DatabaseAccessor<MailDatabase> with _$ThreadDaoMixin {
  ThreadDao(super.db);

  /// Live stream of inbox threads, newest first.
  Stream<List<Thread>> watchInbox() => _watchForPattern('%INBOX%');

  /// Live stream of threads matching a label pattern (SQL LIKE), newest first.
  Stream<List<Thread>> watchForLabel(String pattern) =>
      _watchForPattern(pattern);

  Stream<List<Thread>> _watchForPattern(String pattern) =>
      (select(threads)
            ..where((t) => t.labelIds.like(pattern))
            ..orderBy([
              (t) => OrderingTerm.desc(t.lastMessageTimestamp),
            ]))
          .watch();

  Future<Thread?> getById(String id) =>
      (select(threads)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<void> upsertAll(List<ThreadsCompanion> rows) =>
      batch((b) => b.insertAllOnConflictUpdate(threads, rows));

  Future<void> deleteThread(Thread thread) => delete(threads).delete(thread);

  Future<int?> getLatestTimestamp() {
    final maxExpr = threads.lastMessageTimestamp.max();
    return (selectOnly(threads)..addColumns([maxExpr]))
        .map((row) => row.read(maxExpr))
        .getSingleOrNull();
  }

  Future<List<String>> getInboxIds() async {
    final rows = await (select(threads)
          ..where((t) => t.labelIds.like('%INBOX%'))
          ..orderBy([(t) => OrderingTerm.desc(t.lastMessageTimestamp)]))
        .get();
    return rows.map((r) => r.id).toList();
  }
}

// ── Extension helpers (mirrors ThreadEntity.labelList()) ──────────────────────

extension ThreadX on Thread {
  List<String> get labelList =>
      labelIds.isEmpty ? [] : labelIds.split(',');
}
