import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/admin/data/repositories/admin_contract_repository.dart';
import 'package:frontend/features/admin/presentation/pages/admin_contracts_page.dart';
import 'package:frontend/features/contract/data/models/contract_model.dart';

Map<String, dynamic> row(int id) => {
  'id': id,
  'listingId': id,
  'listingName': 'Nhà thuê $id',
  'address': 'Địa chỉ thử $id',
  'landlordName': 'Chủ nhà thử',
  'tenantName': 'Người thuê thử',
  'startDate': '2026-01-01',
  'endDate': '2027-01-01',
  'monthlyRent': 4000000,
  'depositAmount': 1000000,
  'status': id == 1 ? 'EXPIRED' : 'DRAFT',
  'contractType': 'HOUSE',
  'myRole': 'ADMIN',
};

class MemoryContracts extends AdminContractRepository {
  MemoryContracts() : super(ApiClient());
  bool failList = false, failDetail = false;
  String queryValue = '', statusValue = '', typeValue = '';
  int pageValue = 0, detailCalls = 0;
  void failure() => throw DioException(
    requestOptions: RequestOptions(),
    response: Response(
      requestOptions: RequestOptions(),
      statusCode: 503,
      data: {'message': 'Không tải được hợp đồng.'},
    ),
  );
  @override
  Future<AdminContractPageData> fetch({
    String query = '',
    String status = '',
    String type = '',
    int page = 0,
  }) async {
    queryValue = query;
    statusValue = status;
    typeValue = type;
    pageValue = page;
    if (failList) failure();
    final items = <Map<String, dynamic>>[];
    for (int id = 1; id <= 23; id++) {
      final item = row(id);
      if ((status.isEmpty || status == item['status']) &&
          (type.isEmpty || type == item['contractType']) &&
          (query.isEmpty || item['listingName'].toString().contains(query))) {
        items.add(item);
      }
    }
    return AdminContractPageData({
      'items': items.skip(page * 20).take(20).toList(),
      'total': items.length,
      'page': page,
      'totalPages': (items.length / 20).ceil(),
    });
  }

  @override
  Future<ContractModel> detail(int id) async {
    detailCalls++;
    if (failDetail) failure();
    return ContractModel.fromJson({
      ...row(id),
      'documentText': 'THỎA THUẬN GỐC CỦA HAI BÊN',
      'details': {'landlordPhone': '0901111111', 'tenantPhone': '0902222222'},
    });
  }
}

Future<void> open(
  WidgetTester tester,
  MemoryContracts repo, {
  double width = 1400,
  double scale = 1,
}) async {
  await tester.binding.setSurfaceSize(Size(width, 1000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          size: Size(width, 1000),
          textScaler: TextScaler.linear(scale),
        ),
        child: Scaffold(body: AdminContractsPage(repository: repo)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> press(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Desktop lists all contracts and exposes only viewing actions', (
    tester,
  ) async {
    final repo = MemoryContracts();
    await open(tester, repo);
    expect(find.byType(DataTable), findsOneWidget);
    expect(find.text('23 hợp đồng phù hợp'), findsOneWidget);
    expect(find.text('Tạo hợp đồng'), findsNothing);
    expect(find.text('Sửa bản nháp'), findsNothing);
    await press(tester, find.byTooltip('Trang sau'));
    expect(repo.pageValue, 1);
    expect(find.text('Trang 2/2'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'Search and filters reset pagination and clearing restores all rows',
    (tester) async {
      final repo = MemoryContracts();
      await open(tester, repo, width: 700);
      final search = find.byKey(const ValueKey('admin-contract-search'));
      await tester.enterText(search, 'Nhà thuê 1');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(repo.queryValue, 'Nhà thuê 1');
      expect(repo.pageValue, 0);
      await press(tester, find.byType(DropdownButtonFormField<String>).first);
      await press(tester, find.text('Đã hết hạn').last);
      expect(repo.statusValue, 'EXPIRED');
      expect(find.text('1 hợp đồng phù hợp'), findsOneWidget);
      await press(tester, find.byType(DropdownButtonFormField<String>).last);
      await press(tester, find.text('Thuê phòng trọ').last);
      expect(repo.typeValue, 'ROOM');
      expect(find.text('Không có hợp đồng phù hợp.'), findsOneWidget);
      await press(tester, find.text('Xóa bộ lọc'));
      expect(repo.statusValue, '');
      expect(repo.typeValue, '');
      expect(repo.queryValue, '');
      expect(find.text('23 hợp đồng phù hợp'), findsOneWidget);
    },
  );
  testWidgets(
    'Admin details use separate endpoint and allow retry without agreement actions',
    (tester) async {
      final repo = MemoryContracts()..failDetail = true;
      await open(tester, repo, width: 700);
      await press(tester, find.text('Xem chi tiết').first);
      expect(repo.detailCalls, 1);
      expect(find.text('Không tải được hợp đồng.'), findsOneWidget);
      repo.failDetail = false;
      await press(tester, find.text('Thử lại'));
      expect(repo.detailCalls, 2);
      expect(find.text('Chủ nhà: Chủ nhà thử'), findsOneWidget);
      await tester.ensureVisible(find.text('THỎA THUẬN GỐC CỦA HAI BÊN'));
      await tester.pumpAndSettle();
      expect(find.text('THỎA THUẬN GỐC CỦA HAI BÊN'), findsOneWidget);
      expect(find.text('Xác nhận hợp đồng'), findsNothing);
      expect(find.text('Kết thúc hợp đồng'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('Narrow enlarged layout and list retry remain usable', (
    tester,
  ) async {
    final repo = MemoryContracts()..failList = true;
    await open(tester, repo, width: 320, scale: 1.5);
    expect(find.text('Không tải được hợp đồng.'), findsOneWidget);
    repo.failList = false;
    await press(tester, find.text('Thử lại'));
    expect(find.byType(DataTable), findsNothing);
    expect(find.text('23 hợp đồng phù hợp'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
