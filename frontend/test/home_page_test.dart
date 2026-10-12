import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:frontend/features/home/presentation/pages/home_page.dart';
import 'package:frontend/features/home/presentation/pages/main_page.dart';
import 'package:frontend/features/user/data/models/user_profile.dart';
import 'package:frontend/features/user/data/repositories/user_repository.dart';

class _ProfileRepository implements UserRepository {
  @override
  Future<UserProfile> getProfile() async => const UserProfile(
    id: 1,
    fullName: 'Ngọc Thuận',
    email: 'thuan@example.com',
    role: 'USER',
  );
  @override
  Future<UserProfile> updateAvatar(String url) => getProfile();
  @override
  Future<String> uploadImage(XFile file) async => '';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final symbols =
        FontLoader('packages/material_symbols_icons/MaterialSymbolsOutlined')
          ..addFont(
            rootBundle.load(
              'packages/material_symbols_icons/lib/fonts/MaterialSymbolsOutlined.ttf',
            ),
          );
    await symbols.load();
    if (Platform.environment['RENDER_HOME_PREVIEW'] == 'true') {
      final bytes = await File('C:/Windows/Fonts/segoeui.ttf').readAsBytes();
      final loader = FontLoader('HomePreview')
        ..addFont(Future.value(ByteData.sublistView(bytes)));
      await loader.load();
    }
  });
  testWidgets('Home scales to small screens and exposes all primary actions', (
    tester,
  ) async {
    for (final width in [320.0, 430.0, 600.0]) {
      await tester.binding.setSurfaceSize(Size(width, 860));
      await tester.pumpWidget(const MaterialApp(home: HomePage()));
      await tester.pump();
      expect(find.text('Đăng Tin'), findsOneWidget);
      expect(find.text('Bản Đồ'), findsOneWidget);
      expect(find.text('Quản Lý\nTin Đăng'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('Menu and notification buttons invoke shell navigation', (
    tester,
  ) async {
    var menuOpened = false;
    int? tab;
    await tester.pumpWidget(
      MaterialApp(
        home: HomePage(
          onMenu: () => menuOpened = true,
          onTabSelected: (value) => tab = value,
        ),
      ),
    );
    await tester.tap(find.byTooltip('Mở menu'));
    expect(menuOpened, isTrue);
    await tester.tap(find.byTooltip('Thông báo'));
    expect(tab, 3);
    await tester.tap(find.text('Quản Lý\nTin Đăng'));
    expect(tab, 2);
  });

  testWidgets('Bottom bar hides in the listing flow and returns after back', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 860));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(home: MainPage(userRepository: _ProfileRepository())),
    );
    await tester.pumpAndSettle();
    expect(find.byTooltip('Trang chủ'), findsOneWidget);
    await tester.tap(find.text('Đăng Tin'));
    await tester.pumpAndSettle();
    expect(find.text('Đăng tin mới'), findsOneWidget);
    expect(find.byTooltip('Trang chủ'), findsNothing);
    final context = tester.element(find.text('Đăng tin mới'));
    Navigator.of(context).pop();
    await tester.pumpAndSettle();
    expect(find.byTooltip('Trang chủ'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Google icons render in a home preview with the bottom navigation',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 860));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final preview = Platform.environment['RENDER_HOME_PREVIEW'] == 'true';
      final boundaryKey = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: boundaryKey,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              useMaterial3: true,
              fontFamily: preview ? 'HomePreview' : null,
              colorSchemeSeed: const Color(0xFFFF751B),
            ),
            home: MainPage(userRepository: _ProfileRepository()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byTooltip('Trang chủ'), findsOneWidget);
      expect(find.byTooltip('Tài khoản'), findsOneWidget);
      expect(tester.takeException(), isNull);
      if (preview) {
        await tester.runAsync(() async {
          final boundary =
              boundaryKey.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          final image = await boundary.toImage(pixelRatio: 2);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final output = File('build/home-preview.png');
          await output.parent.create(recursive: true);
          await output.writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
    },
  );
}
