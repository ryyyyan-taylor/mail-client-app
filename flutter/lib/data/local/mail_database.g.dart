// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mail_database.dart';

// ignore_for_file: type=lint
class $ThreadsTable extends Threads with TableInfo<$ThreadsTable, Thread> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ThreadsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _snippetMeta = const VerificationMeta(
    'snippet',
  );
  @override
  late final GeneratedColumn<String> snippet = GeneratedColumn<String>(
    'snippet',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _historyIdMeta = const VerificationMeta(
    'historyId',
  );
  @override
  late final GeneratedColumn<String> historyId = GeneratedColumn<String>(
    'history_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _subjectMeta = const VerificationMeta(
    'subject',
  );
  @override
  late final GeneratedColumn<String> subject = GeneratedColumn<String>(
    'subject',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fromAddressMeta = const VerificationMeta(
    'fromAddress',
  );
  @override
  late final GeneratedColumn<String> fromAddress = GeneratedColumn<String>(
    'from_address',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _labelIdsMeta = const VerificationMeta(
    'labelIds',
  );
  @override
  late final GeneratedColumn<String> labelIds = GeneratedColumn<String>(
    'label_ids',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastMessageTimestampMeta =
      const VerificationMeta('lastMessageTimestamp');
  @override
  late final GeneratedColumn<int> lastMessageTimestamp = GeneratedColumn<int>(
    'last_message_timestamp',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _messageCountMeta = const VerificationMeta(
    'messageCount',
  );
  @override
  late final GeneratedColumn<int> messageCount = GeneratedColumn<int>(
    'message_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isReadMeta = const VerificationMeta('isRead');
  @override
  late final GeneratedColumn<bool> isRead = GeneratedColumn<bool>(
    'is_read',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_read" IN (0, 1))',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    snippet,
    historyId,
    subject,
    fromAddress,
    labelIds,
    lastMessageTimestamp,
    messageCount,
    isRead,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'threads';
  @override
  VerificationContext validateIntegrity(
    Insertable<Thread> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('snippet')) {
      context.handle(
        _snippetMeta,
        snippet.isAcceptableOrUnknown(data['snippet']!, _snippetMeta),
      );
    } else if (isInserting) {
      context.missing(_snippetMeta);
    }
    if (data.containsKey('history_id')) {
      context.handle(
        _historyIdMeta,
        historyId.isAcceptableOrUnknown(data['history_id']!, _historyIdMeta),
      );
    } else if (isInserting) {
      context.missing(_historyIdMeta);
    }
    if (data.containsKey('subject')) {
      context.handle(
        _subjectMeta,
        subject.isAcceptableOrUnknown(data['subject']!, _subjectMeta),
      );
    } else if (isInserting) {
      context.missing(_subjectMeta);
    }
    if (data.containsKey('from_address')) {
      context.handle(
        _fromAddressMeta,
        fromAddress.isAcceptableOrUnknown(
          data['from_address']!,
          _fromAddressMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_fromAddressMeta);
    }
    if (data.containsKey('label_ids')) {
      context.handle(
        _labelIdsMeta,
        labelIds.isAcceptableOrUnknown(data['label_ids']!, _labelIdsMeta),
      );
    } else if (isInserting) {
      context.missing(_labelIdsMeta);
    }
    if (data.containsKey('last_message_timestamp')) {
      context.handle(
        _lastMessageTimestampMeta,
        lastMessageTimestamp.isAcceptableOrUnknown(
          data['last_message_timestamp']!,
          _lastMessageTimestampMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastMessageTimestampMeta);
    }
    if (data.containsKey('message_count')) {
      context.handle(
        _messageCountMeta,
        messageCount.isAcceptableOrUnknown(
          data['message_count']!,
          _messageCountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_messageCountMeta);
    }
    if (data.containsKey('is_read')) {
      context.handle(
        _isReadMeta,
        isRead.isAcceptableOrUnknown(data['is_read']!, _isReadMeta),
      );
    } else if (isInserting) {
      context.missing(_isReadMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Thread map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Thread(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      snippet: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}snippet'],
      )!,
      historyId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}history_id'],
      )!,
      subject: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subject'],
      )!,
      fromAddress: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}from_address'],
      )!,
      labelIds: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label_ids'],
      )!,
      lastMessageTimestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_message_timestamp'],
      )!,
      messageCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}message_count'],
      )!,
      isRead: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_read'],
      )!,
    );
  }

  @override
  $ThreadsTable createAlias(String alias) {
    return $ThreadsTable(attachedDatabase, alias);
  }
}

class Thread extends DataClass implements Insertable<Thread> {
  final String id;
  final String snippet;
  final String historyId;
  final String subject;
  final String fromAddress;

  /// Comma-separated label IDs e.g. "INBOX,UNREAD"
  final String labelIds;
  final int lastMessageTimestamp;
  final int messageCount;
  final bool isRead;
  const Thread({
    required this.id,
    required this.snippet,
    required this.historyId,
    required this.subject,
    required this.fromAddress,
    required this.labelIds,
    required this.lastMessageTimestamp,
    required this.messageCount,
    required this.isRead,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['snippet'] = Variable<String>(snippet);
    map['history_id'] = Variable<String>(historyId);
    map['subject'] = Variable<String>(subject);
    map['from_address'] = Variable<String>(fromAddress);
    map['label_ids'] = Variable<String>(labelIds);
    map['last_message_timestamp'] = Variable<int>(lastMessageTimestamp);
    map['message_count'] = Variable<int>(messageCount);
    map['is_read'] = Variable<bool>(isRead);
    return map;
  }

  ThreadsCompanion toCompanion(bool nullToAbsent) {
    return ThreadsCompanion(
      id: Value(id),
      snippet: Value(snippet),
      historyId: Value(historyId),
      subject: Value(subject),
      fromAddress: Value(fromAddress),
      labelIds: Value(labelIds),
      lastMessageTimestamp: Value(lastMessageTimestamp),
      messageCount: Value(messageCount),
      isRead: Value(isRead),
    );
  }

  factory Thread.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Thread(
      id: serializer.fromJson<String>(json['id']),
      snippet: serializer.fromJson<String>(json['snippet']),
      historyId: serializer.fromJson<String>(json['historyId']),
      subject: serializer.fromJson<String>(json['subject']),
      fromAddress: serializer.fromJson<String>(json['fromAddress']),
      labelIds: serializer.fromJson<String>(json['labelIds']),
      lastMessageTimestamp: serializer.fromJson<int>(
        json['lastMessageTimestamp'],
      ),
      messageCount: serializer.fromJson<int>(json['messageCount']),
      isRead: serializer.fromJson<bool>(json['isRead']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'snippet': serializer.toJson<String>(snippet),
      'historyId': serializer.toJson<String>(historyId),
      'subject': serializer.toJson<String>(subject),
      'fromAddress': serializer.toJson<String>(fromAddress),
      'labelIds': serializer.toJson<String>(labelIds),
      'lastMessageTimestamp': serializer.toJson<int>(lastMessageTimestamp),
      'messageCount': serializer.toJson<int>(messageCount),
      'isRead': serializer.toJson<bool>(isRead),
    };
  }

  Thread copyWith({
    String? id,
    String? snippet,
    String? historyId,
    String? subject,
    String? fromAddress,
    String? labelIds,
    int? lastMessageTimestamp,
    int? messageCount,
    bool? isRead,
  }) => Thread(
    id: id ?? this.id,
    snippet: snippet ?? this.snippet,
    historyId: historyId ?? this.historyId,
    subject: subject ?? this.subject,
    fromAddress: fromAddress ?? this.fromAddress,
    labelIds: labelIds ?? this.labelIds,
    lastMessageTimestamp: lastMessageTimestamp ?? this.lastMessageTimestamp,
    messageCount: messageCount ?? this.messageCount,
    isRead: isRead ?? this.isRead,
  );
  Thread copyWithCompanion(ThreadsCompanion data) {
    return Thread(
      id: data.id.present ? data.id.value : this.id,
      snippet: data.snippet.present ? data.snippet.value : this.snippet,
      historyId: data.historyId.present ? data.historyId.value : this.historyId,
      subject: data.subject.present ? data.subject.value : this.subject,
      fromAddress: data.fromAddress.present
          ? data.fromAddress.value
          : this.fromAddress,
      labelIds: data.labelIds.present ? data.labelIds.value : this.labelIds,
      lastMessageTimestamp: data.lastMessageTimestamp.present
          ? data.lastMessageTimestamp.value
          : this.lastMessageTimestamp,
      messageCount: data.messageCount.present
          ? data.messageCount.value
          : this.messageCount,
      isRead: data.isRead.present ? data.isRead.value : this.isRead,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Thread(')
          ..write('id: $id, ')
          ..write('snippet: $snippet, ')
          ..write('historyId: $historyId, ')
          ..write('subject: $subject, ')
          ..write('fromAddress: $fromAddress, ')
          ..write('labelIds: $labelIds, ')
          ..write('lastMessageTimestamp: $lastMessageTimestamp, ')
          ..write('messageCount: $messageCount, ')
          ..write('isRead: $isRead')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    snippet,
    historyId,
    subject,
    fromAddress,
    labelIds,
    lastMessageTimestamp,
    messageCount,
    isRead,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Thread &&
          other.id == this.id &&
          other.snippet == this.snippet &&
          other.historyId == this.historyId &&
          other.subject == this.subject &&
          other.fromAddress == this.fromAddress &&
          other.labelIds == this.labelIds &&
          other.lastMessageTimestamp == this.lastMessageTimestamp &&
          other.messageCount == this.messageCount &&
          other.isRead == this.isRead);
}

class ThreadsCompanion extends UpdateCompanion<Thread> {
  final Value<String> id;
  final Value<String> snippet;
  final Value<String> historyId;
  final Value<String> subject;
  final Value<String> fromAddress;
  final Value<String> labelIds;
  final Value<int> lastMessageTimestamp;
  final Value<int> messageCount;
  final Value<bool> isRead;
  final Value<int> rowid;
  const ThreadsCompanion({
    this.id = const Value.absent(),
    this.snippet = const Value.absent(),
    this.historyId = const Value.absent(),
    this.subject = const Value.absent(),
    this.fromAddress = const Value.absent(),
    this.labelIds = const Value.absent(),
    this.lastMessageTimestamp = const Value.absent(),
    this.messageCount = const Value.absent(),
    this.isRead = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ThreadsCompanion.insert({
    required String id,
    required String snippet,
    required String historyId,
    required String subject,
    required String fromAddress,
    required String labelIds,
    required int lastMessageTimestamp,
    required int messageCount,
    required bool isRead,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       snippet = Value(snippet),
       historyId = Value(historyId),
       subject = Value(subject),
       fromAddress = Value(fromAddress),
       labelIds = Value(labelIds),
       lastMessageTimestamp = Value(lastMessageTimestamp),
       messageCount = Value(messageCount),
       isRead = Value(isRead);
  static Insertable<Thread> custom({
    Expression<String>? id,
    Expression<String>? snippet,
    Expression<String>? historyId,
    Expression<String>? subject,
    Expression<String>? fromAddress,
    Expression<String>? labelIds,
    Expression<int>? lastMessageTimestamp,
    Expression<int>? messageCount,
    Expression<bool>? isRead,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (snippet != null) 'snippet': snippet,
      if (historyId != null) 'history_id': historyId,
      if (subject != null) 'subject': subject,
      if (fromAddress != null) 'from_address': fromAddress,
      if (labelIds != null) 'label_ids': labelIds,
      if (lastMessageTimestamp != null)
        'last_message_timestamp': lastMessageTimestamp,
      if (messageCount != null) 'message_count': messageCount,
      if (isRead != null) 'is_read': isRead,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ThreadsCompanion copyWith({
    Value<String>? id,
    Value<String>? snippet,
    Value<String>? historyId,
    Value<String>? subject,
    Value<String>? fromAddress,
    Value<String>? labelIds,
    Value<int>? lastMessageTimestamp,
    Value<int>? messageCount,
    Value<bool>? isRead,
    Value<int>? rowid,
  }) {
    return ThreadsCompanion(
      id: id ?? this.id,
      snippet: snippet ?? this.snippet,
      historyId: historyId ?? this.historyId,
      subject: subject ?? this.subject,
      fromAddress: fromAddress ?? this.fromAddress,
      labelIds: labelIds ?? this.labelIds,
      lastMessageTimestamp: lastMessageTimestamp ?? this.lastMessageTimestamp,
      messageCount: messageCount ?? this.messageCount,
      isRead: isRead ?? this.isRead,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (snippet.present) {
      map['snippet'] = Variable<String>(snippet.value);
    }
    if (historyId.present) {
      map['history_id'] = Variable<String>(historyId.value);
    }
    if (subject.present) {
      map['subject'] = Variable<String>(subject.value);
    }
    if (fromAddress.present) {
      map['from_address'] = Variable<String>(fromAddress.value);
    }
    if (labelIds.present) {
      map['label_ids'] = Variable<String>(labelIds.value);
    }
    if (lastMessageTimestamp.present) {
      map['last_message_timestamp'] = Variable<int>(lastMessageTimestamp.value);
    }
    if (messageCount.present) {
      map['message_count'] = Variable<int>(messageCount.value);
    }
    if (isRead.present) {
      map['is_read'] = Variable<bool>(isRead.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ThreadsCompanion(')
          ..write('id: $id, ')
          ..write('snippet: $snippet, ')
          ..write('historyId: $historyId, ')
          ..write('subject: $subject, ')
          ..write('fromAddress: $fromAddress, ')
          ..write('labelIds: $labelIds, ')
          ..write('lastMessageTimestamp: $lastMessageTimestamp, ')
          ..write('messageCount: $messageCount, ')
          ..write('isRead: $isRead, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MessagesTable extends Messages with TableInfo<$MessagesTable, Message> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MessagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _threadIdMeta = const VerificationMeta(
    'threadId',
  );
  @override
  late final GeneratedColumn<String> threadId = GeneratedColumn<String>(
    'thread_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fromAddressMeta = const VerificationMeta(
    'fromAddress',
  );
  @override
  late final GeneratedColumn<String> fromAddress = GeneratedColumn<String>(
    'from_address',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _toAddressMeta = const VerificationMeta(
    'toAddress',
  );
  @override
  late final GeneratedColumn<String> toAddress = GeneratedColumn<String>(
    'to_address',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _subjectMeta = const VerificationMeta(
    'subject',
  );
  @override
  late final GeneratedColumn<String> subject = GeneratedColumn<String>(
    'subject',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _snippetMeta = const VerificationMeta(
    'snippet',
  );
  @override
  late final GeneratedColumn<String> snippet = GeneratedColumn<String>(
    'snippet',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<int> date = GeneratedColumn<int>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _labelIdsMeta = const VerificationMeta(
    'labelIds',
  );
  @override
  late final GeneratedColumn<String> labelIds = GeneratedColumn<String>(
    'label_ids',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isReadMeta = const VerificationMeta('isRead');
  @override
  late final GeneratedColumn<bool> isRead = GeneratedColumn<bool>(
    'is_read',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_read" IN (0, 1))',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    threadId,
    fromAddress,
    toAddress,
    subject,
    snippet,
    body,
    date,
    labelIds,
    isRead,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'messages';
  @override
  VerificationContext validateIntegrity(
    Insertable<Message> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('thread_id')) {
      context.handle(
        _threadIdMeta,
        threadId.isAcceptableOrUnknown(data['thread_id']!, _threadIdMeta),
      );
    } else if (isInserting) {
      context.missing(_threadIdMeta);
    }
    if (data.containsKey('from_address')) {
      context.handle(
        _fromAddressMeta,
        fromAddress.isAcceptableOrUnknown(
          data['from_address']!,
          _fromAddressMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_fromAddressMeta);
    }
    if (data.containsKey('to_address')) {
      context.handle(
        _toAddressMeta,
        toAddress.isAcceptableOrUnknown(data['to_address']!, _toAddressMeta),
      );
    } else if (isInserting) {
      context.missing(_toAddressMeta);
    }
    if (data.containsKey('subject')) {
      context.handle(
        _subjectMeta,
        subject.isAcceptableOrUnknown(data['subject']!, _subjectMeta),
      );
    } else if (isInserting) {
      context.missing(_subjectMeta);
    }
    if (data.containsKey('snippet')) {
      context.handle(
        _snippetMeta,
        snippet.isAcceptableOrUnknown(data['snippet']!, _snippetMeta),
      );
    } else if (isInserting) {
      context.missing(_snippetMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('label_ids')) {
      context.handle(
        _labelIdsMeta,
        labelIds.isAcceptableOrUnknown(data['label_ids']!, _labelIdsMeta),
      );
    } else if (isInserting) {
      context.missing(_labelIdsMeta);
    }
    if (data.containsKey('is_read')) {
      context.handle(
        _isReadMeta,
        isRead.isAcceptableOrUnknown(data['is_read']!, _isReadMeta),
      );
    } else if (isInserting) {
      context.missing(_isReadMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Message map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Message(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      threadId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}thread_id'],
      )!,
      fromAddress: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}from_address'],
      )!,
      toAddress: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}to_address'],
      )!,
      subject: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subject'],
      )!,
      snippet: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}snippet'],
      )!,
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}date'],
      )!,
      labelIds: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label_ids'],
      )!,
      isRead: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_read'],
      )!,
    );
  }

  @override
  $MessagesTable createAlias(String alias) {
    return $MessagesTable(attachedDatabase, alias);
  }
}

class Message extends DataClass implements Insertable<Message> {
  final String id;
  final String threadId;
  final String fromAddress;
  final String toAddress;
  final String subject;
  final String snippet;

  /// Decoded HTML or plain-text body. Empty until thread is opened (format=full).
  final String body;
  final int date;

  /// Comma-separated label IDs
  final String labelIds;
  final bool isRead;
  const Message({
    required this.id,
    required this.threadId,
    required this.fromAddress,
    required this.toAddress,
    required this.subject,
    required this.snippet,
    required this.body,
    required this.date,
    required this.labelIds,
    required this.isRead,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['thread_id'] = Variable<String>(threadId);
    map['from_address'] = Variable<String>(fromAddress);
    map['to_address'] = Variable<String>(toAddress);
    map['subject'] = Variable<String>(subject);
    map['snippet'] = Variable<String>(snippet);
    map['body'] = Variable<String>(body);
    map['date'] = Variable<int>(date);
    map['label_ids'] = Variable<String>(labelIds);
    map['is_read'] = Variable<bool>(isRead);
    return map;
  }

  MessagesCompanion toCompanion(bool nullToAbsent) {
    return MessagesCompanion(
      id: Value(id),
      threadId: Value(threadId),
      fromAddress: Value(fromAddress),
      toAddress: Value(toAddress),
      subject: Value(subject),
      snippet: Value(snippet),
      body: Value(body),
      date: Value(date),
      labelIds: Value(labelIds),
      isRead: Value(isRead),
    );
  }

  factory Message.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Message(
      id: serializer.fromJson<String>(json['id']),
      threadId: serializer.fromJson<String>(json['threadId']),
      fromAddress: serializer.fromJson<String>(json['fromAddress']),
      toAddress: serializer.fromJson<String>(json['toAddress']),
      subject: serializer.fromJson<String>(json['subject']),
      snippet: serializer.fromJson<String>(json['snippet']),
      body: serializer.fromJson<String>(json['body']),
      date: serializer.fromJson<int>(json['date']),
      labelIds: serializer.fromJson<String>(json['labelIds']),
      isRead: serializer.fromJson<bool>(json['isRead']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'threadId': serializer.toJson<String>(threadId),
      'fromAddress': serializer.toJson<String>(fromAddress),
      'toAddress': serializer.toJson<String>(toAddress),
      'subject': serializer.toJson<String>(subject),
      'snippet': serializer.toJson<String>(snippet),
      'body': serializer.toJson<String>(body),
      'date': serializer.toJson<int>(date),
      'labelIds': serializer.toJson<String>(labelIds),
      'isRead': serializer.toJson<bool>(isRead),
    };
  }

  Message copyWith({
    String? id,
    String? threadId,
    String? fromAddress,
    String? toAddress,
    String? subject,
    String? snippet,
    String? body,
    int? date,
    String? labelIds,
    bool? isRead,
  }) => Message(
    id: id ?? this.id,
    threadId: threadId ?? this.threadId,
    fromAddress: fromAddress ?? this.fromAddress,
    toAddress: toAddress ?? this.toAddress,
    subject: subject ?? this.subject,
    snippet: snippet ?? this.snippet,
    body: body ?? this.body,
    date: date ?? this.date,
    labelIds: labelIds ?? this.labelIds,
    isRead: isRead ?? this.isRead,
  );
  Message copyWithCompanion(MessagesCompanion data) {
    return Message(
      id: data.id.present ? data.id.value : this.id,
      threadId: data.threadId.present ? data.threadId.value : this.threadId,
      fromAddress: data.fromAddress.present
          ? data.fromAddress.value
          : this.fromAddress,
      toAddress: data.toAddress.present ? data.toAddress.value : this.toAddress,
      subject: data.subject.present ? data.subject.value : this.subject,
      snippet: data.snippet.present ? data.snippet.value : this.snippet,
      body: data.body.present ? data.body.value : this.body,
      date: data.date.present ? data.date.value : this.date,
      labelIds: data.labelIds.present ? data.labelIds.value : this.labelIds,
      isRead: data.isRead.present ? data.isRead.value : this.isRead,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Message(')
          ..write('id: $id, ')
          ..write('threadId: $threadId, ')
          ..write('fromAddress: $fromAddress, ')
          ..write('toAddress: $toAddress, ')
          ..write('subject: $subject, ')
          ..write('snippet: $snippet, ')
          ..write('body: $body, ')
          ..write('date: $date, ')
          ..write('labelIds: $labelIds, ')
          ..write('isRead: $isRead')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    threadId,
    fromAddress,
    toAddress,
    subject,
    snippet,
    body,
    date,
    labelIds,
    isRead,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Message &&
          other.id == this.id &&
          other.threadId == this.threadId &&
          other.fromAddress == this.fromAddress &&
          other.toAddress == this.toAddress &&
          other.subject == this.subject &&
          other.snippet == this.snippet &&
          other.body == this.body &&
          other.date == this.date &&
          other.labelIds == this.labelIds &&
          other.isRead == this.isRead);
}

class MessagesCompanion extends UpdateCompanion<Message> {
  final Value<String> id;
  final Value<String> threadId;
  final Value<String> fromAddress;
  final Value<String> toAddress;
  final Value<String> subject;
  final Value<String> snippet;
  final Value<String> body;
  final Value<int> date;
  final Value<String> labelIds;
  final Value<bool> isRead;
  final Value<int> rowid;
  const MessagesCompanion({
    this.id = const Value.absent(),
    this.threadId = const Value.absent(),
    this.fromAddress = const Value.absent(),
    this.toAddress = const Value.absent(),
    this.subject = const Value.absent(),
    this.snippet = const Value.absent(),
    this.body = const Value.absent(),
    this.date = const Value.absent(),
    this.labelIds = const Value.absent(),
    this.isRead = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MessagesCompanion.insert({
    required String id,
    required String threadId,
    required String fromAddress,
    required String toAddress,
    required String subject,
    required String snippet,
    required String body,
    required int date,
    required String labelIds,
    required bool isRead,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       threadId = Value(threadId),
       fromAddress = Value(fromAddress),
       toAddress = Value(toAddress),
       subject = Value(subject),
       snippet = Value(snippet),
       body = Value(body),
       date = Value(date),
       labelIds = Value(labelIds),
       isRead = Value(isRead);
  static Insertable<Message> custom({
    Expression<String>? id,
    Expression<String>? threadId,
    Expression<String>? fromAddress,
    Expression<String>? toAddress,
    Expression<String>? subject,
    Expression<String>? snippet,
    Expression<String>? body,
    Expression<int>? date,
    Expression<String>? labelIds,
    Expression<bool>? isRead,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (threadId != null) 'thread_id': threadId,
      if (fromAddress != null) 'from_address': fromAddress,
      if (toAddress != null) 'to_address': toAddress,
      if (subject != null) 'subject': subject,
      if (snippet != null) 'snippet': snippet,
      if (body != null) 'body': body,
      if (date != null) 'date': date,
      if (labelIds != null) 'label_ids': labelIds,
      if (isRead != null) 'is_read': isRead,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MessagesCompanion copyWith({
    Value<String>? id,
    Value<String>? threadId,
    Value<String>? fromAddress,
    Value<String>? toAddress,
    Value<String>? subject,
    Value<String>? snippet,
    Value<String>? body,
    Value<int>? date,
    Value<String>? labelIds,
    Value<bool>? isRead,
    Value<int>? rowid,
  }) {
    return MessagesCompanion(
      id: id ?? this.id,
      threadId: threadId ?? this.threadId,
      fromAddress: fromAddress ?? this.fromAddress,
      toAddress: toAddress ?? this.toAddress,
      subject: subject ?? this.subject,
      snippet: snippet ?? this.snippet,
      body: body ?? this.body,
      date: date ?? this.date,
      labelIds: labelIds ?? this.labelIds,
      isRead: isRead ?? this.isRead,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (threadId.present) {
      map['thread_id'] = Variable<String>(threadId.value);
    }
    if (fromAddress.present) {
      map['from_address'] = Variable<String>(fromAddress.value);
    }
    if (toAddress.present) {
      map['to_address'] = Variable<String>(toAddress.value);
    }
    if (subject.present) {
      map['subject'] = Variable<String>(subject.value);
    }
    if (snippet.present) {
      map['snippet'] = Variable<String>(snippet.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (date.present) {
      map['date'] = Variable<int>(date.value);
    }
    if (labelIds.present) {
      map['label_ids'] = Variable<String>(labelIds.value);
    }
    if (isRead.present) {
      map['is_read'] = Variable<bool>(isRead.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MessagesCompanion(')
          ..write('id: $id, ')
          ..write('threadId: $threadId, ')
          ..write('fromAddress: $fromAddress, ')
          ..write('toAddress: $toAddress, ')
          ..write('subject: $subject, ')
          ..write('snippet: $snippet, ')
          ..write('body: $body, ')
          ..write('date: $date, ')
          ..write('labelIds: $labelIds, ')
          ..write('isRead: $isRead, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LabelsTable extends Labels with TableInfo<$LabelsTable, Label> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LabelsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, type];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'labels';
  @override
  VerificationContext validateIntegrity(
    Insertable<Label> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Label map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Label(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
    );
  }

  @override
  $LabelsTable createAlias(String alias) {
    return $LabelsTable(attachedDatabase, alias);
  }
}

class Label extends DataClass implements Insertable<Label> {
  final String id;
  final String name;
  final String type;
  const Label({required this.id, required this.name, required this.type});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['type'] = Variable<String>(type);
    return map;
  }

  LabelsCompanion toCompanion(bool nullToAbsent) {
    return LabelsCompanion(id: Value(id), name: Value(name), type: Value(type));
  }

  factory Label.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Label(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      type: serializer.fromJson<String>(json['type']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'type': serializer.toJson<String>(type),
    };
  }

  Label copyWith({String? id, String? name, String? type}) => Label(
    id: id ?? this.id,
    name: name ?? this.name,
    type: type ?? this.type,
  );
  Label copyWithCompanion(LabelsCompanion data) {
    return Label(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Label(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, type);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Label &&
          other.id == this.id &&
          other.name == this.name &&
          other.type == this.type);
}

class LabelsCompanion extends UpdateCompanion<Label> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> type;
  final Value<int> rowid;
  const LabelsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LabelsCompanion.insert({
    required String id,
    required String name,
    required String type,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       type = Value(type);
  static Insertable<Label> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? type,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LabelsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? type,
    Value<int>? rowid,
  }) {
    return LabelsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LabelsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$MailDatabase extends GeneratedDatabase {
  _$MailDatabase(QueryExecutor e) : super(e);
  $MailDatabaseManager get managers => $MailDatabaseManager(this);
  late final $ThreadsTable threads = $ThreadsTable(this);
  late final $MessagesTable messages = $MessagesTable(this);
  late final $LabelsTable labels = $LabelsTable(this);
  late final ThreadDao threadDao = ThreadDao(this as MailDatabase);
  late final MessageDao messageDao = MessageDao(this as MailDatabase);
  late final LabelDao labelDao = LabelDao(this as MailDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    threads,
    messages,
    labels,
  ];
}

typedef $$ThreadsTableCreateCompanionBuilder =
    ThreadsCompanion Function({
      required String id,
      required String snippet,
      required String historyId,
      required String subject,
      required String fromAddress,
      required String labelIds,
      required int lastMessageTimestamp,
      required int messageCount,
      required bool isRead,
      Value<int> rowid,
    });
typedef $$ThreadsTableUpdateCompanionBuilder =
    ThreadsCompanion Function({
      Value<String> id,
      Value<String> snippet,
      Value<String> historyId,
      Value<String> subject,
      Value<String> fromAddress,
      Value<String> labelIds,
      Value<int> lastMessageTimestamp,
      Value<int> messageCount,
      Value<bool> isRead,
      Value<int> rowid,
    });

class $$ThreadsTableFilterComposer
    extends Composer<_$MailDatabase, $ThreadsTable> {
  $$ThreadsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get snippet => $composableBuilder(
    column: $table.snippet,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get historyId => $composableBuilder(
    column: $table.historyId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subject => $composableBuilder(
    column: $table.subject,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fromAddress => $composableBuilder(
    column: $table.fromAddress,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get labelIds => $composableBuilder(
    column: $table.labelIds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastMessageTimestamp => $composableBuilder(
    column: $table.lastMessageTimestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get messageCount => $composableBuilder(
    column: $table.messageCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isRead => $composableBuilder(
    column: $table.isRead,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ThreadsTableOrderingComposer
    extends Composer<_$MailDatabase, $ThreadsTable> {
  $$ThreadsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get snippet => $composableBuilder(
    column: $table.snippet,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get historyId => $composableBuilder(
    column: $table.historyId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subject => $composableBuilder(
    column: $table.subject,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fromAddress => $composableBuilder(
    column: $table.fromAddress,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get labelIds => $composableBuilder(
    column: $table.labelIds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastMessageTimestamp => $composableBuilder(
    column: $table.lastMessageTimestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get messageCount => $composableBuilder(
    column: $table.messageCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isRead => $composableBuilder(
    column: $table.isRead,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ThreadsTableAnnotationComposer
    extends Composer<_$MailDatabase, $ThreadsTable> {
  $$ThreadsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get snippet =>
      $composableBuilder(column: $table.snippet, builder: (column) => column);

  GeneratedColumn<String> get historyId =>
      $composableBuilder(column: $table.historyId, builder: (column) => column);

  GeneratedColumn<String> get subject =>
      $composableBuilder(column: $table.subject, builder: (column) => column);

  GeneratedColumn<String> get fromAddress => $composableBuilder(
    column: $table.fromAddress,
    builder: (column) => column,
  );

  GeneratedColumn<String> get labelIds =>
      $composableBuilder(column: $table.labelIds, builder: (column) => column);

  GeneratedColumn<int> get lastMessageTimestamp => $composableBuilder(
    column: $table.lastMessageTimestamp,
    builder: (column) => column,
  );

  GeneratedColumn<int> get messageCount => $composableBuilder(
    column: $table.messageCount,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isRead =>
      $composableBuilder(column: $table.isRead, builder: (column) => column);
}

class $$ThreadsTableTableManager
    extends
        RootTableManager<
          _$MailDatabase,
          $ThreadsTable,
          Thread,
          $$ThreadsTableFilterComposer,
          $$ThreadsTableOrderingComposer,
          $$ThreadsTableAnnotationComposer,
          $$ThreadsTableCreateCompanionBuilder,
          $$ThreadsTableUpdateCompanionBuilder,
          (Thread, BaseReferences<_$MailDatabase, $ThreadsTable, Thread>),
          Thread,
          PrefetchHooks Function()
        > {
  $$ThreadsTableTableManager(_$MailDatabase db, $ThreadsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ThreadsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ThreadsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ThreadsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> snippet = const Value.absent(),
                Value<String> historyId = const Value.absent(),
                Value<String> subject = const Value.absent(),
                Value<String> fromAddress = const Value.absent(),
                Value<String> labelIds = const Value.absent(),
                Value<int> lastMessageTimestamp = const Value.absent(),
                Value<int> messageCount = const Value.absent(),
                Value<bool> isRead = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ThreadsCompanion(
                id: id,
                snippet: snippet,
                historyId: historyId,
                subject: subject,
                fromAddress: fromAddress,
                labelIds: labelIds,
                lastMessageTimestamp: lastMessageTimestamp,
                messageCount: messageCount,
                isRead: isRead,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String snippet,
                required String historyId,
                required String subject,
                required String fromAddress,
                required String labelIds,
                required int lastMessageTimestamp,
                required int messageCount,
                required bool isRead,
                Value<int> rowid = const Value.absent(),
              }) => ThreadsCompanion.insert(
                id: id,
                snippet: snippet,
                historyId: historyId,
                subject: subject,
                fromAddress: fromAddress,
                labelIds: labelIds,
                lastMessageTimestamp: lastMessageTimestamp,
                messageCount: messageCount,
                isRead: isRead,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ThreadsTableProcessedTableManager =
    ProcessedTableManager<
      _$MailDatabase,
      $ThreadsTable,
      Thread,
      $$ThreadsTableFilterComposer,
      $$ThreadsTableOrderingComposer,
      $$ThreadsTableAnnotationComposer,
      $$ThreadsTableCreateCompanionBuilder,
      $$ThreadsTableUpdateCompanionBuilder,
      (Thread, BaseReferences<_$MailDatabase, $ThreadsTable, Thread>),
      Thread,
      PrefetchHooks Function()
    >;
typedef $$MessagesTableCreateCompanionBuilder =
    MessagesCompanion Function({
      required String id,
      required String threadId,
      required String fromAddress,
      required String toAddress,
      required String subject,
      required String snippet,
      required String body,
      required int date,
      required String labelIds,
      required bool isRead,
      Value<int> rowid,
    });
typedef $$MessagesTableUpdateCompanionBuilder =
    MessagesCompanion Function({
      Value<String> id,
      Value<String> threadId,
      Value<String> fromAddress,
      Value<String> toAddress,
      Value<String> subject,
      Value<String> snippet,
      Value<String> body,
      Value<int> date,
      Value<String> labelIds,
      Value<bool> isRead,
      Value<int> rowid,
    });

class $$MessagesTableFilterComposer
    extends Composer<_$MailDatabase, $MessagesTable> {
  $$MessagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get threadId => $composableBuilder(
    column: $table.threadId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fromAddress => $composableBuilder(
    column: $table.fromAddress,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get toAddress => $composableBuilder(
    column: $table.toAddress,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subject => $composableBuilder(
    column: $table.subject,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get snippet => $composableBuilder(
    column: $table.snippet,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get labelIds => $composableBuilder(
    column: $table.labelIds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isRead => $composableBuilder(
    column: $table.isRead,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MessagesTableOrderingComposer
    extends Composer<_$MailDatabase, $MessagesTable> {
  $$MessagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get threadId => $composableBuilder(
    column: $table.threadId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fromAddress => $composableBuilder(
    column: $table.fromAddress,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get toAddress => $composableBuilder(
    column: $table.toAddress,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subject => $composableBuilder(
    column: $table.subject,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get snippet => $composableBuilder(
    column: $table.snippet,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get labelIds => $composableBuilder(
    column: $table.labelIds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isRead => $composableBuilder(
    column: $table.isRead,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MessagesTableAnnotationComposer
    extends Composer<_$MailDatabase, $MessagesTable> {
  $$MessagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get threadId =>
      $composableBuilder(column: $table.threadId, builder: (column) => column);

  GeneratedColumn<String> get fromAddress => $composableBuilder(
    column: $table.fromAddress,
    builder: (column) => column,
  );

  GeneratedColumn<String> get toAddress =>
      $composableBuilder(column: $table.toAddress, builder: (column) => column);

  GeneratedColumn<String> get subject =>
      $composableBuilder(column: $table.subject, builder: (column) => column);

  GeneratedColumn<String> get snippet =>
      $composableBuilder(column: $table.snippet, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<int> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get labelIds =>
      $composableBuilder(column: $table.labelIds, builder: (column) => column);

  GeneratedColumn<bool> get isRead =>
      $composableBuilder(column: $table.isRead, builder: (column) => column);
}

class $$MessagesTableTableManager
    extends
        RootTableManager<
          _$MailDatabase,
          $MessagesTable,
          Message,
          $$MessagesTableFilterComposer,
          $$MessagesTableOrderingComposer,
          $$MessagesTableAnnotationComposer,
          $$MessagesTableCreateCompanionBuilder,
          $$MessagesTableUpdateCompanionBuilder,
          (Message, BaseReferences<_$MailDatabase, $MessagesTable, Message>),
          Message,
          PrefetchHooks Function()
        > {
  $$MessagesTableTableManager(_$MailDatabase db, $MessagesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MessagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MessagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MessagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> threadId = const Value.absent(),
                Value<String> fromAddress = const Value.absent(),
                Value<String> toAddress = const Value.absent(),
                Value<String> subject = const Value.absent(),
                Value<String> snippet = const Value.absent(),
                Value<String> body = const Value.absent(),
                Value<int> date = const Value.absent(),
                Value<String> labelIds = const Value.absent(),
                Value<bool> isRead = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MessagesCompanion(
                id: id,
                threadId: threadId,
                fromAddress: fromAddress,
                toAddress: toAddress,
                subject: subject,
                snippet: snippet,
                body: body,
                date: date,
                labelIds: labelIds,
                isRead: isRead,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String threadId,
                required String fromAddress,
                required String toAddress,
                required String subject,
                required String snippet,
                required String body,
                required int date,
                required String labelIds,
                required bool isRead,
                Value<int> rowid = const Value.absent(),
              }) => MessagesCompanion.insert(
                id: id,
                threadId: threadId,
                fromAddress: fromAddress,
                toAddress: toAddress,
                subject: subject,
                snippet: snippet,
                body: body,
                date: date,
                labelIds: labelIds,
                isRead: isRead,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MessagesTableProcessedTableManager =
    ProcessedTableManager<
      _$MailDatabase,
      $MessagesTable,
      Message,
      $$MessagesTableFilterComposer,
      $$MessagesTableOrderingComposer,
      $$MessagesTableAnnotationComposer,
      $$MessagesTableCreateCompanionBuilder,
      $$MessagesTableUpdateCompanionBuilder,
      (Message, BaseReferences<_$MailDatabase, $MessagesTable, Message>),
      Message,
      PrefetchHooks Function()
    >;
typedef $$LabelsTableCreateCompanionBuilder =
    LabelsCompanion Function({
      required String id,
      required String name,
      required String type,
      Value<int> rowid,
    });
typedef $$LabelsTableUpdateCompanionBuilder =
    LabelsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> type,
      Value<int> rowid,
    });

class $$LabelsTableFilterComposer
    extends Composer<_$MailDatabase, $LabelsTable> {
  $$LabelsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LabelsTableOrderingComposer
    extends Composer<_$MailDatabase, $LabelsTable> {
  $$LabelsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LabelsTableAnnotationComposer
    extends Composer<_$MailDatabase, $LabelsTable> {
  $$LabelsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);
}

class $$LabelsTableTableManager
    extends
        RootTableManager<
          _$MailDatabase,
          $LabelsTable,
          Label,
          $$LabelsTableFilterComposer,
          $$LabelsTableOrderingComposer,
          $$LabelsTableAnnotationComposer,
          $$LabelsTableCreateCompanionBuilder,
          $$LabelsTableUpdateCompanionBuilder,
          (Label, BaseReferences<_$MailDatabase, $LabelsTable, Label>),
          Label,
          PrefetchHooks Function()
        > {
  $$LabelsTableTableManager(_$MailDatabase db, $LabelsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LabelsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LabelsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LabelsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) =>
                  LabelsCompanion(id: id, name: name, type: type, rowid: rowid),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String type,
                Value<int> rowid = const Value.absent(),
              }) => LabelsCompanion.insert(
                id: id,
                name: name,
                type: type,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LabelsTableProcessedTableManager =
    ProcessedTableManager<
      _$MailDatabase,
      $LabelsTable,
      Label,
      $$LabelsTableFilterComposer,
      $$LabelsTableOrderingComposer,
      $$LabelsTableAnnotationComposer,
      $$LabelsTableCreateCompanionBuilder,
      $$LabelsTableUpdateCompanionBuilder,
      (Label, BaseReferences<_$MailDatabase, $LabelsTable, Label>),
      Label,
      PrefetchHooks Function()
    >;

class $MailDatabaseManager {
  final _$MailDatabase _db;
  $MailDatabaseManager(this._db);
  $$ThreadsTableTableManager get threads =>
      $$ThreadsTableTableManager(_db, _db.threads);
  $$MessagesTableTableManager get messages =>
      $$MessagesTableTableManager(_db, _db.messages);
  $$LabelsTableTableManager get labels =>
      $$LabelsTableTableManager(_db, _db.labels);
}

mixin _$ThreadDaoMixin on DatabaseAccessor<MailDatabase> {
  $ThreadsTable get threads => attachedDatabase.threads;
}
mixin _$MessageDaoMixin on DatabaseAccessor<MailDatabase> {
  $MessagesTable get messages => attachedDatabase.messages;
}
mixin _$LabelDaoMixin on DatabaseAccessor<MailDatabase> {
  $LabelsTable get labels => attachedDatabase.labels;
}
