import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'mail_database.g.dart';
part 'thread_dao.dart';
part 'message_dao.dart';
part 'label_dao.dart';

// ── Tables ────────────────────────────────────────────────────────────────────

class Threads extends Table {
  TextColumn get id => text()();
  TextColumn get snippet => text()();
  TextColumn get historyId => text()();
  TextColumn get subject => text()();
  TextColumn get fromAddress => text().named('from_address')();
  /// Comma-separated label IDs e.g. "INBOX,UNREAD"
  TextColumn get labelIds => text()();
  IntColumn get lastMessageTimestamp => integer()();
  IntColumn get messageCount => integer()();
  BoolColumn get isRead => boolean()();

  @override
  Set<Column> get primaryKey => {id};
}

class Messages extends Table {
  TextColumn get id => text()();
  TextColumn get threadId => text()();
  TextColumn get fromAddress => text().named('from_address')();
  TextColumn get toAddress => text().named('to_address')();
  TextColumn get subject => text()();
  TextColumn get snippet => text()();
  /// Decoded HTML or plain-text body. Empty until thread is opened (format=full).
  TextColumn get body => text()();
  IntColumn get date => integer()();
  /// Comma-separated label IDs
  TextColumn get labelIds => text()();
  BoolColumn get isRead => boolean()();

  @override
  Set<Column> get primaryKey => {id};
}

class Labels extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get type => text()();

  @override
  Set<Column> get primaryKey => {id};
}

// ── Database ──────────────────────────────────────────────────────────────────

@DriftDatabase(
  tables: [Threads, Messages, Labels],
  daos: [ThreadDao, MessageDao, LabelDao],
)
class MailDatabase extends _$MailDatabase {
  MailDatabase() : super(_openConnection());

  MailDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    // Dev convenience: destructive migration on schema change.
    // Replace with proper migrations before shipping.
    onUpgrade: (m, from, to) async {
      await m.recreateAllViews();
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'mail.db'));
    return NativeDatabase.createInBackground(file);
  });
}
