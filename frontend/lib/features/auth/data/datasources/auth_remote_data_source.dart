import '../../../../core/network/api_client.dart';
import '../models/auth_models.dart';

abstract class AuthRemoteDataSource {
  Future<AuthResponse> login(LoginRequest request);
  Future<void> register(RegisterRequest request);
  Future<void> verifyOtp(VerifyOtpRequest request);
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
    await _apiClient.post('/auth/register', request.toJson());
  }

  @override
  Future<void> verifyOtp(VerifyOtpRequest request) async {
    await _apiClient.post('/auth/verify-otp', request.toJson());
  }
}
