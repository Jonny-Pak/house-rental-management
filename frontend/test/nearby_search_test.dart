import 'package:flutter_map/flutter_map.dart';
import 'package:frontend/features/map/presentation/pages/listing_map_page.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/listing/data/models/listing_filter.dart';
import 'package:frontend/features/listing/data/models/listing_model.dart';
import 'package:frontend/features/listing/data/repositories/listing_repository.dart';
import 'package:frontend/features/listing/presentation/pages/listing_browse_page.dart';
import 'package:frontend/features/listing/presentation/pages/search_location_page.dart';
import 'package:frontend/features/listing/presentation/widgets/listing_filter_bar.dart';
import 'package:frontend/features/home/presentation/cubit/home_map_cubit.dart';

import 'area_selector_test.dart' show FakeAreas;

Listing room(
  int id,
  double? lat, {
  String status = 'APPROVED',
  double price = 3000000,
}) => Listing(
  id: id,
  title: 'Nhà gần $id',
  rentPrice: price,
  areaSqm: 25,
  latitude: lat,
  longitude: 106.7,
  approvalStatus: status,
);

class NearbyRepository extends ListingRepository {
  NearbyRepository() : super(ApiClient());
  bool fail = false;
  int nearbyCalls = 0;
  @override
  Future<List<Listing>> fetchNearby(
    double latitude,
    double longitude,
    double radiusKm,
  ) async {
    nearbyCalls++;
    if (fail) throw Exception('Mất kết nối');
    return [room(1, 10.78), room(2, 10.79)];
  }

  @override
  Future<List<Listing>> fetchApprovedListings() async => [room(3, 11)];
}

class DelayedRepository extends NearbyRepository {
  final pending = Completer<List<Listing>>();
  @override
  Future<List<Listing>> fetchApprovedListings() => pending.future;
}

class Locations extends SearchLocationService {
  bool fail = false;
  @override
  Future<LatLng> current() async {
    if (fail) throw Exception('GPS denied');
    return const LatLng(10.78, 106.7);
  }

  @override
  Future<LatLng> search(String address) async => const LatLng(10.79, 106.7);
}

void main() {
  const filter = ListingFilter(
    center: LatLng(10.78, 106.7),
    radiusKm: 1.5,
    sort: 'nearest',
  );
  test('Distance in km, inclusive radius, missing coordinates and combined filters', () {
    expect(filter.distanceKm(room(1, 10.78)), 0);
    expect(filter.distanceKm(room(2, 10.79)), closeTo(1.112, .002));
    expect(
      filter
          .apply([
            room(2, 10.79),
            room(1, 10.78),
            room(3, 10.80),
            room(4, null),
            room(5, 10.78, status: 'PENDING'),
          ])
          .map((r) => r.id),
      [1, 2],
    );
    final boundary = filter.distanceKm(room(2, 10.79))!;
    expect(
      ListingFilter(
        center: filter.center,
        radiusKm: boundary,
      ).apply([room(2, 10.79)]),
      hasLength(1),
    );
    expect(
      ListingFilter(
        center: filter.center,
        radiusKm: boundary - .001,
      ).apply([room(2, 10.79)]),
      isEmpty,
    );
    expect(
      ListingFilter(
        center: filter.center,
        radiusKm: 2,
        maxPrice: 2000000,
      ).apply([room(1, 10.78)]),
      isEmpty,
    );
    expect(filter.withQuery('nhà').center, filter.center);
    expect(filter.withQuery('nhà').radiusKm, 1.5);
    expect(filter.distanceKm(room(6, double.nan)), isNull);
    expect(const ListingFilter().apply([room(4, null)]), hasLength(1));
  });
  test('Invalid search values are rejected', () {
    for (final radius in [0.0, -1.0, 51.0, double.nan, double.infinity]) {
      expect(
        ListingFilter(center: filter.center, radiusKm: radius).validationError,
        isNotNull,
      );
    }
    expect(const ListingFilter(radiusKm: 3).validationError, isNotNull);
    expect(const ListingFilter(sort: 'nearest').validationError, isNotNull);
    expect(filter.validationError, isNull);
  });
  test(
    'Map ignores an old request after switching to a radius search',
    () async {
      final repository = DelayedRepository();
      final cubit = HomeMapCubit(repository);
      final old = cubit.fetchApprovedListings();
      cubit.filter = filter;
      await cubit.fetchApprovedListings();
      repository.pending.complete([room(3, 11)]);
      await old;
      expect((cubit.state as HomeMapLoaded).listings.first.id, 1);
      await cubit.close();
    },
  );
  testWidgets('Radius map shows circle and retains center when opening list', (
    tester,
  ) async {
    final repository = NearbyRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: ListingMapPage(repository: repository, initialFilter: filter),
      ),
    );
    await tester.pumpAndSettle();
    final circle = tester.widget<CircleLayer>(find.byType(CircleLayer));
    expect(circle.circles.single.radius, 1500);
    expect(find.byKey(const ValueKey('map-listing-1')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('map-listing-1')));
    await tester.pumpAndSettle();
    expect(find.text('0.00 km • đường chim bay'), findsOneWidget);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Xem danh sách'));
    await tester.pumpAndSettle();
    expect(repository.nearbyCalls, 2);
    expect(find.text('2 tin phù hợp'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets(
    'Address search and manual map selection work on a narrow screen',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(home: SearchLocationPage(service: Locations())),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Đại học');
      await tester.tap(find.byTooltip('Tìm địa chỉ'));
      await tester.pumpAndSettle();
      expect(find.text('10.79000, 106.70000'), findsOneWidget);
      await tester.tapAt(
        tester.getCenter(find.byType(FlutterMap)) + const Offset(40, 40),
      );
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(find.text('Điểm đã chọn trên bản đồ'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'Browse displays distances, network retry and clearing the radius',
    (tester) async {
      final repository = NearbyRepository()..fail = true;
      await tester.pumpWidget(
        MaterialApp(
          home: ListingBrowsePage(
            title: 'Thuê nhà',
            repository: repository,
            initialFilter: filter,
          ),
        ),
      );
      await tester.pumpAndSettle();
      repository.fail = false;
      await tester.tap(find.text('Thử lại'));
      await tester.pumpAndSettle();
      expect(find.text('2 tin phù hợp'), findsOneWidget);
      expect(find.text('0.00 km • đường chim bay'), findsOneWidget);
      await tester.tap(find.text('Xóa bộ lọc'));
      await tester.pumpAndSettle();
      expect(find.text('1 tin phù hợp'), findsOneWidget);
      expect(find.text('Nhà gần 3'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('Filter preserves radius and clearing it resets nearest sort', (
    tester,
  ) async {
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
                  builder: (_) =>
                      ListingFilterSheet(initial: filter, areas: FakeAreas()),
                );
              },
              child: const Text('Mở'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Mở'));
    await tester.pumpAndSettle();
    expect(find.byType(Slider), findsOneWidget);
    await tester.tap(find.byTooltip('Bỏ giới hạn bán kính'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Áp dụng'));
    await tester.pumpAndSettle();
    expect(result!.hasRadius, false);
    expect(result!.sort, 'newest');
  });
  testWidgets(
    'Location picker handles GPS denial, retry and confirming coordinates',
    (tester) async {
      final locations = Locations()..fail = true;
      SearchLocation? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  result = await Navigator.push<SearchLocation>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SearchLocationPage(service: locations),
                    ),
                  );
                },
                child: const Text('Chọn'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Chọn'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Vị trí hiện tại'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Không lấy được vị trí'), findsOneWidget);
      locations.fail = false;
      await tester.tap(find.byTooltip('Vị trí hiện tại'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dùng vị trí này'));
      await tester.pumpAndSettle();
      expect(result!.point.latitude, 10.78);
      expect(result!.name, 'Vị trí hiện tại');
      expect(tester.takeException(), isNull);
    },
  );
}
