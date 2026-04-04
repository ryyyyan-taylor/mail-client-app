import 'package:dio/dio.dart';
import 'gmail_dtos.dart';

/// Dio-based Gmail API v1 client — mirrors GmailApiService.kt (Retrofit interface).
/// All methods throw [DioException] on network/HTTP errors; callers handle them
/// in the repository layer.
class GmailApiService {
  GmailApiService(this._dio);

  final Dio _dio;

  static const _base = 'gmail/v1/users/me';

  /// Lists threads for a label or query. Uses format=metadata (fast, no body).
  Future<ThreadListResponse> listThreads({
    String? labelId,
    String? q,
    String? pageToken,
    int maxResults = 50,
  }) async {
    final response = await _dio.get(
      '$_base/threads',
      queryParameters: {
        'labelIds': ?labelId,
        'q': ?q,
        'pageToken': ?pageToken,
        'maxResults': maxResults,
      },
    );
    return ThreadListResponse.fromJson(response.data as Map<String, dynamic>);
  }

  /// Gets a single thread.
  /// [format] = 'metadata' for inbox list (fast), 'full' when opening a thread.
  Future<ThreadDetailDto> getThread(
    String id, {
    String format = 'metadata',
  }) async {
    final response = await _dio.get(
      '$_base/threads/$id',
      queryParameters: {'format': format},
    );
    return ThreadDetailDto.fromJson(response.data as Map<String, dynamic>);
  }

  /// Adds / removes labels on a thread (move, mark read/unread, spam, etc.).
  Future<ThreadSummaryDto> modifyThread(
    String id,
    ModifyRequest body,
  ) async {
    final response = await _dio.post(
      '$_base/threads/$id/modify',
      data: body.toJson(),
    );
    return ThreadSummaryDto.fromJson(response.data as Map<String, dynamic>);
  }

  /// Moves a thread to Trash.
  Future<ThreadSummaryDto> trashThread(String id) async {
    final response = await _dio.post('$_base/threads/$id/trash');
    return ThreadSummaryDto.fromJson(response.data as Map<String, dynamic>);
  }

  /// Restores a thread from Trash.
  Future<ThreadSummaryDto> untrashThread(String id) async {
    final response = await _dio.post('$_base/threads/$id/untrash');
    return ThreadSummaryDto.fromJson(response.data as Map<String, dynamic>);
  }

  /// Lists all labels for the authenticated user.
  Future<LabelListResponse> listLabels() async {
    final response = await _dio.get('$_base/labels');
    return LabelListResponse.fromJson(response.data as Map<String, dynamic>);
  }
}
