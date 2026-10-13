import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/storage/token_storage.dart';

import '../../data/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  AuthBloc(this._authRepository) : super(const AuthInitial()) {
    on<LoginRequested>(_onLoginRequested);
    on<RegisterRequested>(_onRegisterRequested);
    on<VerifyOtpRequested>(_onVerifyOtpRequested);
    on<ResendOtpRequested>(_onResendOtpRequested);
    on<LogoutRequested>(_onLogoutRequested);
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
    emit(const AuthLoading());
    try {
      final authResponse = await _authRepository.login(event.request);
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
    emit(const AuthLoading());
    try {
      await _authRepository.register(event.request);
      // After successful registration, signal that OTP was sent to the email
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
      // OTP verified — user should now log in
      emit(const AuthUnauthenticated());
    } on DioException catch (e) {
      final message = _extractErrorMessage(e);
      emit(AuthError(message));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  /// Extracts a human-readable error message from a [DioException].
  String _extractErrorMessage(DioException e) {
    try {
      final responseData = e.response?.data;
      if (responseData is Map<String, dynamic>) {
        return responseData['message'] as String? ??
            'An unknown error occurred.';
      }
    } catch (_) {}
    return e.message ?? 'Network error. Please try again.';
  }
}
