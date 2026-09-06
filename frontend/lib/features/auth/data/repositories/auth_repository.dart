import '../datasources/auth_remote_data_source.dart';
import '../models/auth_models.dart';

abstract class AuthRepository {
  Future<AuthResponse> login(LoginRequest request);
  Future<void> register(RegisterRequest request);
  Future<void> verifyOtp(VerifyOtpRequest request);
}

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;

  AuthRepositoryImpl(this._remoteDataSource);

  @override
  Future<AuthResponse> login(LoginRequest request) async {
    return _remoteDataSource.login(request);
  }

  @override
  Future<void> register(RegisterRequest request) async {
    return _remoteDataSource.register(request);
  }

  @override
  Future<void> verifyOtp(VerifyOtpRequest request) async {
    return _remoteDataSource.verifyOtp(request);
  }
}
