import 'package:equatable/equatable.dart';
import '../../data/models/auth_models.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class LoginRequested extends AuthEvent {
  final LoginRequest request;

  const LoginRequested(this.request);

  @override
  List<Object?> get props => [request.email];
}

class RegisterRequested extends AuthEvent {
  final RegisterRequest request;

  const RegisterRequested(this.request);

  @override
  List<Object?> get props => [request.email];
}

class VerifyOtpRequested extends AuthEvent {
  final VerifyOtpRequest request;

  const VerifyOtpRequested(this.request);

  @override
  List<Object?> get props => [request.email, request.otp];
}
