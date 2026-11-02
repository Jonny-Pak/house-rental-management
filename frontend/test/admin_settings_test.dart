import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kite_ui/shadcn.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/app/admin/auth/session.dart';
import 'package:frontend/app/admin/router/routes.dart';
import 'package:frontend/app/admin/theme/app_theme.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/admin/presentation/screens/system/settings_screen.dart';
import 'package:frontend/features/user/data/repositories/user_repository.dart';
import 'package:frontend/features/user/data/datasources/user_remote_data_source.dart';
import 'package:frontend/features/user/data/models/user_profile.dart';

import 'password_flow_test.dart' show FakePasswords;

class MemoryAccount extends UserRepositoryImpl {
  MemoryAccount() : super(UserRemoteDataSourceImpl(ApiClient()));
  bool fail = false;
  int loads = 0;
  @override
  Future<UserProfile> getProfile() async {
    loads++;
    if (fail) throw StateError('offline');
    return const UserProfile(
      id: 1,
      fullName: 'Quản trị thử',
      email: 'admin@example.com',
      phoneNumber: '0901234567',
      role: 'ADMIN',
      status: 'ACTIVE',
    );
  }
}

class SettingsSession extends SessionController {
  @override
  SessionUser? build() =>
      const SessionUser(name: 'Tên phiên cũ', email: 'admin@example.com');
}

Future<ProviderContainer> open(
  WidgetTester tester,
  MemoryAccount account, {
  FakePasswords? passwords,
  double width = 1360,
  double scale = 1,
}) async {
  SharedPreferences.setMockInitialValues({
    'access_token': 'test-token',
    ThemeController.modeKey: 'light',
  });
  await tester.binding.setSurfaceSize(Size(width, 1100));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final container = ProviderContainer(
    overrides: [sessionProvider.overrideWith(SettingsSession.new)],
  );
  final refresh = ValueNotifier(0);
  final subscription = container.listen(
    sessionProvider,
    (_, _) => refresh.value++,
  );
  final router = GoRouter(
    initialLocation: R.settings,
    refreshListenable: refresh,
    redirect: (_, state) =>
        container.read(sessionProvider) == null &&
            state.matchedLocation != R.signIn
        ? R.signIn
        : null,
    routes: [
      GoRoute(
        path: R.settings,
        builder: (_, _) => Scaffold(
          body: SettingsScreen(
            accountRepository: account,
            passwordRepository: passwords,
          ),
        ),
      ),
      GoRoute(
        path: R.signIn,
        builder: (_, _) => const Scaffold(body: Text('Trang đăng nhập')),
      ),
      for (final path in [R.content, R.areas, R.memberships])
        GoRoute(
          path: path,
          builder: (_, _) => Scaffold(body: Text('Đích $path')),
        ),
    ],
  );
  addTearDown(() {
    subscription.close();
    router.dispose();
    refresh.dispose();
    container.dispose();
  });
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: Consumer(
        builder: (context, ref, _) {
          final theme = ref.watch(themeProvider);
          return ShadApp.router(
            theme: theme.data(Brightness.light),
            darkTheme: theme.data(Brightness.dark),
            themeMode: theme.mode,
            routerConfig: router,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
          );
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

Future<void> press(WidgetTester tester, String text) async {
  final filled = find.widgetWithText(FilledButton, text);
  final outlined = find.widgetWithText(OutlinedButton, text);
  final target = filled.evaluate().isNotEmpty
      ? filled.last
      : outlined.evaluate().isNotEmpty
      ? outlined.last
      : find.text(text).last;
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<void> fill(WidgetTester tester, String key, String text) async {
  final field = find.byKey(ValueKey(key));
  await tester.ensureVisible(field);
  await tester.enterText(field, text);
  await tester.pump();
}

void main() {
  testWidgets(
    'Settings show real profile without demo or system setup sections',
    (tester) async {
      final account = MemoryAccount();
      await open(tester, account);
      expect(account.loads, 1);
      expect(find.text('Quản trị thử'), findsOneWidget);
      expect(find.text('0901234567'), findsOneWidget);
      expect(find.text('Quản trị viên'), findsOneWidget);
      expect(find.textContaining('MockDataProvider'), findsNothing);
      expect(find.text('English'), findsNothing);
      expect(find.text('Accent'), findsNothing);
      expect(find.text('Thiết lập hệ thống'), findsNothing);
      expect(find.text('Nội dung hiển thị'), findsNothing);
    },
  );
  testWidgets(
    'Theme selection applies immediately and persists across provider recreation',
    (tester) async {
      final container = await open(tester, MemoryAccount());
      await tester.tap(find.byKey(const ValueKey('admin-theme-dark')));
      await tester.pumpAndSettle();
      expect(container.read(themeProvider).mode, ThemeMode.dark);
      final preferences = await SharedPreferences.getInstance();
      expect(preferences.getString(ThemeController.modeKey), 'dark');
      expect(
        Theme.of(tester.element(find.byType(SettingsScreen))).brightness,
        Brightness.dark,
      );
      final restored = ProviderContainer();
      addTearDown(restored.dispose);
      restored.read(themeProvider);
      await tester.pumpAndSettle();
      expect(restored.read(themeProvider).mode, ThemeMode.dark);
      await tester.tap(find.byKey(const ValueKey('admin-theme-system')));
      await tester.pumpAndSettle();
      expect(preferences.getString(ThemeController.modeKey), 'system');
    },
  );
  testWidgets(
    'Narrow enlarged settings retry account loading and support dark mode',
    (tester) async {
      final account = MemoryAccount()..fail = true;
      await open(tester, account, width: 320, scale: 1.5);
      expect(
        find.text('Chưa tải được thông tin tài khoản. Vui lòng thử lại.'),
        findsOneWidget,
      );
      account.fail = false;
      await press(tester, 'Thử tải lại');
      expect(account.loads, 2);
      expect(find.text('Quản trị thử'), findsOneWidget);
      final dark = find.byKey(const ValueKey('admin-theme-dark'));
      await tester.ensureVisible(dark);
      await tester.tap(dark);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'Logout cancellation preserves session and confirmation clears token and redirects',
    (tester) async {
      final container = await open(tester, MemoryAccount());
      await press(tester, 'Đăng xuất');
      await press(tester, 'Hủy');
      expect(container.read(sessionProvider), isNotNull);
      expect(
        (await SharedPreferences.getInstance()).getString('access_token'),
        'test-token',
      );
      await press(tester, 'Đăng xuất');
      await press(tester, 'Đăng xuất');
      expect(container.read(sessionProvider), isNull);
      expect(
        (await SharedPreferences.getInstance()).getString('access_token'),
        isNull,
      );
      expect(find.text('Trang đăng nhập'), findsOneWidget);
    },
  );
  testWidgets(
    'Successful password change signs Admin out while failure keeps the session',
    (tester) async {
      final passwords = FakePasswords()..changeFails = true;
      final container = await open(
        tester,
        MemoryAccount(),
        passwords: passwords,
      );
      await press(tester, 'Đổi mật khẩu');
      await fill(tester, 'password-current', 'OldPassword123');
      await fill(tester, 'password-new', 'NewPassword123');
      await fill(tester, 'password-confirm', 'NewPassword123');
      await press(tester, 'Đổi mật khẩu');
      expect(container.read(sessionProvider), isNotNull);
      expect(find.text('Mật khẩu hiện tại không đúng.'), findsOneWidget);
      passwords.changeFails = false;
      await press(tester, 'Đổi mật khẩu');
      expect(passwords.changes, 2);
      expect(container.read(sessionProvider), isNull);
      expect(find.text('Trang đăng nhập'), findsOneWidget);
    },
  );
}
