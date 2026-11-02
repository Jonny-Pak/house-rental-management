import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kite_ui/shadcn.dart';
import 'package:frontend/app/admin/auth/session.dart';
import 'package:frontend/app/admin/router/routes.dart';
import 'package:frontend/app/admin/theme/app_theme.dart';
import 'package:frontend/features/admin/presentation/screens/auth/auth_screens.dart';

class MemorySignIn extends SessionController {
  int calls = 0;
  String? email, password;
  final pending = Completer<void>();
  @override
  SessionUser? build() => null;
  @override
  Future<void> signIn({required String email, required String password}) async {
    calls++;
    this.email = email;
    this.password = password;
    await pending.future;
  }
}

Future<void> open(
  WidgetTester tester,
  MemorySignIn session, {
  double width = 1200,
  double scale = 1,
}) async {
  await tester.binding.setSurfaceSize(Size(width, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final router = GoRouter(
    initialLocation: R.signIn,
    routes: [
      GoRoute(path: R.signIn, builder: (_, _) => const SignInScreen()),
      GoRoute(
        path: R.forgot,
        builder: (_, _) => const Scaffold(body: Text('Khôi phục mật khẩu')),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [sessionProvider.overrideWith(() => session)],
      child: ShadApp.router(
        theme: const ThemeState().data(Brightness.light),
        routerConfig: router,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> press(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.text(text));
  await tester.pumpAndSettle();
  await tester.tap(find.text(text));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'Vietnamese login validates fields and prevents duplicate submission',
    (tester) async {
      final session = MemorySignIn();
      await open(tester, session);
      expect(find.text('No account? Create one'), findsNothing);
      expect(find.text('Sign in'), findsNothing);
      await press(tester, 'Đăng nhập');
      expect(find.text('Vui lòng nhập địa chỉ email hợp lệ.'), findsOneWidget);
      await tester.enterText(
        find.byType(EditableText).first,
        ' admin@example.com ',
      );
      await press(tester, 'Đăng nhập');
      expect(find.text('Vui lòng nhập mật khẩu.'), findsOneWidget);
      await tester.enterText(find.byType(EditableText).last, 'Matkhau123');
      await press(tester, 'Đăng nhập');
      expect(session.calls, 1);
      expect(session.email, 'admin@example.com');
      expect(session.password, 'Matkhau123');
      expect(find.text('Đang đăng nhập…'), findsOneWidget);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(session.calls, 1);
      session.pending.complete();
      await tester.pumpAndSettle();
      expect(find.text('Đăng nhập'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'Narrow enlarged login keeps form and password recovery accessible',
    (tester) async {
      await open(tester, MemorySignIn(), width: 320, scale: 1.5);
      expect(find.text('Rental Admin'), findsOneWidget);
      expect(
        find.text('Quản trị tập trung.\nVận hành hiệu quả.'),
        findsNothing,
      );
      await press(tester, 'Quên mật khẩu?');
      expect(find.text('Khôi phục mật khẩu'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
