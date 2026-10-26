import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/auth/data/repositories/password_repository.dart';
import 'package:frontend/features/auth/presentation/pages/password_page.dart';

class FakePasswords extends PasswordRepository {
  FakePasswords() : super(ApiClient());
  int sends = 0, resets = 0, changes = 0;
  bool mailFails = false, resetFails = false, changeFails = false;
  String? address, code, current, password;
  void failure(String message) => throw DioException(
    requestOptions: RequestOptions(),
    response: Response(
      requestOptions: RequestOptions(),
      statusCode: 400,
      data: {'message': message},
    ),
  );
  @override
  Future<String> requestReset(String email) async {
    sends++;
    address = email;
    if (mailFails) failure('Chưa gửi được email.');
    return 'Kiểm tra email để lấy mã đặt lại mật khẩu.';
  }

  @override
  Future<void> reset(String email, String otp, String password) async {
    resets++;
    address = email;
    code = otp;
    this.password = password;
    if (resetFails) failure('Mã không hợp lệ hoặc hết hạn.');
  }

  @override
  Future<void> change(String currentPassword, String newPassword) async {
    changes++;
    current = currentPassword;
    password = newPassword;
    if (changeFails) failure('Mật khẩu hiện tại không đúng.');
  }
}

Future<void> open(
  WidgetTester tester,
  FakePasswords repository, {
  bool change = false,
  double width = 430,
}) async {
  await tester.binding.setSurfaceSize(Size(width, 1000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(
        brightness: width < 400 ? Brightness.dark : Brightness.light,
      ),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(width < 400 ? 1.5 : 1)),
        child: child!,
      ),
      home: PasswordPage(changePassword: change, repository: repository),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> press(WidgetTester tester, String text) async {
  final buttons = find.widgetWithText(FilledButton, text);
  final finder = buttons.evaluate().isNotEmpty
      ? buttons.last
      : find.text(text).last;
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> fill(WidgetTester tester, String key, String text) async {
  final finder = find.byKey(ValueKey(key));
  await tester.ensureVisible(finder);
  await tester.enterText(finder, text);
}

void main() {
  testWidgets(
    'Forgot password validates, resends, resets and returns to login',
    (tester) async {
      final repository = FakePasswords();
      await open(tester, repository);
      await press(tester, 'Gửi mã OTP');
      expect(repository.sends, 0);
      await fill(tester, 'password-email', 'member@example.com');
      await press(tester, 'Gửi mã OTP');
      expect(repository.sends, 1);
      expect(find.textContaining('Gửi lại sau'), findsOneWidget);
      await tester.pump(const Duration(seconds: 60));
      await tester.pumpAndSettle();
      await press(tester, 'Gửi lại mã');
      expect(repository.sends, 2);
      await fill(tester, 'password-otp', '123456');
      await fill(tester, 'password-new', 'NewPassword123');
      await fill(tester, 'password-confirm', 'not-matching');
      await press(tester, 'Đặt lại mật khẩu');
      expect(repository.resets, 0);
      await fill(tester, 'password-confirm', 'NewPassword123');
      await press(tester, 'Đặt lại mật khẩu');
      expect(repository.resets, 1);
      expect(repository.code, '123456');
      expect(repository.password, 'NewPassword123');
      expect(find.text('Quay lại đăng nhập'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('Mail and invalid OTP errors preserve input and allow retry', (
    tester,
  ) async {
    final repository = FakePasswords()..mailFails = true;
    await open(tester, repository);
    await fill(tester, 'password-email', 'member@example.com');
    await press(tester, 'Gửi mã OTP');
    expect(find.text('Chưa gửi được email.'), findsOneWidget);
    repository.mailFails = false;
    await press(tester, 'Gửi mã OTP');
    await fill(tester, 'password-otp', '123456');
    await fill(tester, 'password-new', 'NewPassword123');
    await fill(tester, 'password-confirm', 'NewPassword123');
    repository.resetFails = true;
    await press(tester, 'Đặt lại mật khẩu');
    expect(find.text('Mã không hợp lệ hoặc hết hạn.'), findsOneWidget);
    expect(find.text('NewPassword123'), findsNWidgets(2));
    repository.resetFails = false;
    await press(tester, 'Đặt lại mật khẩu');
    expect(find.text('Quay lại đăng nhập'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'Changing password validates current, new and confirmation and returns success',
    (tester) async {
      final repository = FakePasswords();
      bool completed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: PasswordPage(
            changePassword: true,
            repository: repository,
            onComplete: () => completed = true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await press(tester, 'Đổi mật khẩu');
      expect(repository.changes, 0);
      await fill(tester, 'password-current', 'OldPassword123');
      await fill(tester, 'password-new', 'OldPassword123');
      await fill(tester, 'password-confirm', 'OldPassword123');
      await press(tester, 'Đổi mật khẩu');
      expect(repository.changes, 0);
      await fill(tester, 'password-new', ' NewPassword123 ');
      await fill(tester, 'password-confirm', ' NewPassword123 ');
      repository.changeFails = true;
      await press(tester, 'Đổi mật khẩu');
      expect(completed, false);
      expect(find.text('Mật khẩu hiện tại không đúng.'), findsOneWidget);
      repository.changeFails = false;
      await press(tester, 'Đổi mật khẩu');
      expect(completed, true);
      expect(repository.current, 'OldPassword123');
      expect(repository.password, ' NewPassword123 ');
    },
  );

  testWidgets(
    'Change success pops pushed page instead of being blocked by busy state',
    (tester) async {
      final navigator = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigator,
          home: const Scaffold(body: Text('Profile')),
        ),
      );
      final result = navigator.currentState!.push<bool>(
        MaterialPageRoute(
          builder: (_) =>
              PasswordPage(changePassword: true, repository: FakePasswords()),
        ),
      );
      await tester.pumpAndSettle();
      await fill(tester, 'password-current', 'OldPassword123');
      await fill(tester, 'password-new', 'NewPassword123');
      await fill(tester, 'password-confirm', 'NewPassword123');
      await press(tester, 'Đổi mật khẩu');
      expect(find.text('Profile'), findsOneWidget);
      expect(await result, true);
      expect(find.text('Profile'), findsOneWidget);
    },
  );

  testWidgets(
    'Small dark form with enlarged text supports OTP and long password validation',
    (tester) async {
      final repository = FakePasswords();
      await open(tester, repository, width: 320);
      await fill(tester, 'password-email', 'member@example.com');
      await press(tester, 'Gửi mã OTP');
      await fill(tester, 'password-otp', '123456');
      await fill(tester, 'password-new', 'ắ' * 25);
      await fill(tester, 'password-confirm', 'ắ' * 25);
      await press(tester, 'Đặt lại mật khẩu');
      expect(repository.resets, 0);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
