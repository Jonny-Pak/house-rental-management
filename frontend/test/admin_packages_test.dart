import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/admin/data/repositories/admin_package_repository.dart';
import 'package:frontend/features/admin/presentation/pages/admin_packages_page.dart';
import 'package:frontend/features/membership/data/models/membership_package_model.dart';

Map<String, dynamic> packageRow(int id) => {
  'id': id,
  'packageName': 'Gói thử $id',
  'price': 50000,
  'standardPostQuota': 10,
  'vipPostQuota': 2,
  'refreshQuota': 3,
  'description': 'Quyền lợi thử',
  'active': true,
  'version': 0,
};

class MemoryPackages extends AdminPackageRepository {
  MemoryPackages() : super(ApiClient());
  final rows = <int, Map<String, dynamic>>{1: packageRow(1), 2: packageRow(2)};
  bool failLoad = false;
  int saves = 0, statuses = 0, deletes = 0;
  bool? filter;
  Map<String, dynamic>? saved;
  void failure(String message) => throw DioException(
    requestOptions: RequestOptions(),
    response: Response(
      requestOptions: RequestOptions(),
      statusCode: 409,
      data: {'message': message},
    ),
  );
  @override
  Future<AdminPackagePageData> fetch({
    String query = '',
    bool? active,
    int page = 0,
  }) async {
    filter = active;
    if (failLoad) failure('Không tải được danh sách gói.');
    final selected = <Map<String, dynamic>>[];
    for (final row in rows.values) {
      if ((active == null || active == row['active']) &&
          row['packageName'].toString().contains(query)) {
        selected.add(row);
      }
    }
    return AdminPackagePageData({
      'items': selected.skip(page * 20).take(20).toList(),
      'total': selected.length,
      'page': page,
      'totalPages': (selected.length / 20).ceil(),
    });
  }

  @override
  Future<void> save(int? id, Map<String, dynamic> data) async {
    if (id != null && rows[id]!['version'] != data['version']) {
      failure('Gói đã thay đổi. Hãy tải lại trước khi thao tác.');
    }
    saves++;
    saved = data;
    final target = id ?? rows.length + 1;
    rows[target] = {
      ...data,
      'id': target,
      'version': id == null ? 0 : data['version'] + 1,
    };
  }

  @override
  Future<void> status(MembershipPackage item) async {
    statuses++;
    rows[item.id]!['active'] = !item.active;
    rows[item.id]!['version'] = item.version + 1;
  }

  @override
  Future<void> delete(MembershipPackage item) async {
    if (item.id == 1) {
      failure(
        'Gói đã có người mua hoặc giao dịch. Hãy ngừng bán để giữ lịch sử.',
      );
    }
    deletes++;
    rows.remove(item.id);
  }
}

Future<void> open(
  WidgetTester tester,
  MemoryPackages repo, {
  double width = 1440,
  double scale = 1,
}) async {
  await tester.binding.setSurfaceSize(Size(width, 1100));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(
        brightness: width < 400 ? Brightness.dark : Brightness.light,
      ),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: Scaffold(body: AdminPackagesPage(repository: repo)),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> press(WidgetTester tester, String text) async {
  Finder target = find.text(text).last;
  final filled = find.widgetWithText(FilledButton, text);
  final outlined = find.widgetWithText(OutlinedButton, text);
  if (filled.evaluate().isNotEmpty) {
    target = filled.last;
  } else if (outlined.evaluate().isNotEmpty) {
    target = outlined.last;
  }
  await tester.ensureVisible(target);
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<void> fill(WidgetTester tester, String key, String text) async {
  final target = find.byKey(ValueKey(key));
  await tester.ensureVisible(target);
  await tester.enterText(target, text);
  await tester.pump();
}

Future<void> action(WidgetTester tester, String tooltip) async {
  final target = find.byTooltip(tooltip);
  await tester.ensureVisible(target);
  await tester.tap(target);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Admin creates valid package and edits catalog values', (
    tester,
  ) async {
    final repo = MemoryPackages();
    await open(tester, repo);
    await press(tester, 'Thêm gói dịch vụ');
    await press(tester, 'Lưu gói');
    expect(repo.saves, 0);
    await fill(tester, 'package-name', 'Gói PLUS mới');
    await press(tester, 'Lưu gói');
    expect(repo.saves, 0);
    expect(
      find.text('Gói cần có ít nhất một lượt đăng tin hoặc làm mới.'),
      findsOneWidget,
    );
    await fill(tester, 'package-standard', '12');
    await fill(tester, 'package-price', '70000');
    await press(tester, 'Lưu gói');
    expect(repo.saves, 1);
    expect(repo.saved!['price'], 70000);
    expect(find.text('Gói PLUS mới'), findsOneWidget);
    await action(tester, 'Sửa Gói PLUS mới');
    await fill(tester, 'package-vip', '5');
    await press(tester, 'Lưu gói');
    expect(repo.saves, 2);
    expect(repo.saved!['vipPostQuota'], 5);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'Status and deletion require confirmation and used packages remain',
    (tester) async {
      final repo = MemoryPackages();
      await open(tester, repo);
      await action(tester, 'Ngừng bán Gói thử 1');
      await press(tester, 'Hủy');
      expect(repo.statuses, 0);
      await action(tester, 'Ngừng bán Gói thử 1');
      await press(tester, 'Xác nhận');
      expect(repo.statuses, 1);
      expect(repo.rows[1]!['active'], false);
      await action(tester, 'Mở bán Gói thử 1');
      await press(tester, 'Xác nhận');
      expect(repo.statuses, 2);
      await action(tester, 'Xóa Gói thử 1');
      await press(tester, 'Xác nhận');
      expect(
        find.text(
          'Gói đã có người mua hoặc giao dịch. Hãy ngừng bán để giữ lịch sử.',
        ),
        findsOneWidget,
      );
      expect(repo.rows.length, 2);
      await action(tester, 'Xóa Gói thử 2');
      await press(tester, 'Xác nhận');
      expect(repo.deletes, 1);
      expect(repo.rows.length, 1);
    },
  );
  testWidgets(
    'Version conflict retains input and re-opening loads latest version',
    (tester) async {
      final repo = MemoryPackages();
      await open(tester, repo);
      await action(tester, 'Sửa Gói thử 1');
      await fill(tester, 'package-description', 'Thông tin đang nhập');
      repo.rows[1]!['version'] = 1;
      await press(tester, 'Lưu gói');
      expect(repo.saves, 0);
      expect(find.text('Thông tin đang nhập'), findsOneWidget);
      expect(
        find.text('Gói đã thay đổi. Hãy tải lại trước khi thao tác.'),
        findsOneWidget,
      );
      await press(tester, 'Hủy');
      await press(tester, 'Làm mới');
      await action(tester, 'Sửa Gói thử 1');
      await fill(tester, 'package-description', 'Thông tin mới');
      await press(tester, 'Lưu gói');
      expect(repo.saves, 1);
    },
  );
  testWidgets('Pagination, search and failed load retry use real filters', (
    tester,
  ) async {
    final repo = MemoryPackages();
    for (int id = 3; id <= 22; id++) {
      repo.rows[id] = packageRow(id);
    }
    await open(tester, repo);
    await action(tester, 'Trang sau');
    expect(find.text('Trang 2/2'), findsOneWidget);
    await fill(tester, 'package-search', 'Gói thử 22');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.text('1 gói phù hợp'), findsOneWidget);
    repo.failLoad = true;
    await press(tester, 'Làm mới');
    expect(find.text('Không tải được danh sách gói.'), findsOneWidget);
    repo.failLoad = false;
    await press(tester, 'Tải lại danh sách');
    expect(
      find.byWidgetPredicate(
        (widget) => widget is Text && widget.data == 'Gói thử 22',
      ),
      findsOneWidget,
    );
  });
  testWidgets(
    'Narrow enlarged dark catalog and editor validate numeric limits',
    (tester) async {
      final repo = MemoryPackages();
      await open(tester, repo, width: 320, scale: 1.5);
      expect(find.byType(DataTable), findsNothing);
      await action(tester, 'Sửa Gói thử 1');
      await fill(tester, 'package-price', '100000000');
      await press(tester, 'Lưu gói');
      expect(repo.saves, 0);
      expect(find.text('Nhập số nguyên từ 0 đến 99999999.'), findsOneWidget);
      await fill(tester, 'package-price', '50000');
      await fill(tester, 'package-vip', '32768');
      await press(tester, 'Lưu gói');
      expect(repo.saves, 0);
      expect(tester.takeException(), isNull);
    },
  );
}
