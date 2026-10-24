import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../../../features/auth/data/models/auth_models.dart';

@immutable
class SessionUser {
  const SessionUser({
    required this.name,
    required this.email,
    this.role = 'ADMIN',
  });

  final String name;
  final String email;
  final String role;

  String get initials => name
      .trim()
      .split(RegExp(r'\s+'))
      .take(2)
      .map((p) => p.isEmpty ? '' : p[0].toUpperCase())
      .join();
}

class SessionController extends Notifier<SessionUser?> {
  @override
  SessionUser? build() {
    _restoreSession();
    return null;
  }

  Future<void> _restoreSession() async {
    final token = await TokenStorage.getToken();
    if (token != null && token.isNotEmpty) {
      try {
        final response = await ApiClient().get('/users/me');
        final profile = response.data['data'] as Map;
        if (profile['role'] != 'ADMIN') {
          await TokenStorage.clearToken();
          return;
        }
        state = SessionUser(
          name: profile['fullName'] as String,
          email: profile['email'] as String,
          role: 'ADMIN',
        );
      } catch (_) {
        await TokenStorage.clearToken();
      }
    }
  }

  bool get isSignedIn => state != null;

  Future<void> signIn({required String email, required String password}) async {
    try {
      final client = ApiClient();
      final res = await client.post('/auth/login', {
        'email': email,
        'password': password,
      });

      if (res.statusCode == 200) {
        final authResponse = AuthResponse.fromJson(
          res.data as Map<String, dynamic>,
        );
        if (authResponse.role != 'ADMIN') {
          throw Exception('Tài khoản này không có quyền quản trị.');
        }
        await TokenStorage.saveToken(authResponse.accessToken);

        final handle = email
            .split('@')
            .first
            .replaceAll(RegExp(r'[._-]+'), ' ');
        state = SessionUser(
          name: handle.isEmpty
              ? 'Quản trị viên'
              : handle
                    .split(' ')
                    .map(
                      (w) => w.isEmpty
                          ? w
                          : '${w[0].toUpperCase()}${w.substring(1)}',
                    )
                    .join(' '),
          email: email,
          role: authResponse.role,
        );
      } else {
        throw Exception('Đăng nhập thất bại.');
      }
    } on DioException catch (e) {
      String msg = 'Tài khoản hoặc mật khẩu không chính xác.';
      if (e.response?.data is Map && e.response?.data['message'] != null) {
        msg = e.response!.data['message'].toString();
      }
      throw Exception(msg);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<void> signOut() async {
    await TokenStorage.clearToken();
    state = null;
  }
}

final sessionProvider = NotifierProvider<SessionController, SessionUser?>(
  SessionController.new,
);
