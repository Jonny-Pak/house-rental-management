import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../models/auth_models.dart';

abstract class AuthRemoteDataSource {
  Future<AuthResponse> login(LoginRequest request);
  Future<void> register(RegisterRequest request);
  Future<void> verifyOtp(VerifyOtpRequest request);
  Future<void> resendOtp(String email);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient _apiClient;

  AuthRemoteDataSourceImpl(this._apiClient);

  @override
  Future<AuthResponse> login(LoginRequest request) async {
    final response = await _apiClient.post('/auth/login', request.toJson());
    return AuthResponse.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> register(RegisterRequest request) async {
    await _apiClient.post(
      '/auth/register',
      request.toJson(),
      options: Options(receiveTimeout: const Duration(seconds: 60)),
    );
  }

  @override
  Future<void> verifyOtp(VerifyOtpRequest request) async {
    await _apiClient.post('/auth/verify-otp', request.toJson());
  }

  @override
  Future<void> resendOtp(String email) async {
    await _apiClient.post('/auth/resend-otp', {
      'email': email,
    }, options: Options(receiveTimeout: const Duration(seconds: 60)));
  }
}
