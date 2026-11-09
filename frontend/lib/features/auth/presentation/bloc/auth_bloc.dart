import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/storage/token_storage.dart';

import '../../data/repositories/auth_repository.dart';
import '../../data/google_sign_in_service.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  final GoogleSignInService _googleSignIn;

  AuthBloc(this._authRepository, {GoogleSignInService? googleSignIn})
    : _googleSignIn = googleSignIn ?? GoogleSignInService(),
      super(const AuthInitial()) {
    on<GoogleLoginRequested>(_onGoogleLoginRequested);
    on<LoginRequested>(_onLoginRequested);
    on<RegisterRequested>(_onRegisterRequested);
    on<VerifyOtpRequested>(_onVerifyOtpRequested);
    on<ResendOtpRequested>(_onResendOtpRequested);
    on<LogoutRequested>(_onLogoutRequested);
  }

  Future<void> _onGoogleLoginRequested(
    GoogleLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    if (state is AuthLoading) return;
    emit(const AuthLoading());
    try {
      final idToken = await _googleSignIn.getIdToken();
      if (idToken == null) {
        emit(const AuthInitial());
        return;
      }
      final response = await _authRepository.googleLogin(idToken);
      await TokenStorage.saveToken(response.accessToken);
      emit(AuthAuthenticated(response));
    } on GoogleLoginException catch (error) {
      emit(AuthError(error.message));
    } on DioException catch (error) {
      emit(AuthError(_extractErrorMessage(error)));
    } catch (_) {
      emit(const AuthError('Chưa đăng nhập được Google. Vui lòng thử lại.'));
    }
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      await TokenStorage.clearToken();
      emit(const AuthUnauthenticated());
    } catch (_) {
      emit(const AuthError('Chưa đăng xuất được. Vui lòng thử lại.'));
    }
  }

  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    if (state is AuthLoading) return;
    emit(const AuthLoading());
    try {
      final authResponse = await _authRepository.login(event.request);
      await TokenStorage.saveToken(authResponse.accessToken);
      emit(AuthAuthenticated(authResponse));
    } on DioException catch (e) {
      final message = _extractErrorMessage(e);
      emit(AuthError(message));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onRegisterRequested(
    RegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    if (state is AuthLoading) return;
    emit(const AuthLoading());
    try {
      await _authRepository.register(event.request);
      emit(AuthOtpSent(event.request.email));
    } on DioException catch (e) {
      final message = _extractErrorMessage(e);
      emit(AuthError(message));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onResendOtpRequested(
    ResendOtpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      await _authRepository.resendOtp(event.email);
      emit(const AuthOtpResent());
    } on DioException catch (e) {
      emit(AuthError(_extractErrorMessage(e)));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onVerifyOtpRequested(
    VerifyOtpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      await _authRepository.verifyOtp(event.request);
      emit(const AuthUnauthenticated());
    } on DioException catch (e) {
      final message = _extractErrorMessage(e);
      emit(AuthError(message));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  String _extractErrorMessage(DioException e) {
    try {
      final responseData = e.response?.data;
      if (responseData is Map<String, dynamic>) {
        return responseData['message'] as String? ??
            'Có lỗi xảy ra. Vui lòng thử lại.';
      }
    } catch (_) {}
    return 'Không kết nối được máy chủ. Vui lòng thử lại.';
  }
}
