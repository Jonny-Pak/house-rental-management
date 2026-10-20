import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:frontend/features/home/presentation/pages/home_page.dart';
import 'package:frontend/features/home/presentation/pages/main_page.dart';
import 'package:frontend/features/home/presentation/widgets/home_feature_icon.dart';
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
    await tester.ensureVisible(find.text('Quản Lý\nTin Đăng'));
    await tester.tap(find.text('Quản Lý\nTin Đăng'));
    expect(tab, 2);
  });

  testWidgets('Hero dots switch slides and all functions opens the menu', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 860));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MaterialApp(home: HomePage()));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('home-slide-1')));
    await tester.pumpAndSettle();
    expect(find.text('Nhà đẹp\nTrong tầm tay'), findsOneWidget);
    await tester.tap(find.text('Xem tất cả').first);
    await tester.pumpAndSettle();
    expect(find.text('Tất cả chức năng'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Drawer supports navigation and large text on small screens', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final boundary = GlobalKey();
    for (final largeText in [false, true]) {
      await tester.binding.setSurfaceSize(
        largeText ? const Size(320, 640) : const Size(430, 860),
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            fontFamily: Platform.environment['RENDER_HOME_PREVIEW'] == 'true'
                ? 'HomePreview'
                : null,
          ),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(largeText ? 2 : 1)),
            child: child!,
          ),
          home: RepaintBoundary(
            key: boundary,
            child: MainPage(userRepository: _ProfileRepository()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Mở menu'));
      await tester.pumpAndSettle();
      final drawer = find.byType(Drawer);
      expect(
        find.descendant(of: drawer, matching: find.text('Ngọc Thuận')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: drawer, matching: find.text('Đăng xuất')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      if (!largeText && Platform.environment['RENDER_HOME_PREVIEW'] == 'true') {
        await tester.runAsync(() async {
          final render =
              boundary.currentContext!.findRenderObject()
                  as RenderRepaintBoundary;
          final picture = await render.toImage(pixelRatio: 2);
          final bytes = await picture.toByteData(
            format: ui.ImageByteFormat.png,
          );
          await File('build/home-drawer-preview.png')
              .writeAsBytes(bytes!.buffer.asUint8List());
          picture.dispose();
        });
      }
      final notifications = find.descendant(
        of: drawer,
        matching: find.text('Thông báo'),
      );
      await tester.scrollUntilVisible(
        notifications,
        100,
        scrollable: find.descendant(of: drawer, matching: find.byType(Scrollable)),
      );
      await tester.tap(notifications);
      await tester.pumpAndSettle();
      expect(find.text('Thông báo hệ thống'), findsOneWidget);
      expect(find.byType(Drawer), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    }
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
          final context = tester.element(find.byType(HomePage));
          await precacheImage(
            const AssetImage('assets/images/home/townhouse.webp'),
            context,
          );
          await precacheImage(
            const AssetImage('assets/images/home/room.webp'),
            context,
          );
        });
        await tester.pumpAndSettle();
        await tester.binding.setSurfaceSize(const Size(430, 1440));
        await tester.pumpAndSettle();
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
        await tester.binding.setSurfaceSize(const Size(1440, 1000));
        await tester.pumpAndSettle();
        await tester.runAsync(() async {
          final boundary =
              boundaryKey.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          final image = await boundary.toImage(pixelRatio: 1);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await File('build/home-preview-desktop.png')
              .writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
        await tester.binding.setSurfaceSize(const Size(430, 620));
        const icons = [
          ('Đăng tin', Symbols.post_add),
          ('Thuê nhà', Symbols.home_work),
          ('Thuê phòng trọ', Symbols.apartment),
          ('Quản lý tin đăng', Symbols.assignment),
          ('Hợp đồng', Symbols.receipt_long),
          ('Gói dịch vụ', Symbols.payments),
          ('Bản đồ', Symbols.map),
          ('Trợ lý AI', Symbols.smart_toy),
          ('Giới thiệu', Symbols.menu_book),
          ('Quy định', Symbols.gavel),
          ('Hướng dẫn', Symbols.help),
          ('Báo cáo sự cố', Symbols.report),
          ('Liên hệ', Symbols.support_agent),
        ];
        await tester.pumpWidget(
          RepaintBoundary(
            key: boundaryKey,
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: ThemeData(fontFamily: 'HomePreview'),
              home: Scaffold(
                backgroundColor: const Color(0xFFF1F9FC),
                body: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text(
                        'BỘ ICON THUÊ NHÀ',
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF225B75),
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'Nhà ở · Hợp đồng · Dịch vụ · Hỗ trợ',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6D8894),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        runSpacing: 12,
                        children: [
                          for (final entry in icons)
                            SizedBox(
                              width: 92,
                              height: 116,
                              child: Column(
                                children: [
                                  Container(
                                    width: 72,
                                    height: 72,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: const Color(0xFFCDDFE5),
                                      ),
                                    ),
                                    child: HomeFeatureIcon(
                                      icon: entry.$2,
                                      size: 56,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    entry.$1,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      height: 1.2,
                                      color: Color(0xFF225B75),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.runAsync(() async {
          final boundary =
              boundaryKey.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          final image = await boundary.toImage(pixelRatio: 2);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await File('build/home-icons-preview.png')
              .writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
    },
  );
}
