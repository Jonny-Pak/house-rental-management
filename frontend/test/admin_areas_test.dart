import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/admin/data/models/admin_area.dart';
import 'package:frontend/features/admin/data/repositories/admin_area_repository.dart';
import 'package:frontend/features/admin/presentation/pages/admin_areas_page.dart';
import 'package:frontend/features/admin/presentation/widgets/admin_area_dialog.dart';
import 'package:frontend/app/admin/router/routes.dart';

const province = AdminArea(
  id: 1,
  name: 'Thành phố kiểm thử',
  type: 'PROVINCE',
  code: 'TP',
  children: 1,
);
AdminArea ward({
  String name = 'Phường kiểm thử',
  bool active = true,
  int listings = 0,
}) => AdminArea(
  id: 6,
  name: name,
  type: 'WARD',
  code: 'P06',
  parentId: 1,
  parentName: province.name,
  active: active,
  listingCount: listings,
);

class MemoryAreas extends AdminAreaRepository {
  MemoryAreas() : super(ApiClient());
  AdminArea? row = ward();
  String? failure;
  bool failLoad = false;
  int saves = 0, changes = 0, deletes = 0;
  final searches = <Map<String, dynamic>>[];
  Completer<AdminAreaPage>? slow;

  @override
  Future<List<AdminArea>> parents() async => [province];
  @override
  Future<AdminAreaPage> search({
    String query = '',
    String? type,
    int? parentId,
    bool? active,
    int page = 0,
  }) async {
    searches.add({
      'query': query,
      'type': type,
      'parentId': parentId,
      'active': active,
      'page': page,
    });
    if (failLoad) throw error('Không tải được khu vực.');
    if (slow != null) {
      final pending = slow!;
      slow = null;
      return pending.future;
    }
    return AdminAreaPage(
      row == null ? [] : [row!],
      row == null ? 0 : 21,
      page,
      row == null ? 0 : 2,
    );
  }

  @override
  Future<AdminArea> detail(int id) async => row!;
  @override
  Future<void> save({
    int? id,
    required String name,
    required String code,
    required String type,
    int? parentId,
  }) async {
    saves++;
    if (failure != null) throw error(failure!);
    row = AdminArea(
      id: id ?? 10,
      name: name,
      type: type,
      code: code,
      parentId: parentId,
      parentName: parentId == null ? null : province.name,
    );
  }

  @override
  Future<void> changeStatus(int id, bool active) async {
    changes++;
    row = ward(active: active);
  }

  @override
  Future<void> delete(int id) async {
    deletes++;
    row = null;
  }
}

DioException error(String message) => DioException(
  requestOptions: RequestOptions(path: '/admin/areas'),
  response: Response(
    requestOptions: RequestOptions(path: '/admin/areas'),
    statusCode: 409,
    data: {'message': message},
  ),
);

Future<void> open(
  WidgetTester tester,
  MemoryAreas repository, {
  double width = 1500,
  double scale = 1,
  Brightness brightness = Brightness.light,
}) async {
  await tester.binding.setSurfaceSize(Size(width, 1000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(brightness: brightness),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: Scaffold(body: AdminAreasPage(repository: repository)),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  test('Area management is linked in the Admin menu', () {
    expect(kNav.where((n) => n.path == R.areas).length, 1);
  });

  testWidgets('Search, type, parent and status filters reset paging', (
    tester,
  ) async {
    final repository = MemoryAreas();
    await open(tester, repository);
    expect(find.byType(DataTable), findsOneWidget);
    expect(find.text('Phường kiểm thử'), findsOneWidget);
    await tester.ensureVisible(find.byTooltip('Trang sau'));
    await tester.tap(find.byTooltip('Trang sau'));
    await tester.pumpAndSettle();
    expect(repository.searches.last['page'], 1);
    await tester.ensureVisible(find.byType(TextField).first);
    await tester.enterText(find.byType(TextField).first, 'P06');
    await tester.tap(find.byTooltip('Tìm khu vực'));
    await tester.pumpAndSettle();
    expect(repository.searches.last['query'], 'P06');
    expect(repository.searches.last['page'], 0);
    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xã').last);
    await tester.pumpAndSettle();
    expect(repository.searches.last['type'], 'COMMUNE');
    await tester.tap(find.byType(DropdownButtonFormField<int>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Thành phố kiểm thử (TP)').last);
    await tester.pumpAndSettle();
    expect(repository.searches.last['parentId'], 1);
    await tester.tap(find.byType(DropdownButtonFormField<bool>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ngừng sử dụng').last);
    await tester.pumpAndSettle();
    expect(repository.searches.last['active'], false);
    await tester.tap(find.text('Xóa bộ lọc'));
    await tester.pumpAndSettle();
    expect(repository.searches.last['type'], isNull);
    expect(repository.searches.last['parentId'], isNull);
    expect(repository.searches.last['active'], isNull);
    expect(repository.searches.last['query'], '');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Create validates fields, requires a parent and reloads the result',
    (tester) async {
      final repository = MemoryAreas();
      await open(tester, repository);
      await tester.tap(find.text('Thêm khu vực'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lưu khu vực'));
      await tester.pumpAndSettle();
      expect(repository.saves, 0);
      expect(find.text('Vui lòng nhập tên khu vực.'), findsOneWidget);
      await tester.enterText(find.byKey(const ValueKey('area-name')), 'Xã mới');
      await tester.enterText(find.byKey(const ValueKey('area-code')), 'XA-MOI');
      await tester.tap(find.byType(DropdownButtonFormField<int>).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text(province.name).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lưu khu vực'));
      await tester.pumpAndSettle();
      expect(repository.saves, 1);
      expect(repository.row!.parentId, 1);
      expect(find.byType(AdminAreaDialog), findsNothing);
      expect(find.text('Xã mới'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Used area keeps its hierarchy and supports retry after a save error',
    (tester) async {
      final repository = MemoryAreas()
        ..row = ward(listings: 2)
        ..failure = 'Mã khu vực đã tồn tại.';
      await open(tester, repository);
      await tester.ensureVisible(find.byTooltip('Sửa khu vực'));
      await tester.tap(find.byTooltip('Sửa khu vực'));
      await tester.pumpAndSettle();
      final type = tester.widget<DropdownButtonFormField<String>>(
        find.byKey(const ValueKey('area-type')),
      );
      expect(type.onChanged, isNull);
      await tester.enterText(
        find.byKey(const ValueKey('area-name')),
        'Phường đổi tên',
      );
      await tester.tap(find.text('Lưu khu vực'));
      await tester.pumpAndSettle();
      expect(find.text('Mã khu vực đã tồn tại.'), findsOneWidget);
      expect(find.text('Phường đổi tên'), findsOneWidget);
      repository.failure = null;
      await tester.tap(find.text('Lưu khu vực'));
      await tester.pumpAndSettle();
      expect(repository.saves, 2);
      expect(find.text('Phường đổi tên'), findsOneWidget);
    },
  );

  testWidgets('Disabling requires confirmation and can be reversed', (
    tester,
  ) async {
    final repository = MemoryAreas();
    await open(tester, repository);
    await tester.ensureVisible(find.byTooltip('Ngừng sử dụng'));
    await tester.tap(find.byTooltip('Ngừng sử dụng'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hủy'));
    await tester.pumpAndSettle();
    expect(repository.changes, 0);
    await tester.tap(find.byTooltip('Ngừng sử dụng'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xác nhận'));
    await tester.pumpAndSettle();
    expect(repository.row!.active, false);
    await tester.tap(find.byTooltip('Kích hoạt'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xác nhận'));
    await tester.pumpAndSettle();
    expect(repository.changes, 2);
    expect(repository.row!.active, true);
  });

  testWidgets('Unused areas can be deleted and the empty state is shown', (
    tester,
  ) async {
    final repository = MemoryAreas();
    await open(tester, repository);
    await tester.ensureVisible(find.byTooltip('Xóa khu vực'));
    await tester.tap(find.byTooltip('Xóa khu vực'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xác nhận'));
    await tester.pumpAndSettle();
    expect(repository.deletes, 1);
    expect(find.text('Chưa có khu vực phù hợp.'), findsOneWidget);
  });

  testWidgets('Used areas disable delete and loading errors support retry', (
    tester,
  ) async {
    final repository = MemoryAreas()..failLoad = true;
    await open(tester, repository);
    expect(find.text('Không tải được khu vực.'), findsOneWidget);
    repository.failLoad = false;
    repository.row = ward(listings: 1);
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byTooltip('Đang có dữ liệu liên quan'));
    final button = tester.widget<IconButton>(
      find
          .ancestor(
            of: find.byTooltip('Đang có dữ liệu liên quan'),
            matching: find.byType(IconButton),
          )
          .first,
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('Old searches cannot replace newer search results', (
    tester,
  ) async {
    final repository = MemoryAreas();
    await open(tester, repository);
    final pending = Completer<AdminAreaPage>();
    repository.slow = pending;
    await tester.enterText(find.byType(TextField).first, 'old');
    await tester.tap(find.byTooltip('Tìm khu vực'));
    await tester.pump();
    repository.row = ward(name: 'Kết quả mới');
    await tester.enterText(find.byType(TextField).first, 'new');
    await tester.tap(find.byTooltip('Tìm khu vực'));
    await tester.pumpAndSettle();
    pending.complete(AdminAreaPage([ward(name: 'Kết quả cũ')], 1, 0, 1));
    await tester.pumpAndSettle();
    expect(find.text('Kết quả mới'), findsOneWidget);
    expect(find.text('Kết quả cũ'), findsNothing);
  });

  testWidgets('Narrow dark layout and large text keep the form accessible', (
    tester,
  ) async {
    await open(
      tester,
      MemoryAreas(),
      width: 320,
      scale: 1.5,
      brightness: Brightness.dark,
    );
    expect(find.byType(DataTable), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('Thêm khu vực'));
    await tester.tap(find.text('Thêm khu vực'));
    await tester.pumpAndSettle();
    expect(find.byType(AdminAreaDialog), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.enterText(
      find.byKey(const ValueKey('area-name')),
      'Phường nhỏ',
    );
    await tester.ensureVisible(find.text('Hủy'));
    await tester.tap(find.text('Hủy'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
