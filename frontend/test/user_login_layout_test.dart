import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/auth/data/models/auth_models.dart';
import 'package:frontend/features/auth/data/repositories/auth_repository.dart';
import 'package:frontend/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:frontend/features/auth/presentation/pages/login_page.dart';
import 'package:frontend/features/auth/presentation/pages/password_page.dart';
import 'package:frontend/features/auth/presentation/pages/register_page.dart';

class LoginRepository implements AuthRepository {
  final pending = Completer<AuthResponse>();
  int calls = 0;
  LoginRequest? request;
  @override
  Future<AuthResponse> googleLogin(String idToken) async =>
      throw UnimplementedError();

  @override
  Future<AuthResponse> login(LoginRequest request) {
    calls++;
    this.request = request;
    return pending.future;
  }

  @override
  Future<void> register(RegisterRequest request) async {}
  @override
  Future<void> verifyOtp(VerifyOtpRequest request) async {}
  @override
  Future<void> resendOtp(String email) async {}
}

Future<void> openLogin(
  WidgetTester tester,
  LoginRepository repository, {
  double scale = 1,
  double keyboard = 0,
}) async {
  await tester.pumpWidget(
    BlocProvider(
      create: (_) => AuthBloc(repository),
      child: MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(scale),
            viewInsets: EdgeInsets.only(bottom: keyboard),
          ),
          child: child!,
        ),
        home: const LoginPage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> press(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pump();
}

void main() {
  testWidgets(
    'Login remains usable with large text, narrow windows and keyboard',
    (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      for (final width in [320.0, 800.0, 1440.0]) {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.binding.setSurfaceSize(Size(width, 800));
        await openLogin(tester, LoginRepository(), scale: 1.8, keyboard: 280);
        await tester.ensureVisible(
          find.widgetWithText(ElevatedButton, 'Đăng nhập'),
        );
        await tester.pumpAndSettle();
        expect(find.text('Xác thực email'), findsNothing);
        expect(tester.takeException(), isNull);
      }
    },
  );
  testWidgets(
    'Validation, visibility, keyboard submission, loading and error preserve input',
    (tester) async {
      final repository = LoginRepository();
      await openLogin(tester, repository);
      await press(tester, find.widgetWithText(ElevatedButton, 'Đăng nhập'));
      await tester.pumpAndSettle();
      expect(repository.calls, 0);
      expect(find.text('Email không hợp lệ'), findsOneWidget);
      await tester.enterText(
        find.byType(TextFormField).first,
        'member@example.com',
      );
      await tester.enterText(find.byType(TextFormField).last, 'password123');
      await press(tester, find.byTooltip('Hiện mật khẩu'));
      expect(
        tester.widget<EditableText>(find.byType(EditableText).last).obscureText,
        false,
      );
      await tester.showKeyboard(find.byType(TextFormField).last);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(repository.calls, 1);
      expect(repository.request!.email, 'member@example.com');
      expect(
        tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
        isNull,
      );
      repository.pending.completeError(
        Exception('Email hoặc mật khẩu không đúng.'),
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Email hoặc mật khẩu không đúng.'),
        findsOneWidget,
      );
      expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField).first)
            .controller!
            .text,
        'member@example.com',
      );
      expect(
        tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
        isNotNull,
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('Forgot password and register navigation still work', (
    tester,
  ) async {
    await openLogin(tester, LoginRepository());
    await tester.enterText(
      find.byType(TextFormField).first,
      'member@example.com',
    );
    await press(tester, find.text('Quên mật khẩu?'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<PasswordPage>(find.byType(PasswordPage)).initialEmail,
      'member@example.com',
    );
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    await press(tester, find.text('Đăng ký'));
    await tester.pumpAndSettle();
    expect(find.byType(RegisterPage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
