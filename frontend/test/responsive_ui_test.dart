import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:frontend/app/app_launcher.dart';
import 'package:frontend/core/layout/app_layout.dart';
import 'package:frontend/features/auth/presentation/pages/login_page.dart';
import 'package:frontend/features/home/presentation/pages/main_page.dart';
import 'package:frontend/features/home/presentation/pages/home_page.dart';
import 'package:frontend/features/home/presentation/widgets/home_feature_icon.dart';
import 'package:frontend/features/user/data/models/user_profile.dart';
import 'package:frontend/features/user/data/repositories/user_repository.dart';

class TestProfileRepository implements UserRepository {
  int loads = 0;
  @override
  Future<UserProfile> getProfile() async {
    loads++;
    return const UserProfile(
      id: 1,
      fullName: 'Người dùng thử',
      email: 'tenant@example.com',
    );
  }

  @override
  Future<UserProfile> updateAvatar(String url) => getProfile();
  @override
  Future<String> uploadImage(XFile file) async => '';
}

void main() {
  testWidgets(
    'Navigation adapts while keeping the active tab and profile state',
    (tester) async {
      final repository = TestProfileRepository();
      await resize(tester, const Size(390, 860));
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        return tester.binding.setSurfaceSize(null);
      });
      await tester.pumpWidget(
        MaterialApp(home: MainPage(userRepository: repository)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Tài khoản'));
      await tester.pumpAndSettle();
      for (final width in [320.0, 599.0, 600.0, 820.0, 1024.0, 1440.0, 390.0]) {
        await resize(tester, Size(width, 860));
        await tester.pumpAndSettle();
        expect(find.text('Người dùng thử'), findsOneWidget);
        if (width >= AppLayout.compact) {
          final rail = tester.widget<NavigationRail>(
            find.byType(NavigationRail),
          );
          expect(rail.selectedIndex, 4);
          expect(rail.extended, width >= AppLayout.expanded);
        } else {
          expect(find.byType(NavigationRail), findsNothing);
          expect(find.byTooltip('Trang chủ'), findsOneWidget);
        }
        expect(tester.takeException(), isNull, reason: "Width: $width");
      }
      expect(repository.loads, 1);
    },
    variant: TargetPlatformVariant({
      TargetPlatform.android,
      TargetPlatform.windows,
    }),
  );

  testWidgets('Resizing inside the listing flow keeps the current route', (
    tester,
  ) async {
    await resize(tester, const Size(390, 860));
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      return tester.binding.setSurfaceSize(null);
    });
    await tester.pumpWidget(
      MaterialApp(home: MainPage(userRepository: TestProfileRepository())),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Đăng Tin'));
    await tester.pumpAndSettle();
    for (final size in [
      const Size(1440, 900),
      const Size(800, 400),
      const Size(320, 580),
    ]) {
      await resize(tester, size);
      await tester.pumpAndSettle();
      expect(find.text('Đăng tin mới'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
    Navigator.of(tester.element(find.text('Đăng tin mới'))).pop();
    await tester.pumpAndSettle();
    expect(find.text('Đăng Tin'), findsOneWidget);
  });

  testWidgets('Content and cards use the available width', (tester) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      return tester.binding.setSurfaceSize(null);
    });
    for (final width in [320.0, 820.0, 1440.0]) {
      await resize(tester, Size(width, 860));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppContent(
              child: SingleChildScrollView(
                child: ResponsiveCards(
                  children: List.generate(
                    4,
                    (index) => SizedBox(key: ValueKey(index), height: 100),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final first = tester.getRect(find.byKey(const ValueKey(0)));
      final second = tester.getRect(find.byKey(const ValueKey(1)));
      expect(first.width, lessThanOrEqualTo(width));
      expect(first.top == second.top, width >= 820);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('Home supports large text on a narrow screen', (tester) async {
    await resize(tester, const Size(320, 720));
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      return tester.binding.setSurfaceSize(null);
    });
    await tester.pumpWidget(
      MaterialApp(
        scrollBehavior: const AppScrollBehavior(),
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 720),
            textScaler: TextScaler.linear(1.5),
          ),
          child: const HomePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is HomeFeatureIcon && widget.icon == Symbols.home_work,
      ),
      findsWidgets,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'All platforms can choose the user interface and return to the launcher',
    (tester) async {
      await resize(tester, const Size(390, 860));
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        return tester.binding.setSurfaceSize(null);
      });
      await tester.pumpWidget(const AppLauncher());
      await tester.pumpAndSettle();
      expect(find.text('Quản trị viên'), findsOneWidget);
      await tester.tap(find.text('Người dùng'));
      await tester.pumpAndSettle();
      expect(find.byType(LoginPage), findsOneWidget);
      await tester.tap(find.text('Chọn giao diện'));
      await tester.pumpAndSettle();
      expect(find.text('Quản trị viên'), findsOneWidget);
      expect(find.byType(LoginPage), findsNothing);
    },
  );
}

Future<void> resize(WidgetTester tester, Size size) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  await tester.binding.setSurfaceSize(size);
}
