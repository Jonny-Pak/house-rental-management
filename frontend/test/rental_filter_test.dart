import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/listing/data/models/listing_filter.dart';
import 'package:frontend/features/listing/data/models/listing_model.dart';
import 'package:frontend/features/listing/data/repositories/listing_repository.dart';
import 'package:frontend/features/listing/presentation/pages/listing_browse_page.dart';
import 'package:frontend/features/listing/presentation/widgets/listing_filter_bar.dart';

import 'area_selector_test.dart' show FakeAreas;

Listing listing(
  int id, {
  double price = 3000000,
  double area = 25,
  int ward = 10,
  String type = 'BOARDING_ROOM',
  String status = 'APPROVED',
  String rental = 'AVAILABLE',
}) => Listing(
  id: id,
  title: 'Phòng thoáng $id',
  address: 'Phường Sài Gòn, TP.HCM',
  description: 'Có ban công',
  areaId: ward,
  approvalStatus: status,
  rentalStatus: rental,
  listingType: type,
  rentPrice: price,
  areaSqm: area,
);

class SearchRepository extends ListingRepository {
  SearchRepository() : super(ApiClient());
  @override
  Future<List<Listing>> fetchApprovedListings() async => [
    listing(1),
    listing(2, price: 5000000, area: 40),
  ];
}

void main() {
  test('Combined filters use inclusive bounds and Vietnamese search without accents', () {
    final filter = ListingFilter(
      query: 'sai gon ban cong',
      areaId: 10,
      listingType: 'BOARDING_ROOM',
      minPrice: 3000000,
      maxPrice: 3000000,
      minArea: 25,
      maxArea: 25,
    );
    expect(
      filter
          .apply([
            listing(1),
            listing(2, ward: 11),
            listing(3, type: 'WHOLE_HOUSE'),
            listing(4, price: 3000001),
          ])
          .map((l) => l.id),
      [1],
    );
    expect(const ListingFilter(query: 'khong co').apply([listing(1)]), isEmpty);
  });
  test(
    'Only approved available listings are visible; sort is deterministic',
    () {
      final items = [
        listing(1),
        listing(2, price: 2000000),
        listing(3, status: 'PENDING'),
        listing(4, rental: 'RENTED'),
        listing(5, rental: 'HIDDEN'),
        listing(6, rental: 'DELETED'),
      ];
      expect(
        const ListingFilter(sort: 'priceAsc').apply(items).map((l) => l.id),
        [2, 1],
      );
      expect(
        const ListingFilter(sort: 'priceDesc').apply(items).map((l) => l.id),
        [1, 2],
      );
      expect(
        const ListingFilter().apply([listing(1), listing(2)]).map((l) => l.id),
        [2, 1],
      );
    },
  );
  test('Invalid ranges and non-finite numbers are rejected', () {
    expect(
      const ListingFilter(minPrice: 4000000, maxPrice: 3000000).validationError,
      isNotNull,
    );
    expect(
      const ListingFilter(minArea: 40, maxArea: 20).validationError,
      isNotNull,
    );
    expect(
      const ListingFilter(minArea: double.infinity).validationError,
      isNotNull,
    );
    expect(const ListingFilter(minPrice: -1).validationError, isNotNull);
    expect(
      const ListingFilter(minPrice: 0, maxPrice: 0).validationError,
      isNull,
    );
  });
  testWidgets(
    'Rental cards and search adapt to narrow screens and large text',
    (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      for (final width in [320.0, 800.0, 1440.0]) {
        await tester.binding.setSurfaceSize(Size(width, 850));
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(2)),
              child: child!,
            ),
            home: ListingBrowsePage(
              title: 'Thuê nhà',
              repository: SearchRepository(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.text('Phòng thoáng 1'),
          180,
          scrollable: find.byType(Scrollable).last,
        );
        await tester.pumpAndSettle();
        expect(find.byTooltip('Bộ lọc'), findsOneWidget);
        expect(find.byTooltip('Xem trên bản đồ'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets('Search updates results, reset clears query and filters', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ListingBrowsePage(
          title: 'Tìm nhà',
          repository: SearchRepository(),
          initialFilter: const ListingFilter(minPrice: 4000000),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Phòng thoáng 2'), findsOneWidget);
    expect(find.text('Phòng thoáng 1'), findsNothing);
    await tester.enterText(find.byType(TextField), 'khong co');
    await tester.pumpAndSettle();
    expect(find.text('0 tin phù hợp'), findsOneWidget);
    await tester.tap(find.text('Xóa bộ lọc'));
    await tester.pumpAndSettle();
    expect(find.text('2 tin phù hợp'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'Filter sheet validates price range and selects a new commune by name',
    (tester) async {
      ListingFilter? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  result = await showModalBottomSheet<ListingFilter>(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => ListingFilterSheet(
                      initial: const ListingFilter(),
                      areas: FakeAreas(),
                    ),
                  );
                },
                child: const Text('Mở lọc'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Mở lọc'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Giá từ'),
        '5000000',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Giá đến'),
        '3000000',
      );
      await tester.tap(find.text('Áp dụng'));
      await tester.pumpAndSettle();
      expect(result, isNull);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Giá đến'),
        '6000000',
      );
      await tester.tap(find.text('Tất cả phường / xã / đặc khu'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Tìm phường / xã / đặc khu'),
        'binh chanh',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Xã Bình Chánh'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Áp dụng'));
      await tester.pumpAndSettle();
      expect(result?.areaId, 11);
      expect(result?.maxPrice, 6000000);
      expect(tester.takeException(), isNull);
    },
  );
}
