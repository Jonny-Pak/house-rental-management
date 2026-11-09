import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/map/presentation/pages/listing_map_page.dart';
import 'package:frontend/features/listing/data/models/listing_model.dart';
import 'package:frontend/features/listing/data/repositories/listing_repository.dart';

class MapListings extends ListingRepository {
  MapListings() : super(ApiClient());
  int loads = 0;
  final listing = Listing(
    id: 1,
    title: 'Nhà cho thuê gần trung tâm',
    address: 'Nguyễn Bình, TP.HCM',
    rentPrice: 7500000,
    areaSqm: 30,
    latitude: 10.7769,
    longitude: 106.7009,
    approvalStatus: 'APPROVED',
  );
  @override
  Future<List<Listing>> fetchApprovedListings() async {
    loads++;
    return [listing];
  }

  @override
  Future<Listing> fetchDetail(int id) async => listing;
}

void main() {
  testWidgets('Map supports home markers, searching and opening the listing', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = MapListings();
    await tester.pumpWidget(
      MaterialApp(home: ListingMapPage(repository: repository)),
    );
    await tester.pumpAndSettle();
    expect(find.text('1 tin phù hợp trên bản đồ'), findsOneWidget);
    expect(find.text('7,5 tr'), findsNothing);
    expect(find.byKey(const ValueKey('map-listing-1')), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'khong co');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('map-listing-1')), findsNothing);
    await tester.tap(find.byTooltip('Xóa từ khóa'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('map-listing-1')));
    await tester.pumpAndSettle();
    expect(find.text('Nguyễn Bình, TP.HCM'), findsOneWidget);
    await tester.tap(find.text('Xem chi tiết'));
    await tester.pumpAndSettle();
    expect(find.text('Chi tiết tin cho thuê'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'Map and preview adapt to large text on narrow and wide screens',
    (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      for (final width in [320.0, 1440.0]) {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.binding.setSurfaceSize(Size(width, 800));
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(2)),
              child: child!,
            ),
            home: ListingMapPage(repository: MapListings()),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('map-listing-1')));
        await tester.pumpAndSettle();
        expect(find.text('Xem chi tiết'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
