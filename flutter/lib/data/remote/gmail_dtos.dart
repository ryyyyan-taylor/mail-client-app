import 'package:json_annotation/json_annotation.dart';

part 'gmail_dtos.g.dart';

// ── Thread list ───────────────────────────────────────────────────────────────

@JsonSerializable()
class ThreadListResponse {
  const ThreadListResponse({
    this.threads,
    this.nextPageToken,
    this.resultSizeEstimate,
  });

  final List<ThreadSummaryDto>? threads;
  final String? nextPageToken;
  final int? resultSizeEstimate;

  factory ThreadListResponse.fromJson(Map<String, dynamic> json) =>
      _$ThreadListResponseFromJson(json);
  Map<String, dynamic> toJson() => _$ThreadListResponseToJson(this);
}

@JsonSerializable()
class ThreadSummaryDto {
  const ThreadSummaryDto({
    required this.id,
    this.snippet,
    this.historyId,
  });

  final String id;
  final String? snippet;
  final String? historyId;

  factory ThreadSummaryDto.fromJson(Map<String, dynamic> json) =>
      _$ThreadSummaryDtoFromJson(json);
  Map<String, dynamic> toJson() => _$ThreadSummaryDtoToJson(this);
}

// ── Thread detail (threads.get) ───────────────────────────────────────────────

@JsonSerializable(explicitToJson: true)
class ThreadDetailDto {
  const ThreadDetailDto({
    required this.id,
    this.snippet,
    this.historyId,
    this.messages,
  });

  final String id;
  final String? snippet;
  final String? historyId;
  final List<MessageDto>? messages;

  factory ThreadDetailDto.fromJson(Map<String, dynamic> json) =>
      _$ThreadDetailDtoFromJson(json);
  Map<String, dynamic> toJson() => _$ThreadDetailDtoToJson(this);
}

// ── Message ───────────────────────────────────────────────────────────────────

@JsonSerializable(explicitToJson: true)
class MessageDto {
  const MessageDto({
    required this.id,
    this.threadId,
    this.labelIds,
    this.snippet,
    this.payload,
    this.internalDate,
  });

  final String id;
  final String? threadId;
  final List<String>? labelIds;
  final String? snippet;
  final PayloadDto? payload;
  /// Epoch millis as a string (Gmail API quirk).
  final String? internalDate;

  factory MessageDto.fromJson(Map<String, dynamic> json) =>
      _$MessageDtoFromJson(json);
  Map<String, dynamic> toJson() => _$MessageDtoToJson(this);
}

@JsonSerializable(explicitToJson: true)
class PayloadDto {
  const PayloadDto({
    this.mimeType,
    this.headers,
    this.body,
    this.parts,
  });

  final String? mimeType;
  final List<HeaderDto>? headers;
  final BodyDto? body;
  /// Recursive: MIME multipart parts can themselves contain parts.
  final List<PayloadDto>? parts;

  factory PayloadDto.fromJson(Map<String, dynamic> json) =>
      _$PayloadDtoFromJson(json);
  Map<String, dynamic> toJson() => _$PayloadDtoToJson(this);
}

@JsonSerializable()
class HeaderDto {
  const HeaderDto({required this.name, required this.value});

  final String name;
  final String value;

  factory HeaderDto.fromJson(Map<String, dynamic> json) =>
      _$HeaderDtoFromJson(json);
  Map<String, dynamic> toJson() => _$HeaderDtoToJson(this);
}

@JsonSerializable()
class BodyDto {
  const BodyDto({this.size, this.data});

  final int? size;
  /// Base64url-encoded body data.
  final String? data;

  factory BodyDto.fromJson(Map<String, dynamic> json) =>
      _$BodyDtoFromJson(json);
  Map<String, dynamic> toJson() => _$BodyDtoToJson(this);
}

// ── Labels ────────────────────────────────────────────────────────────────────

@JsonSerializable(explicitToJson: true)
class LabelListResponse {
  const LabelListResponse({this.labels});

  final List<LabelDto>? labels;

  factory LabelListResponse.fromJson(Map<String, dynamic> json) =>
      _$LabelListResponseFromJson(json);
  Map<String, dynamic> toJson() => _$LabelListResponseToJson(this);
}

@JsonSerializable()
class LabelDto {
  const LabelDto({required this.id, this.name, this.type});

  final String id;
  /// Nullable: some system labels omit the name field entirely.
  final String? name;
  final String? type;

  factory LabelDto.fromJson(Map<String, dynamic> json) =>
      _$LabelDtoFromJson(json);
  Map<String, dynamic> toJson() => _$LabelDtoToJson(this);
}

// ── Modify request ────────────────────────────────────────────────────────────

@JsonSerializable(includeIfNull: false)
class ModifyRequest {
  const ModifyRequest({this.addLabelIds, this.removeLabelIds});

  final List<String>? addLabelIds;
  final List<String>? removeLabelIds;

  Map<String, dynamic> toJson() => _$ModifyRequestToJson(this);
}
