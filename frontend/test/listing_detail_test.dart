import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/listing/data/models/listing_model.dart';
import 'package:frontend/features/listing/data/repositories/listing_repository.dart';
import 'package:frontend/features/listing/presentation/pages/listing_detail_page.dart';
import 'package:frontend/features/listing/presentation/pages/saved_listings_page.dart';

class DetailRepository extends ListingRepository {
  DetailRepository() : super(ApiClient());
  bool saved = false, fail = false, failSave = false;
  String? phone = '0901234567';
  @override
  Future<Listing> fetchDetail(int id) async {
    if (fail) {
      throw DioException(
        requestOptions: RequestOptions(),
        response: Response(requestOptions: RequestOptions(), statusCode: 404),
      );
    }
    return Listing.fromJson({
      'id': id,
      'title': 'Nhà cho thuê tại Sài Gòn',
      'approvalStatus': 'APPROVED',
      'rentPrice': 7500000,
      'areaSqm': 50,
      'address': 'Phường Sài Gòn, TP.HCM',
      'listingType': 'WHOLE_HOUSE',
      'description': 'Nhà thoáng mát',
      'bedrooms': 2,
      'bathrooms': 1,
      'furnitureStatus': 'BASIC',
      'ownerName': 'Chủ nhà Thuan',
      'ownerPhone': phone,
      'latitude': 10.78,
      'longitude': 106.7,
    });
  }

  @override
  Future<List<Listing>> fetchSavedListings() async =>
      saved ? [await fetchDetail(10)] : [];
  @override
  Future<bool> isFavorite(int id) async => saved;
  @override
  Future<void> setFavorite(int id, bool value) async {
    if (failSave) throw Exception('Lỗi lưu tin');
    saved = value;
  }
}

Future<void> showDetail(
  WidgetTester tester,
  DetailRepository repository,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: ListingDetailPage(
        listingId: 10,
        repository: repository,
        mapBuilder: (_) => const ColoredBox(color: Colors.grey),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'Saved cards and empty state support large text and responsive widths',
    (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final repository = DetailRepository()..saved = true;
      for (final width in [320.0, 800.0, 1440.0]) {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.binding.setSurfaceSize(Size(width, 850));
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(2)),
              child: child!,
            ),
            home: SavedListingsPage(repository: repository),
          ),
        );
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.text('50 m²'),
          180,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        expect(find.byTooltip('Bỏ lưu tin'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
      await tester.pumpWidget(const SizedBox.shrink());
      repository.saved = false;
      await tester.binding.setSurfaceSize(const Size(320, 850));
      await tester.pumpWidget(
        MaterialApp(home: SavedListingsPage(repository: repository)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Lưu lại nơi bạn muốn gọi là nhà'), findsOneWidget);
      expect(find.text('Xem khu trọ đã lưu'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Saved listings uses listing favorites and supports removal', (
    tester,
  ) async {
    final repository = DetailRepository()..saved = true;
    await tester.pumpWidget(
      MaterialApp(home: SavedListingsPage(repository: repository)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Nhà cho thuê tại Sài Gòn'), findsOneWidget);
    await tester.tap(find.byTooltip('Bỏ lưu tin'));
    await tester.pumpAndSettle();
    expect(repository.saved, isFalse);
    expect(find.text('Nhà cho thuê tại Sài Gòn'), findsNothing);
  });
  testWidgets('Detail and contact bar fit a narrow phone', (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await showDetail(tester, DetailRepository());
    await tester.drag(find.byType(ListView), const Offset(0, -900));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'Detail shows rental data, contact actions and saves/removes favorites',
    (tester) async {
      final repository = DetailRepository();
      await showDetail(tester, repository);
      expect(find.text('Nhà cho thuê tại Sài Gòn'), findsOneWidget);
      expect(find.text('7.500.000 đ/tháng'), findsOneWidget);
      await tester.tap(find.byTooltip('Lưu tin yêu thích'));
      await tester.pumpAndSettle();
      expect(repository.saved, isTrue);
      expect(find.byTooltip('Bỏ lưu tin'), findsOneWidget);
      await tester.tap(find.byTooltip('Bỏ lưu tin'));
      await tester.pumpAndSettle();
      expect(repository.saved, isFalse);
      await tester.scrollUntilVisible(
        find.text('Liên hệ chủ nhà'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Chủ nhà Thuan'), findsOneWidget);
      expect(find.text('0901234567'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Gọi chủ nhà'),
            )
            .onPressed,
        isNotNull,
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'Unavailable listing hides contact and favorite actions and supports retry',
    (tester) async {
      final repository = DetailRepository()..fail = true;
      await showDetail(tester, repository);
      expect(
        find.text('Tin đăng đã ngừng hiển thị hoặc không còn cho thuê.'),
        findsOneWidget,
      );
      expect(find.text('Gọi chủ nhà'), findsNothing);
      expect(find.byTooltip('Lưu tin yêu thích'), findsNothing);
      repository.fail = false;
      await tester.tap(find.text('Thử lại'));
      await tester.pumpAndSettle();
      expect(find.text('Nhà cho thuê tại Sài Gòn'), findsOneWidget);
    },
  );
  testWidgets(
    'Missing phone disables contact; failed save does not change favorite status',
    (tester) async {
      final repository = DetailRepository()
        ..phone = null
        ..failSave = true;
      await showDetail(tester, repository);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Gọi chủ nhà'),
            )
            .onPressed,
        isNull,
      );
      await tester.tap(find.byTooltip('Lưu tin yêu thích'));
      await tester.pumpAndSettle();
      expect(repository.saved, isFalse);
      expect(find.byTooltip('Lưu tin yêu thích'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
