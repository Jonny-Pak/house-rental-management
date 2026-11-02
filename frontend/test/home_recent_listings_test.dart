import 'home_listings_fixture.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/home/presentation/pages/main_page.dart';
import 'package:frontend/features/home/presentation/widgets/home_recent_listings.dart';
import 'package:frontend/features/listing/presentation/pages/listing_detail_page.dart';

import 'notification_test.dart' show MemoryNotifications;
import 'responsive_ui_test.dart' show TestProfileRepository;

Future<void> open(
  WidgetTester tester,
  HomeListings repository, {
  double scale = 1,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: Scaffold(
        body: SingleChildScrollView(
          child: HomeRecentListings(repository: repository),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'Home loads real listing data and only shows approved available rentals',
    (tester) async {
      final repository = HomeListings();
      await open(tester, repository);
      expect(find.text('Nhà sáng thoáng'), findsOneWidget);
      expect(find.text('Phòng trọ yên tĩnh'), findsOneWidget);
      expect(find.text('Tin chờ duyệt'), findsNothing);
      expect(find.text('5.000.000 đ/tháng'), findsOneWidget);
      expect(find.byIcon(Icons.favorite), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('Favorite saves, preserves state on failure and supports retry', (
    tester,
  ) async {
    final repository = HomeListings();
    await open(tester, repository);
    final heart = find.byKey(const ValueKey('home-favorite-1'));
    await tester.ensureVisible(heart);
    await tester.tap(heart);
    await tester.pumpAndSettle();
    expect(repository.saved.contains(1), true);
    repository.saveFails = true;
    await tester.tap(heart);
    await tester.pumpAndSettle();
    expect(repository.saved.contains(1), true);
    expect(find.textContaining('Chưa lưu được tin'), findsOneWidget);
    repository.saveFails = false;
    await tester.tap(heart);
    await tester.pumpAndSettle();
    expect(repository.saved.contains(1), false);
  });
  testWidgets('Failed load retries and empty state stays usable', (
    tester,
  ) async {
    final repository = HomeListings()..fail = true;
    await open(tester, repository);
    expect(find.text('Chưa tải được tin cho thuê.'), findsOneWidget);
    repository.fail = false;
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(find.text('Nhà sáng thoáng'), findsOneWidget);
    repository.items.clear();
    await tester.pumpWidget(const SizedBox.shrink());
    await open(tester, repository);
    expect(find.text('Chưa có tin cho thuê mới.'), findsOneWidget);
  });
  testWidgets('Rental card opens real details and reloads after returning', (
    tester,
  ) async {
    final repository = HomeListings();
    await open(tester, repository);
    await tester.tap(find.text('Nhà sáng thoáng'));
    await tester.pumpAndSettle();
    expect(find.byType(ListingDetailPage), findsOneWidget);
    Navigator.of(tester.element(find.byType(ListingDetailPage))).pop();
    await tester.pumpAndSettle();
    expect(repository.loads, 2);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Home cards support small screens and large text', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await open(tester, HomeListings(), scale: 2);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'Bottom post button opens creation and back restores the previous tab',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          home: MainPage(
            userRepository: TestProfileRepository(),
            notificationRepository: MemoryNotifications(),
            listingRepository: HomeListings(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Chào bạn, Người dùng thử'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('bottom-nav-2')));
      await tester.pumpAndSettle();
      expect(find.text('Đăng tin mới'), findsOneWidget);
      expect(find.byTooltip('Trang chủ'), findsNothing);
      Navigator.of(tester.element(find.text('Đăng tin mới'))).pop();
      await tester.pumpAndSettle();
      expect(find.byTooltip('Trang chủ'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
