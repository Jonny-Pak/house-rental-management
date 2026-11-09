import 'package:flutter/material.dart';
import 'package:frontend/features/listing/presentation/pages/listing_preview_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/amenity/data/amenity_model.dart';
import 'package:frontend/features/amenity/presentation/amenity_selector.dart';
import 'package:frontend/features/amenity/presentation/amenity_chips.dart';
import 'package:frontend/features/listing/data/models/listing_model.dart';
import 'package:frontend/features/listing/presentation/cubit/create_listing_cubit.dart';

import 'amenity_fixture.dart';

void main() {
  testWidgets(
    'Member selects optional items and a failed reload preserves selection',
    (tester) async {
      final repository = MemoryAmenities()..failLoad = true;
      List<Amenity> selected = [];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => SingleChildScrollView(
                child: AmenitySelector(
                  repository: repository,
                  selected: selected,
                  onChanged: (items) => setState(() => selected = items),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Chưa tải được danh mục'), findsOneWidget);
      repository.failLoad = false;
      await tester.tap(find.text('Tải lại danh mục'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('amenity-2')));
      await tester.pumpAndSettle();
      expect(selected.single.id, 2);
      await tester.tap(find.byKey(const ValueKey('amenity-2')));
      await tester.pumpAndSettle();
      expect(selected, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Previously selected inactive items can be removed without losing other selections',
    (tester) async {
      final repository = MemoryAmenities();
      repository.rows[1]!['active'] = false;
      List<Amenity> selected = [
        Amenity.fromJson(repository.rows[1]!),
        Amenity.fromJson(repository.rows[2]!),
      ];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => SingleChildScrollView(
                child: AmenitySelector(
                  repository: repository,
                  selected: selected,
                  onChanged: (items) => setState(() => selected = items),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Giường (ngừng sử dụng)'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('amenity-1')));
      await tester.pumpAndSettle();
      expect(selected.single.id, 2);
      expect(find.byKey(const ValueKey('amenity-1')), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Listing model and draft preserve the selected names for preview and details',
    (tester) async {
      final listing = Listing.fromJson({
        'id': 1,
        'amenities': [
          {'id': 9, 'name': 'Wi-Fi', 'category': 'UTILITY', 'active': false},
        ],
      });
      final cubit = CreateListingCubit();
      cubit.updateAmenities(listing.amenities);
      cubit.updateFurnitureStatus('BASIC');
      expect(cubit.state.amenities.single.name, 'Wi-Fi');
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: AmenityChips(items: cubit.state.amenities)),
        ),
      );
      expect(find.text('Wi-Fi'), findsOneWidget);
      expect(cubit.state.amenities.single.active, isFalse);
      await cubit.close();
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('Optional amenity names appear in the actual preview page', (
    tester,
  ) async {
    final cubit = CreateListingCubit();
    cubit.updateAmenities(const [
      Amenity(id: 9, name: 'Wi-Fi', category: 'UTILITY'),
    ]);
    await tester.pumpWidget(
      MaterialApp(home: ListingPreviewPage(state: cubit.state)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Wi-Fi'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await cubit.close();
  });

  testWidgets(
    'Catalog chips handle long names and large text on a small screen',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final repository = MemoryAmenities();
      repository.rows[2]!['name'] = 'Khu vực để xe có camera an ninh và bảo vệ';
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: Scaffold(
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: AmenitySelector(
                  repository: repository,
                  selected: const [],
                  onChanged: (_) {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
}
