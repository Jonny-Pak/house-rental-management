import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/contract/data/models/contract_model.dart';
import 'package:frontend/features/contract/data/repositories/contract_repository.dart';
import 'package:frontend/features/contract/presentation/pages/my_contracts_page.dart';
import 'package:frontend/features/contract/presentation/pages/contract_form_page.dart';
import 'package:frontend/features/listing/data/models/listing_model.dart';
import 'package:frontend/features/listing/data/repositories/listing_repository.dart';

ContractModel lease({String role = 'TENANT', String status = 'DRAFT'}) =>
    ContractModel.fromJson({
      'id': 1,
      'listingId': 10,
      'listingName': 'Nhà cho thuê',
      'landlordName': 'Chủ nhà',
      'tenantId': 2,
      'tenantName': 'Người thuê',
      'startDate': '2027-01-01',
      'endDate': '2028-01-01',
      'monthlyRent': 5000000,
      'depositAmount': 0,
      'myRole': role,
      'status': status,
      'version': 5,
    });

class FakeContracts extends ContractRepository {
  FakeContracts() : super(ApiClient());
  ContractModel current = lease();
  String? action;
  int? version;
  CreateContractRequest? updated;
  @override
  Future<List<ContractModel>> getMyContracts() async => [current];
  @override
  Future<ContractModel> detail(int id) async => current;
  @override
  Future<void> status(int id, String status, int v) async {
    action = status;
    version = v;
    current = lease(role: current.myRole, status: status);
  }

  @override
  Future<void> update(int id, CreateContractRequest request) async {
    updated = request;
  }
}

class ContractListings extends ListingRepository {
  ContractListings() : super(ApiClient());
  @override
  Future<List<Listing>> fetchMyListings() async => [
    Listing(
      id: 10,
      title: 'Nhà cho thuê',
      rentPrice: 5000000,
      areaSqm: 50,
      approvalStatus: 'APPROVED',
    ),
  ];
}

void main() {
  test(
    'DTO parses party role and version without nested private user data',
    () {
      final c = lease();
      expect(c.myRole, 'TENANT');
      expect(c.version, 5);
      expect(c.tenantId, 2);
    },
  );
  testWidgets(
    'Tenant accepts draft with current version and cannot edit or terminate',
    (tester) async {
      final repo = FakeContracts();
      await tester.pumpWidget(
        MaterialApp(home: ContractDetailPage(id: 1, repository: repo)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Sửa bản nháp'), findsNothing);
      await tester.scrollUntilVisible(
        find.text('Đồng ý hợp đồng'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Đồng ý hợp đồng'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Xác nhận'));
      await tester.pumpAndSettle();
      expect(repo.action, 'ACTIVE');
      expect(repo.version, 5);
      expect(find.text('Kết thúc hợp đồng'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('Landlord views own draft but cannot accept on tenant behalf', (
    tester,
  ) async {
    final repo = FakeContracts()..current = lease(role: 'LANDLORD');
    await tester.pumpWidget(
      MaterialApp(home: ContractDetailPage(id: 1, repository: repo)),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Sửa bản nháp'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Đồng ý hợp đồng'), findsNothing);
    expect(find.text('Hủy bản nháp'), findsOneWidget);
  });
  testWidgets(
    'Editing uses selected listing and tenant, rejects zero rent before saving',
    (tester) async {
      final repo = FakeContracts();
      await tester.pumpWidget(
        MaterialApp(
          home: ContractFormPage(
            repository: repo,
            existing: lease(role: 'LANDLORD'),
            listings: ContractListings(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('ID Người thuê'), findsNothing);
      await tester.scrollUntilVisible(
        find.widgetWithText(TextFormField, 'Tiền thuê / tháng (VNĐ)'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Tiền thuê / tháng (VNĐ)'),
        '0',
      );
      await tester.scrollUntilVisible(
        find.text('Lưu và chờ người thuê xác nhận'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Lưu và chờ người thuê xác nhận'));
      await tester.pumpAndSettle();
      expect(repo.updated, isNull);
      await tester.scrollUntilVisible(
        find.widgetWithText(TextFormField, 'Tiền thuê / tháng (VNĐ)'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Tiền thuê / tháng (VNĐ)'),
        '5500000',
      );
      await tester.scrollUntilVisible(
        find.text('Lưu và chờ người thuê xác nhận'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Lưu và chờ người thuê xác nhận'));
      await tester.pumpAndSettle();
      expect(repo.updated?.listingId, 10);
      expect(repo.updated?.tenantId, 2);
      expect(repo.updated?.monthlyRent, 5500000);

      expect(tester.takeException(), isNull);
    },
  );
}
