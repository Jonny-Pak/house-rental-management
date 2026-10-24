import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../models/system_content.dart';

class SystemContentRepository {
  SystemContentRepository(this.api);
  final ApiClient api;

  Future<List<SystemContent>> list() async {
    final response = await api.get('/admin/content');
    final rows = response.data['data'] as List;
    final result = <SystemContent>[];
    for (final row in rows) {
      final data = Map<String, dynamic>.from(row);
      result.add(SystemContent.fromJson(data));
    }
    return result;
  }

  Future<SystemContent> detail(String slug) async {
    final response = await api.get('/admin/content/$slug');
    return SystemContent.fromJson(
      Map<String, dynamic>.from(response.data['data']),
    );
  }

  Future<SystemContent> saveDraft(
    String slug,
    String title,
    String body,
    int version,
  ) async {
    final response = await api.put('/admin/content/$slug', {
      'title': title.trim(),
      'body': body.trim(),
      'version': version,
    });
    return SystemContent.fromJson(
      Map<String, dynamic>.from(response.data['data']),
    );
  }

  Future<SystemContent> publish(
    String slug,
    String title,
    String body,
    int version,
  ) async {
    final response = await api.post('/admin/content/$slug/publish', {
      'title': title.trim(),
      'body': body.trim(),
      'version': version,
    });
    return SystemContent.fromJson(
      Map<String, dynamic>.from(response.data['data']),
    );
  }

  Future<SystemContent> unpublish(String slug, int version) async {
    final response = await api.post('/admin/content/$slug/unpublish', {
      'version': version,
    });
    return SystemContent.fromJson(
      Map<String, dynamic>.from(response.data['data']),
    );
  }

  Future<PublishedContent> published(String slug) async {
    final response = await api.get('/content/$slug');
    return PublishedContent.fromJson(
      Map<String, dynamic>.from(response.data['data']),
    );
  }
}

String contentError(Object error) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map && data['message'] is String) {
      return data['message'] as String;
    }
    return 'Không tải được nội dung. Vui lòng kiểm tra kết nối và thử lại.';
  }
  return 'Không thực hiện được thao tác. Vui lòng thử lại.';
}
