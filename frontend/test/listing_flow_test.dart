import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/listing/data/models/listing_model.dart';
import 'package:frontend/features/listing/data/repositories/listing_repository.dart';
import 'package:frontend/features/listing/presentation/cubit/create_listing_cubit.dart';
import 'package:frontend/features/listing/presentation/cubit/create_listing_state.dart';
import 'package:frontend/features/listing/presentation/pages/my_listings_page.dart';

class FakeListingRepository extends ListingRepository {
  FakeListingRepository() : super(ApiClient());
  bool failUpload = false;
  bool failCreate = false;
  int creates = 0;
  Map<String, dynamic>? payload;
  Completer<void>? gate;
  List<Listing> items = [];

  @override
  Future<String> uploadImage(String path) async {
    if (gate != null) await gate!.future;
    if (failUpload) throw Exception('Upload failed');
    return 'https://example.com/$path.jpg';
  }

  @override
  Future<Listing> createListing(Map<String, dynamic> data) async {
    creates++;
    payload = data;
    if (failCreate) throw Exception('Create failed');
    return Listing.fromJson({...data, 'id': 10, 'approvalStatus': 'PENDING'});
  }

  @override
  Future<List<Listing>> fetchMyListings() async => items;
}

CreateListingCubit draft(FakeListingRepository repository) {
  final cubit = CreateListingCubit(repository: repository);
  cubit.updateTitle('Phòng trọ Quận 1');
  cubit.updateDescription('Phòng có cửa sổ');
  cubit.updateAddress('Quận 1, TP.HCM');
  cubit.updatePinnedLocation(const LatLng(10.78, 106.7));
  cubit.updateAreaId(6);
  cubit.updateArea(30);
  cubit.updateRentPrice(3000000);
  cubit.updatePosterType('CA_NHAN');
  cubit.addImages(['room']);
  return cubit;
}

void main() {
  test(
    'Submission uploads images and sends area and location to API',
    () async {
      final repository = FakeListingRepository();
      final cubit = draft(repository);
      expect(await cubit.submit(), isTrue);
      expect(cubit.state.status, CreateListingStatus.success);
      expect(repository.payload!['imageUrls'], [
        'https://example.com/room.jpg',
      ]);
      expect(repository.payload!['areaId'], 6);
      expect(repository.payload!['latitude'], 10.78);
      expect(repository.payload!['longitude'], 106.7);
      await cubit.close();
    },
  );

  test('Upload failure never reports success or creates a listing', () async {
    final repository = FakeListingRepository()..failUpload = true;
    final cubit = draft(repository);
    expect(await cubit.submit(), isFalse);
    expect(cubit.state.status, CreateListingStatus.error);
    expect(repository.creates, 0);
    expect(cubit.state.title, 'Phòng trọ Quận 1');
    await cubit.close();
  });

  test('Create API failure preserves the draft and exposes an error', () async {
    final repository = FakeListingRepository()..failCreate = true;
    final cubit = draft(repository);
    expect(await cubit.submit(), isFalse);
    expect(cubit.state.status, CreateListingStatus.error);
    expect(cubit.state.imagePaths, ['room']);
    await cubit.close();
  });

  test(
    'Repeated submit while request is in progress creates only one listing',
    () async {
      final repository = FakeListingRepository()..gate = Completer<void>();
      final cubit = draft(repository);
      final first = cubit.submit();
      expect(await cubit.submit(), isFalse);
      repository.gate!.complete();
      expect(await first, isTrue);
      expect(repository.creates, 1);
      await cubit.close();
    },
  );

  test('Missing administrative area stops submission before upload', () async {
    final repository = FakeListingRepository();
    final cubit = draft(repository)..updateAreaId(null);
    expect(await cubit.submit(), isFalse);
    expect(repository.creates, 0);
    await cubit.close();
  });

  testWidgets(
    'Owner sees pending and rejected listings with rejection reason',
    (tester) async {
      final repository = FakeListingRepository()
        ..items = [
          Listing(
            id: 1,
            title: 'Tin đang chờ',
            rentPrice: 3000000,
            areaSqm: 30,
          ),
          Listing(
            id: 2,
            title: 'Tin bị từ chối',
            rentPrice: 4000000,
            areaSqm: 40,
            approvalStatus: 'REJECTED',
            rejectionReason: 'Ảnh không rõ',
          ),
        ];
      await tester.pumpWidget(
        MaterialApp(home: MyListingsPage(repository: repository)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Tin đang chờ'), findsOneWidget);
      expect(find.text('Lý do từ chối: Ảnh không rõ'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
