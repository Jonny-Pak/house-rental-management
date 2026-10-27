import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';

const incidentCategories = <String, String>{
  'ACCOUNT': 'Tài khoản',
  'LISTING': 'Tin đăng',
  'CONTRACT': 'Hợp đồng',
  'PAYMENT': 'Thanh toán',
  'TECHNICAL': 'Lỗi ứng dụng',
  'OTHER': 'Khác',
};
const incidentStatuses = <String, String>{
  'OPEN': 'Mới gửi',
  'IN_PROGRESS': 'Đang xử lý',
  'RESOLVED': 'Đã giải quyết',
  'REJECTED': 'Từ chối',
};

class IncidentUpdate {
  IncidentUpdate(Map<String, dynamic> json)
    : actorName = json['actorName'],
      status = json['status'],
      message = json['message'],
      createdAt = DateTime.parse(json['createdAt']);
  final String actorName, status, message;
  final DateTime createdAt;
}

class Incident {
  Incident(Map<String, dynamic> json)
    : id = (json['id'] as num).toInt(),
      title = json['title'],
      category = json['category'],
      description = json['description'],
      status = json['status'],
      reporterName = json['reporterName'],
      reporterEmail = json['reporterEmail'],
      version = (json['version'] as num).toInt(),
      createdAt = DateTime.parse(json['createdAt']),
      updatedAt = DateTime.parse(json['updatedAt']) {
    for (final item in json['history']) {
      history.add(IncidentUpdate(Map<String, dynamic>.from(item)));
    }
  }
  final int id, version;
  final String title,
      category,
      description,
      status,
      reporterName,
      reporterEmail;
  final DateTime createdAt, updatedAt;
  final history = <IncidentUpdate>[];
}

class IncidentPageData {
  IncidentPageData(Map<String, dynamic> json)
    : total = (json['total'] as num).toInt(),
      page = (json['page'] as num).toInt(),
      totalPages = (json['totalPages'] as num).toInt() {
    for (final item in json['items']) {
      items.add(Incident(Map<String, dynamic>.from(item)));
    }
  }
  final int total, page, totalPages;
  final items = <Incident>[];
}

class IncidentRepository {
  IncidentRepository(this.api);
  final ApiClient api;
  Future<IncidentPageData> fetch({
    bool admin = false,
    String query = '',
    String? status,
    String? category,
    int page = 0,
  }) async {
    final parameters = <String, dynamic>{'query': query.trim(), 'page': page};
    if (status != null) parameters['status'] = status;
    if (category != null) parameters['category'] = category;
    final response = await api.get(
      admin ? '/admin/incidents' : '/incidents/me',
      queryParams: parameters,
    );
    return IncidentPageData(Map<String, dynamic>.from(response.data['data']));
  }

  Future<Incident> detail(int id, {bool admin = false}) async {
    final path = admin ? '/admin/incidents/$id' : '/incidents/$id';
    final response = await api.get(path);
    return Incident(Map<String, dynamic>.from(response.data['data']));
  }

  Future<Incident> create(
    String requestKey,
    String title,
    String category,
    String description,
  ) async {
    final response = await api.post('/incidents', {
      'requestKey': requestKey,
      'title': title.trim(),
      'category': category,
      'description': description.trim(),
    });
    return Incident(Map<String, dynamic>.from(response.data['data']));
  }

  Future<Incident> update(
    int id,
    int version,
    String status,
    String message,
  ) async {
    final response = await api.patch(
      '/admin/incidents/$id',
      data: {'status': status, 'message': message.trim(), 'version': version},
    );
    return Incident(Map<String, dynamic>.from(response.data['data']));
  }
}

String incidentError(Object error) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map && data['message'] is String) {
      if (data['data'] is Map) return (data['data'] as Map).values.join('\n');
      return data['message'];
    }
  }
  return 'Không kết nối được máy chủ. Vui lòng thử lại.';
}
