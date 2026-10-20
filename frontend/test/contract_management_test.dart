import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/contract/data/models/contract_model.dart';
import 'package:frontend/features/contract/data/repositories/contract_repository.dart';
import 'package:frontend/features/contract/presentation/pages/my_contracts_page.dart';
import 'package:frontend/features/contract/presentation/pages/contract_form_page.dart';
import 'package:frontend/features/listing/data/models/listing_model.dart';
import 'package:frontend/features/listing/data/repositories/listing_repository.dart';

const contractDetails = <String, dynamic>{
  'landlordIdentity': 'CCCD chủ nhà mẫu',
  'landlordAddress': 'Địa chỉ chủ nhà mẫu',
  'tenantIdentity': 'CCCD người thuê mẫu',
  'tenantAddress': 'Địa chỉ người thuê mẫu',
  'signingPlace': 'TP.HCM',
  'signingDate': '2026-12-25',
  'handoverDate': '2027-01-01',
  'paymentDay': 5,
  'paymentMethod': 'Chuyển khoản theo tài khoản đã xác nhận',
  'electricityTerms': 'Theo hóa đơn điện',
  'waterTerms': 'Theo hóa đơn nước',
};

ContractModel lease({String role = 'TENANT', String status = 'DRAFT'}) =>
    ContractModel.fromJson({
      'details': contractDetails,
      'contractType': 'HOUSE',
      'documentText': 'HỢP ĐỒNG THUÊ NHÀ Ở\nNội dung thỏa thuận của hai bên.',
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
  CreateContractRequest? previewed;
  @override
  Future<String> preview(CreateContractRequest request) async {
    previewed = request;
    return 'HỢP ĐỒNG THUÊ NHÀ Ở\nNội dung dự thảo đã điền đầy đủ.';
  }

  String? action;
  String? contact;
  @override
  Future<Map<String, dynamic>> findTenant(String input, int listingId) async {
    contact = input;
    return {'id': 2, 'name': 'Người thuê'};
  }

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

class TenantApi extends ApiClient {
  Map<String, dynamic>? query;
  @override
  Future<Response> get(String path, {Map<String, dynamic>? queryParams}) async {
    query = queryParams;
    return Response(
      requestOptions: RequestOptions(path: path),
      statusCode: 200,
      data: {'id': 2, 'name': 'Người thuê'},
    );
  }
}

void main() {
  test('Tenant lookup sends phone or email and preserves listing ownership context', () async {
    final api = TenantApi();
    final repository = ContractRepository(api);
    await repository.findTenant('0901234567', 10);
    expect(api.query, {'listingId': 10, 'phone': '0901234567'});
    await repository.findTenant('tenant@example.com', 10);
    expect(api.query, {'listingId': 10, 'email': 'tenant@example.com'});
  });
  testWidgets('Landlord can find tenant using phone in the contract form', (
    tester,
  ) async {
    final repository = FakeContracts();
    await tester.pumpWidget(
      MaterialApp(
        home: ContractFormPage(
          repository: repository,
          existing: lease(role: 'LANDLORD'),
          listings: ContractListings(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email hoặc số điện thoại người thuê'),
      '0901234567',
    );
    await tester.tap(find.text('Tìm người thuê'));
    await tester.pumpAndSettle();
    expect(repository.contact, '0901234567');
    expect(find.text('Người thuê: Người thuê'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
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
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Đồng ý hợp đồng'),
            )
            .onPressed,
        isNull,
      );
      await tester.ensureVisible(
        find.text('Tôi đã đọc toàn bộ và đồng ý nội dung hợp đồng'),
      );
      await tester.tap(
        find.text('Tôi đã đọc toàn bộ và đồng ý nội dung hợp đồng'),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Đồng ý hợp đồng'));
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
    await tester.scrollUntilVisible(
      find.text('Hủy bản nháp'),
      150,
      scrollable: find.byType(Scrollable).first,
    );
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
      expect(repo.previewed, isNull);
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
      expect(repo.updated, isNull);
      expect(find.text('Xem trước hợp đồng'), findsOneWidget);
      await tester.tap(find.text('Quay lại chỉnh sửa'));
      await tester.pumpAndSettle();
      expect(repo.updated, isNull);
      await tester.ensureVisible(find.text('Lưu và chờ người thuê xác nhận'));
      await tester.tap(find.text('Lưu và chờ người thuê xác nhận'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Xác nhận gửi hợp đồng'));
      await tester.pumpAndSettle();
      expect(repo.updated?.listingId, 10);
      expect(repo.updated?.tenantId, 2);
      expect(repo.updated?.monthlyRent, 5500000);
      expect(
        repo.updated?.details['tenantIdentity'],
        contractDetails['tenantIdentity'],
      );

      expect(tester.takeException(), isNull);
    },
  );
}
