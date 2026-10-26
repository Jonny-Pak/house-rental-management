import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';

class PasswordRepository {
  PasswordRepository(this.api);
  final ApiClient api;
  Future<String> requestReset(String email) async {
    final response = await api.post('/auth/forgot-password', {
      'email': email.trim(),
    });
    return response.data['message'] as String;
  }

  Future<void> reset(String email, String otp, String password) async {
    await api.post('/auth/reset-password', {
      'email': email.trim(),
      'otp': otp.trim(),
      'newPassword': password,
    });
  }

  Future<void> change(String currentPassword, String newPassword) async {
    await api.post('/users/me/change-password', {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
  }
}

String passwordError(Object error) {
  if (error is DioException && error.response?.data is Map) {
    final message = error.response!.data['message'];
    if (message is String) return message;
  }
  return 'Chưa thực hiện được. Vui lòng kiểm tra kết nối và thử lại.';
}
