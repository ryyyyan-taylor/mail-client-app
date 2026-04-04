// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gmail_dtos.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ThreadListResponse _$ThreadListResponseFromJson(Map<String, dynamic> json) =>
    ThreadListResponse(
      threads: (json['threads'] as List<dynamic>?)
          ?.map((e) => ThreadSummaryDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      nextPageToken: json['nextPageToken'] as String?,
      resultSizeEstimate: (json['resultSizeEstimate'] as num?)?.toInt(),
    );

Map<String, dynamic> _$ThreadListResponseToJson(ThreadListResponse instance) =>
    <String, dynamic>{
      'threads': instance.threads,
      'nextPageToken': instance.nextPageToken,
      'resultSizeEstimate': instance.resultSizeEstimate,
    };

ThreadSummaryDto _$ThreadSummaryDtoFromJson(Map<String, dynamic> json) =>
    ThreadSummaryDto(
      id: json['id'] as String,
      snippet: json['snippet'] as String?,
      historyId: json['historyId'] as String?,
    );

Map<String, dynamic> _$ThreadSummaryDtoToJson(ThreadSummaryDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'snippet': instance.snippet,
      'historyId': instance.historyId,
    };

ThreadDetailDto _$ThreadDetailDtoFromJson(Map<String, dynamic> json) =>
    ThreadDetailDto(
      id: json['id'] as String,
      snippet: json['snippet'] as String?,
      historyId: json['historyId'] as String?,
      messages: (json['messages'] as List<dynamic>?)
          ?.map((e) => MessageDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ThreadDetailDtoToJson(ThreadDetailDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'snippet': instance.snippet,
      'historyId': instance.historyId,
      'messages': instance.messages?.map((e) => e.toJson()).toList(),
    };

MessageDto _$MessageDtoFromJson(Map<String, dynamic> json) => MessageDto(
  id: json['id'] as String,
  threadId: json['threadId'] as String?,
  labelIds: (json['labelIds'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  snippet: json['snippet'] as String?,
  payload: json['payload'] == null
      ? null
      : PayloadDto.fromJson(json['payload'] as Map<String, dynamic>),
  internalDate: json['internalDate'] as String?,
);

Map<String, dynamic> _$MessageDtoToJson(MessageDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'threadId': instance.threadId,
      'labelIds': instance.labelIds,
      'snippet': instance.snippet,
      'payload': instance.payload?.toJson(),
      'internalDate': instance.internalDate,
    };

PayloadDto _$PayloadDtoFromJson(Map<String, dynamic> json) => PayloadDto(
  mimeType: json['mimeType'] as String?,
  headers: (json['headers'] as List<dynamic>?)
      ?.map((e) => HeaderDto.fromJson(e as Map<String, dynamic>))
      .toList(),
  body: json['body'] == null
      ? null
      : BodyDto.fromJson(json['body'] as Map<String, dynamic>),
  parts: (json['parts'] as List<dynamic>?)
      ?.map((e) => PayloadDto.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$PayloadDtoToJson(PayloadDto instance) =>
    <String, dynamic>{
      'mimeType': instance.mimeType,
      'headers': instance.headers?.map((e) => e.toJson()).toList(),
      'body': instance.body?.toJson(),
      'parts': instance.parts?.map((e) => e.toJson()).toList(),
    };

HeaderDto _$HeaderDtoFromJson(Map<String, dynamic> json) =>
    HeaderDto(name: json['name'] as String, value: json['value'] as String);

Map<String, dynamic> _$HeaderDtoToJson(HeaderDto instance) => <String, dynamic>{
  'name': instance.name,
  'value': instance.value,
};

BodyDto _$BodyDtoFromJson(Map<String, dynamic> json) => BodyDto(
  size: (json['size'] as num?)?.toInt(),
  data: json['data'] as String?,
);

Map<String, dynamic> _$BodyDtoToJson(BodyDto instance) => <String, dynamic>{
  'size': instance.size,
  'data': instance.data,
};

LabelListResponse _$LabelListResponseFromJson(Map<String, dynamic> json) =>
    LabelListResponse(
      labels: (json['labels'] as List<dynamic>?)
          ?.map((e) => LabelDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$LabelListResponseToJson(LabelListResponse instance) =>
    <String, dynamic>{
      'labels': instance.labels?.map((e) => e.toJson()).toList(),
    };

LabelDto _$LabelDtoFromJson(Map<String, dynamic> json) => LabelDto(
  id: json['id'] as String,
  name: json['name'] as String?,
  type: json['type'] as String?,
);

Map<String, dynamic> _$LabelDtoToJson(LabelDto instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'type': instance.type,
};

ModifyRequest _$ModifyRequestFromJson(Map<String, dynamic> json) =>
    ModifyRequest(
      addLabelIds: (json['addLabelIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      removeLabelIds: (json['removeLabelIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$ModifyRequestToJson(ModifyRequest instance) =>
    <String, dynamic>{
      if (instance.addLabelIds case final value?) 'addLabelIds': value,
      if (instance.removeLabelIds case final value?) 'removeLabelIds': value,
    };
