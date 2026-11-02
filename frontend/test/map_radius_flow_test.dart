import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:frontend/features/listing/data/models/listing_filter.dart';
import 'package:frontend/features/map/presentation/pages/listing_map_page.dart';

import 'nearby_search_test.dart' show NearbyRepository, Locations;

class DelayedLocations extends Locations {
  final pending = Completer<LatLng>();
  @override
  Future<LatLng> current() => pending.future;
}

void main() {
  test('Changing radius preserves other filters and clearing it resets nearest sort', () {
    const filter = ListingFilter(
      query: 'phòng',
      areaId: 6,
      listingType: 'BOARDING_ROOM',
      maxPrice: 5000000,
    );
    final nearby = filter.withRadius(
      center: const LatLng(10.78, 106.7),
      centerName: 'Trường học',
      radiusKm: 3,
    );
    expect(nearby.query, filter.query);
    expect(nearby.areaId, 6);
    expect(nearby.maxPrice, 5000000);
    expect(nearby.listingType, 'BOARDING_ROOM');
    expect(nearby.sort, 'nearest');
    final cleared = nearby.withRadius();
    expect(cleared.hasRadius, false);
    expect(cleared.center, isNull);
    expect(cleared.sort, 'newest');
    expect(cleared.maxPrice, 5000000);
  });
  testWidgets('Clearing filters ignores a late GPS result', (tester) async {
    final locations = DelayedLocations();
    await tester.pumpWidget(
      MaterialApp(
        home: ListingMapPage(
          repository: NearbyRepository(),
          locationService: locations,
          initialFilter: const ListingFilter(
            center: LatLng(10.78, 106.7),
            radiusKm: 3,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Tìm quanh vị trí hiện tại'));
    await tester.pump();
    await tester.tap(find.text('Xóa bộ lọc'));
    await tester.pump();
    locations.pending.complete(const LatLng(10.79, 106.7));
    await tester.pumpAndSettle();
    expect(find.byType(CircleLayer), findsNothing);
    expect(find.text('Tìm theo bán kính'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets(
    'Map directly enables radius, searches GPS, changes radius and clears it',
    (tester) async {
      final repository = NearbyRepository();
      await tester.pumpWidget(
        MaterialApp(
          home: ListingMapPage(
            repository: repository,
            locationService: Locations(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tìm theo bán kính'));
      await tester.pumpAndSettle();
      expect(repository.nearbyCalls, 1);
      expect(
        tester
            .widget<CircleLayer>(find.byType(CircleLayer))
            .circles
            .single
            .radius,
        3000,
      );
      await tester.tap(find.byTooltip('Tìm quanh vị trí hiện tại'));
      await tester.pumpAndSettle();
      expect(find.text('2 tin phù hợp trên bản đồ'), findsOneWidget);
      final before = repository.nearbyCalls;
      await tester.drag(
        find.byKey(const ValueKey('map-radius-slider')),
        const Offset(100, 0),
      );
      await tester.pumpAndSettle();
      expect(repository.nearbyCalls, greaterThan(before));
      expect(
        tester
            .widget<CircleLayer>(find.byType(CircleLayer))
            .circles
            .single
            .radius,
        greaterThan(3000),
      );
      await tester.tap(find.byTooltip('Tắt tìm theo bán kính'));
      await tester.pumpAndSettle();
      expect(find.byType(CircleLayer), findsNothing);
      expect(find.text('1 tin phù hợp trên bản đồ'), findsOneWidget);
      expect(find.text('Tìm theo bán kính'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'Address and tapping the rental map change the center without opening another page',
    (tester) async {
      final repository = NearbyRepository();
      await tester.pumpWidget(
        MaterialApp(
          home: ListingMapPage(
            repository: repository,
            locationService: Locations(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tìm theo bán kính'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('map-radius-address')),
        'Đại học',
      );
      await tester.tap(find.byTooltip('Tìm địa điểm trên bản đồ'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Đại học • Chạm bản đồ'), findsOneWidget);
      final before = repository.nearbyCalls;
      await tester.tapAt(
        tester.getCenter(find.byType(FlutterMap)) + const Offset(-50, -30),
      );
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(repository.nearbyCalls, greaterThan(before));
      expect(find.textContaining('Điểm đã chọn trên bản đồ'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'GPS failure preserves radius and narrow enlarged controls support retry',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final locations = Locations()..fail = true;
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.6)),
            child: child!,
          ),
          home: ListingMapPage(
            repository: NearbyRepository(),
            locationService: locations,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tìm theo bán kính'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Tìm quanh vị trí hiện tại'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Không lấy được vị trí'), findsOneWidget);
      expect(find.byType(CircleLayer), findsOneWidget);
      locations.fail = false;
      await tester.tap(find.byTooltip('Tìm quanh vị trí hiện tại'));
      await tester.pumpAndSettle();
      expect(find.text('2 tin phù hợp trên bản đồ'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
