import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/listing/data/models/roommate_info.dart';
import 'package:frontend/features/listing/data/models/listing_model.dart';
import 'package:frontend/features/listing/data/models/listing_filter.dart';
import 'package:frontend/features/listing/presentation/cubit/create_listing_cubit.dart';
import 'package:frontend/features/listing/presentation/pages/create_listing_page.dart';
import 'package:frontend/features/listing/presentation/pages/listing_details_step.dart';
import 'package:frontend/features/listing/presentation/pages/edit_listing_page.dart';
import 'package:frontend/features/listing/presentation/widgets/roommate_form.dart';

import 'package:frontend/features/listing/presentation/widgets/listing_filter_bar.dart';

import 'area_selector_test.dart' show FakeAreas;
import 'listing_flow_test.dart' show FakeListingRepository, draft;

class EditRepository extends FakeListingRepository {
  Map<String, dynamic>? edited;
  @override
  Future<void> updateListing(int id, Map<String, dynamic> data) async {
    edited = data;
  }
}

void main() {
  test(
    'Roommate gender filter includes matching and unrestricted listings',
    () {
      Listing shared(int id, String gender) => Listing(
        id: id,
        title: 'Ở ghép',
        rentPrice: 1500000,
        areaSqm: 25,
        listingType: 'SHARED_ROOM',
        approvalStatus: 'APPROVED',
        details: {'genderPreference': gender},
      );
      const filter = ListingFilter(
        listingType: 'SHARED_ROOM',
        genderPreference: 'FEMALE',
      );
      expect(
        filter
            .apply([shared(1, 'ANY'), shared(2, 'FEMALE'), shared(3, 'MALE')])
            .map((l) => l.id)
            .toSet(),
        {1, 2},
      );
      expect(filter.withQuery('Ở ghép').genderPreference, 'FEMALE');
    },
  );

  testWidgets('Shared filter sheet saves gender and per-person price scope', (
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
                  builder: (_) => ListingFilterSheet(
                    initial: const ListingFilter(listingType: 'SHARED_ROOM'),
                    areas: FakeAreas(),
                  ),
                );
              },
              child: const Text('Lọc ở ghép'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Lọc ở ghép'));
    await tester.pumpAndSettle();
    final gender = find.widgetWithText(
      DropdownButtonFormField<String>,
      'Giới tính người ở ghép',
    );
    await tester.ensureVisible(gender);
    await tester.pumpAndSettle();
    await tester.tap(gender);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nữ').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Áp dụng'));
    await tester.pumpAndSettle();
    expect(result!.genderPreference, 'FEMALE');
    expect(result!.listingType, 'SHARED_ROOM');
    expect(tester.takeException(), isNull);
  });

  test(
    'Shared submission carries roommate details and per-person rent',
    () async {
      final repository = FakeListingRepository();
      final cubit = draft(repository)..updatePropertyType('SHARED_ROOM');
      cubit.updateRoommateInfo(
        const RoommateInfo(
          currentOccupants: 1,
          maxOccupants: 3,
          genderPreference: 'FEMALE',
          allowPets: true,
          roommateRequirements: 'Giữ vệ sinh',
        ),
      );
      expect(await cubit.submit(), isTrue);
      expect(repository.payload!['listingType'], 'SHARED_ROOM');
      expect(repository.payload!['maxOccupants'], 3);
      expect(repository.payload!['genderPreference'], 'FEMALE');
      expect(repository.payload!['allowPets'], isTrue);
      expect(repository.payload!['allowSmoking'], isFalse);
      expect(repository.payload!['roommateRequirements'], 'Giữ vệ sinh');
      expect(repository.payload!['rentPrice'], 3000000);
      await cubit.close();
    },
  );

  test('Full occupancy stops submission before uploading', () async {
    final repository = FakeListingRepository();
    final cubit = draft(repository)..updatePropertyType('SHARED_ROOM');
    cubit.updateRoommateInfo(
      const RoommateInfo(currentOccupants: 2, maxOccupants: 2),
    );
    expect(await cubit.submit(), isFalse);
    expect(repository.creates, 0);
    await cubit.close();
  });

  test('Shared filters keep only approved available roommate listings', () {
    Listing item(int id, String type, String status, String rental) => Listing(
      id: id,
      title: 'Ở ghép',
      rentPrice: 1500000,
      areaSqm: 25,
      listingType: type,
      approvalStatus: status,
      rentalStatus: rental,
      details: const {'roommateRequirements': 'Giữ vệ sinh'},
    );
    final items = [
      item(1, 'SHARED_ROOM', 'APPROVED', 'AVAILABLE'),
      item(2, 'SHARED_ROOM', 'PENDING', 'AVAILABLE'),
      item(3, 'BOARDING_ROOM', 'APPROVED', 'AVAILABLE'),
      item(4, 'SHARED_ROOM', 'APPROVED', 'HIDDEN'),
    ];
    expect(
      const ListingFilter(
        listingType: 'SHARED_ROOM',
        query: 've sinh',
      ).apply(items).map((l) => l.id),
      [1],
    );
    expect(listingRentUnit('SHARED_ROOM'), 'người/tháng');
  });

  testWidgets('Create flow exposes shared-room type and continues to map', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MaterialApp(home: CreateListingPage()));
    await tester.pumpAndSettle();
    final target = find.text('Tìm người ở ghép');
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
    final cubit = tester.element(target).read<CreateListingCubit>();
    await tester.tap(target);
    await tester.pumpAndSettle();
    expect(cubit.state.propertyType, 'SHARED_ROOM');
    expect(find.text('Vị trí & diện tích'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'Roommate form retains edits and blocks full rooms on small screens',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 850));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final cubit = CreateListingCubit()
        ..updatePropertyType('SHARED_ROOM')
        ..updateFurnitureStatus('BASIC');
      addTearDown(cubit.close);
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: cubit,
            child: ListingDetailsStep(onBack: () {}, onNext: () {}),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byTooltip('Tăng Người đang ở'),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Tăng Người đang ở'));
      await tester.pumpAndSettle();
      expect(cubit.state.roommateInfo.isValid, isFalse);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      await tester.tap(find.byTooltip('Giảm Người đang ở'));
      await tester.pumpAndSettle();
      final requirements = find.byKey(const ValueKey('roommate-requirements'));
      await tester.ensureVisible(requirements);
      await tester.pumpAndSettle();
      await tester.enterText(requirements, 'Ngủ sớm, giữ vệ sinh');
      await tester.pumpAndSettle();
      expect(
        cubit.state.roommateInfo.roommateRequirements,
        'Ngủ sớm, giữ vệ sinh',
      );
      expect(cubit.state.roommateInfo.isValid, isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Editing a shared listing sends roommate changes for moderation',
    (tester) async {
      final repository = EditRepository();
      final listing = Listing(
        id: 1,
        title: 'Ở ghép',
        description: 'Phòng thoáng',
        address: 'TP.HCM',
        rentPrice: 1500000,
        areaSqm: 25,
        areaId: 6,
        latitude: 10.78,
        longitude: 106.7,
        listingType: 'SHARED_ROOM',
        imageUrls: const ['https://example.com/shared.jpg'],
        details: const {
          'currentOccupants': 1,
          'maxOccupants': 3,
          'genderPreference': 'ANY',
          'allowPets': true,
        },
      );
      await tester.pumpWidget(
        MaterialApp(
          home: EditListingPage(listing: listing, repository: repository),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byTooltip('Tăng Sức chứa tối đa'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Tăng Sức chứa tối đa'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Lưu và gửi duyệt lại'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lưu và gửi duyệt lại'));
      await tester.pumpAndSettle();
      expect(repository.edited!['maxOccupants'], 4);
      expect(repository.edited!['allowPets'], isTrue);
      expect(repository.edited!['listingType'], 'SHARED_ROOM');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Roommate form supports large text', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
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
              padding: const EdgeInsets.all(20),
              child: RoommateForm(
                value: const RoommateInfo(),
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
