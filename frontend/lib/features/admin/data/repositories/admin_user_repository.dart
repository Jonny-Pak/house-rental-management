import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../models/admin_user.dart';

class AdminUserRepository {
  AdminUserRepository(this.api);
  final ApiClient api;

  Future<AdminUserPage> search({
    String query = '',
    String? role,
    String? status,
    bool? verified,
    int page = 0,
  }) async {
    final params = <String, dynamic>{'query': query.trim(), 'page': page};
    if (role != null) {
      params['role'] = role;
    }
    if (status != null) {
      params['status'] = status;
    }
    if (verified != null) {
      params['verified'] = verified;
    }
    final response = await api.get('/admin/users', queryParams: params);
    return AdminUserPage.fromJson(
      Map<String, dynamic>.from(response.data['data']),
    );
  }

  Future<AdminUser> create({
    required String fullName,
    required String email,
    String phone = '',
    required String password,
    required String role,
  }) async {
    final response = await api.post('/admin/users', {
      'fullName': fullName.trim(),
      'email': email.trim().toLowerCase(),
      'phoneNumber': phone.trim(),
      'password': password,
      'role': role,
    });
    return AdminUser.fromJson(Map<String, dynamic>.from(response.data['data']));
  }

  Future<AdminUser> detail(int id) async {
    final response = await api.get('/admin/users/$id');
    return AdminUser.fromJson(Map<String, dynamic>.from(response.data['data']));
  }

  Future<void> update(
    int id,
    String fullName,
    String phone,
    String role,
  ) async {
    await api.put('/admin/users/$id', {
      'fullName': fullName.trim(),
      'phoneNumber': phone.trim(),
      'role': role,
    });
  }

  Future<void> changeStatus(int id, String status) async {
    await api.patch('/admin/users/$id/status', data: {'status': status});
  }
}

String adminUserError(Object error) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map && data['message'] is String) {
      return data['message'] as String;
    }
    return 'Không kết nối được máy chủ. Vui lòng thử lại.';
  }
  return 'Không thực hiện được thao tác. Vui lòng thử lại.';
}
