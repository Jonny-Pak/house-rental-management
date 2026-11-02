import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/storage/token_storage.dart';
import 'package:frontend/features/auth/data/google_sign_in_service.dart';
import 'package:frontend/features/auth/data/models/auth_models.dart';
import 'package:frontend/features/auth/data/repositories/auth_repository.dart';
import 'package:frontend/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:frontend/features/auth/presentation/bloc/auth_event.dart';
import 'package:frontend/features/auth/presentation/bloc/auth_state.dart';
import 'package:frontend/features/auth/presentation/pages/login_page.dart';
import 'package:frontend/features/auth/presentation/pages/register_page.dart';
import 'package:frontend/features/auth/presentation/widgets/google_login_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeGoogle extends GoogleSignInService {
  final pending = Completer<String?>();
  int calls = 0;
  @override
  Future<String?> getIdToken() {
    calls++;
    return pending.future;
  }
}

class GoogleRepository implements AuthRepository {
  int calls = 0;
  String? receivedToken;
  Object? error;
  @override
  Future<AuthResponse> googleLogin(String idToken) async {
    calls++;
    receivedToken = idToken;
    if (error != null) throw error!;
    return AuthResponse(
      accessToken: 'server-access',
      refreshToken: 'refresh',
      userId: 1,
      role: 'MEMBER',
    );
  }

  @override
  Future<AuthResponse> login(LoginRequest request) async =>
      throw UnimplementedError();
  @override
  Future<void> register(RegisterRequest request) async {}
  @override
  Future<void> verifyOtp(VerifyOtpRequest request) async {}
  @override
  Future<void> resendOtp(String email) async {}
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'Google success exchanges only ID token and stores the server access token',
    () async {
      final google = FakeGoogle();
      final repository = GoogleRepository();
      final bloc = AuthBloc(repository, googleSignIn: google);
      final done = bloc.stream.firstWhere(
        (state) => state is AuthAuthenticated,
      );
      bloc.add(const GoogleLoginRequested());
      google.pending.complete('google-id-token');
      final state = await done as AuthAuthenticated;
      expect(repository.receivedToken, 'google-id-token');
      expect(state.data.userId, 1);
      expect(await TokenStorage.getToken(), 'server-access');
      await bloc.close();
    },
  );

  test('Cancel leaves no session and does not call backend', () async {
    final google = FakeGoogle();
    final repository = GoogleRepository();
    final bloc = AuthBloc(repository, googleSignIn: google);
    final done = bloc.stream.firstWhere((state) => state is AuthInitial);
    bloc.add(const GoogleLoginRequested());
    google.pending.complete(null);
    await done;
    expect(repository.calls, 0);
    expect(await TokenStorage.getToken(), isNull);
    await bloc.close();
  });

  test(
    'Locked backend account reports message without saving a token',
    () async {
      final google = FakeGoogle();
      final repository = GoogleRepository();
      final request = RequestOptions(path: '/auth/google-login');
      repository.error = DioException(
        requestOptions: request,
        response: Response(
          requestOptions: request,
          statusCode: 403,
          data: {'message': 'Tài khoản đã bị khóa.'},
        ),
      );
      final bloc = AuthBloc(repository, googleSignIn: google);
      final done = bloc.stream.firstWhere((state) => state is AuthError);
      bloc.add(const GoogleLoginRequested());
      google.pending.complete('google-id-token');
      expect((await done as AuthError).message, 'Tài khoản đã bị khóa.');
      expect(await TokenStorage.getToken(), isNull);
      await bloc.close();
    },
  );

  test('Repeated taps and password events cannot start another login while Google is open', () async {
    final google = FakeGoogle();
    final repository = GoogleRepository();
    final bloc = AuthBloc(repository, googleSignIn: google);
    final loading = bloc.stream.firstWhere((state) => state is AuthLoading);
    bloc.add(const GoogleLoginRequested());
    await loading;
    bloc.add(const GoogleLoginRequested());
    bloc.add(
      const LoginRequested(
        LoginRequest(email: 'member@gmail.com', password: 'password'),
      ),
    );
    await Future<void>.delayed(Duration.zero);
    expect(google.calls, 1);
    final done = bloc.stream.firstWhere((state) => state is AuthInitial);
    google.pending.complete(null);
    await done;
    await bloc.close();
  });

  test(
    'Missing configuration is a readable error and can be retried',
    () async {
      final google = FakeGoogle();
      final repository = GoogleRepository();
      final bloc = AuthBloc(repository, googleSignIn: google);
      final done = bloc.stream.firstWhere((state) => state is AuthError);
      bloc.add(const GoogleLoginRequested());
      google.pending.completeError(
        const GoogleLoginException('Cần cấu hình Google.'),
      );
      expect((await done as AuthError).message, 'Cần cấu hình Google.');
      expect(repository.calls, 0);
      await bloc.close();
    },
  );

  test(
    'Android without Client ID does not invoke an unconfigured native plugin',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      await expectLater(
        const GoogleSignInService(webClientId: '').getIdToken(),
        throwsA(isA<GoogleLoginException>()),
      );
    },
  );

  for (final register in [false, true]) {
    testWidgets(
      'Google button works without filling ${register ? "registration" : "login"} form and restores it on cancel',
      (tester) async {
        final google = FakeGoogle();
        final repository = GoogleRepository();
        final bloc = AuthBloc(repository, googleSignIn: google);
        addTearDown(bloc.close);
        await tester.pumpWidget(
          BlocProvider.value(
            value: bloc,
            child: MaterialApp(
              home: register ? const RegisterPage() : const LoginPage(),
            ),
          ),
        );
        final inputs = find.byType(TextFormField);
        await tester.enterText(
          inputs.first,
          register ? 'Tên đang nhập' : 'member@gmail.com',
        );
        tester.testTextInput.hide();
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byType(GoogleLoginButton));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(GoogleLoginButton));
        await tester.pump();
        expect(google.calls, 1);
        final button = tester.widget<OutlinedButton>(
          find.descendant(
            of: find.byType(GoogleLoginButton),
            matching: find.byType(OutlinedButton),
          ),
        );
        expect(button.onPressed, isNull);
        google.pending.complete(null);
        await tester.pumpAndSettle();
        expect(repository.calls, 0);
        expect(
          find.text(register ? 'Tên đang nhập' : 'member@gmail.com'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}
