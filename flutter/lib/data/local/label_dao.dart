part of 'mail_database.dart';

@DriftAccessor(tables: [Labels])
class LabelDao extends DatabaseAccessor<MailDatabase> with _$LabelDaoMixin {
  LabelDao(super.db);

  Future<List<Label>> getAll() => select(labels).get();

  Future<void> upsertAll(List<LabelsCompanion> rows) =>
      batch((b) => b.insertAllOnConflictUpdate(labels, rows));
}
