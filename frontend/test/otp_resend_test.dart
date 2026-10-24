import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:frontend/features/auth/data/models/auth_models.dart';
import 'package:frontend/features/auth/data/repositories/auth_repository.dart';
import 'package:frontend/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:frontend/features/auth/presentation/bloc/auth_state.dart';
import 'package:frontend/features/auth/presentation/pages/otp_page.dart';
import 'package:frontend/features/auth/presentation/pages/login_page.dart'
    show LoginPage;

class OtpRepository implements AuthRepository {
  int sent = 0;
  bool fail = false;
  String? verifiedEmail;
  @override
  Future<void> resendOtp(String email) async {
    if (fail) {
      throw DioException(
        requestOptions: RequestOptions(),
        response: Response(
          requestOptions: RequestOptions(),
          statusCode: 503,
          data: {'message': 'Chưa gửi được email xác thực.'},
        ),
      );
    }
    sent++;
  }

  @override
  Future<void> register(RegisterRequest request) async {}
  @override
  Future<void> verifyOtp(VerifyOtpRequest request) async {
    verifiedEmail = request.email;
  }

  @override
  Future<AuthResponse> login(LoginRequest request) =>
      throw UnimplementedError();
}

void main() {
  testWidgets(
    'Admin-created user can open verification from login and verify OTP',
    (tester) async {
      final repository = OtpRepository();
      final bloc = AuthBloc(repository);
      await tester.pumpWidget(
        BlocProvider.value(
          value: bloc,
          child: const MaterialApp(home: LoginPage()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextFormField).first,
        'new@example.com',
      );
      await tester.ensureVisible(find.text('Xác thực email'));
      await tester.tap(find.text('Xác thực email'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<OtpPage>(find.byType(OtpPage)).email,
        'new@example.com',
      );
      expect(
        tester
            .widget<TextButton>(find.widgetWithText(TextButton, 'Gửi lại mã'))
            .onPressed,
        isNotNull,
      );
      await tester.enterText(find.byType(TextFormField).first, '123456');
      await tester.ensureVisible(find.text('Xác thực ngay'));
      await tester.tap(find.text('Xác thực ngay'));
      await tester.pumpAndSettle();
      expect(repository.verifiedEmail, 'new@example.com');
      expect(find.byType(OtpPage), findsNothing);
      expect(find.byType(LoginPage), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(() => bloc.close());
    },
  );

  testWidgets(
    'Resend waits 60 seconds and reports success without leaving OTP page',
    (tester) async {
      final repository = OtpRepository();
      final bloc = AuthBloc(repository);
      await tester.pumpWidget(
        BlocProvider.value(
          value: bloc,
          child: const MaterialApp(home: OtpPage(email: 'tenant@example.com')),
        ),
      );
      await tester.pumpAndSettle();
      final disabled = find.widgetWithText(
        TextButton,
        'Gửi lại mã sau 60 giây',
      );
      expect(tester.widget<TextButton>(disabled).onPressed, isNull);
      await tester.pump(const Duration(seconds: 60));
      await tester.ensureVisible(find.text('Gửi lại mã'));
      await tester.tap(find.text('Gửi lại mã'));
      await tester.pumpAndSettle();
      expect(repository.sent, 1);
      expect(bloc.state, isA<AuthOtpResent>());
      expect(find.text('Xác thực OTP'), findsOneWidget);
      expect(find.text('Gửi lại mã sau 60 giây'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(() => bloc.close());
    },
  );
  testWidgets('SMTP failure is displayed and not reported as sent', (
    tester,
  ) async {
    final repository = OtpRepository()..fail = true;
    final bloc = AuthBloc(repository);
    await tester.pumpWidget(
      BlocProvider.value(
        value: bloc,
        child: const MaterialApp(home: OtpPage(email: 'tenant@example.com')),
      ),
    );
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 60));
    await tester.ensureVisible(find.text('Gửi lại mã'));
    await tester.tap(find.text('Gửi lại mã'));
    await tester.pumpAndSettle();
    expect(repository.sent, 0);
    expect(bloc.state, isA<AuthError>());
    expect(find.text('Chưa gửi được email xác thực.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(() => bloc.close());
  });
}
