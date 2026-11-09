import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/incident/data/incident_repository.dart';
import 'package:frontend/features/incident/presentation/admin_incident_content.dart';

Map<String, dynamic> reportRow(int id, String status) => {
  'id': id,
  'version': 0,
  'title': 'Lỗi cần hỗ trợ $id',
  'description': 'Mô tả sự cố cần xử lý.',
  'category': 'TECHNICAL',
  'status': status,
  'reporterName': 'Người gửi thử',
  'reporterEmail': 'member@example.com',
  'createdAt': '2026-10-29T10:00:00',
  'updatedAt': '2026-10-29T11:00:00',
  'history': [],
};

Future<void> openView(
  WidgetTester tester, {
  required IncidentPageData data,
  double width = 1400,
  double scale = 1,
  TextEditingController? search,
  ValueChanged<int>? detail,
  ValueChanged<int>? page,
  ValueChanged<String?>? status,
  ValueChanged<String?>? category,
  VoidCallback? clear,
  VoidCallback? submit,
}) async {
  await tester.binding.setSurfaceSize(Size(width, 1000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final controller = search ?? TextEditingController();
  if (search == null) addTearDown(controller.dispose);
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
      home: Scaffold(
        body: AdminIncidentContent(
          data: data,
          busy: false,
          error: null,
          search: controller,
          status: null,
          category: null,
          onRefresh: () {},
          onSearch: submit ?? () {},
          onClear: clear ?? () {},
          onStatus: status ?? (_) {},
          onCategory: category ?? (_) {},
          onPage: page ?? (_) {},
          onDetail: detail ?? (_) {},
        ),
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
  testWidgets('Admin desktop table shows reporter and opens selected report', (
    tester,
  ) async {
    int? selected;
    await openView(
      tester,
      data: IncidentPageData({
        'items': [reportRow(7, 'OPEN')],
        'total': 1,
        'page': 0,
        'totalPages': 1,
      }),
      detail: (id) => selected = id,
    );
    expect(find.byType(DataTable), findsOneWidget);
    expect(find.text('Người gửi thử'), findsOneWidget);
    expect(find.text('Gửi báo cáo mới'), findsNothing);
    await press(tester, find.text('Xem và xử lý'));
    expect(selected, 7);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'Empty view hides pagination and filters dispatch selected values',
    (tester) async {
      String? statusValue, categoryValue;
      int clears = 0, searches = 0;
      final search = TextEditingController();
      addTearDown(search.dispose);
      await openView(
        tester,
        data: IncidentPageData({
          'items': [],
          'total': 0,
          'page': 0,
          'totalPages': 0,
        }),
        search: search,
        status: (value) => statusValue = value,
        category: (value) => categoryValue = value,
        clear: () => clears++,
        submit: () => searches++,
      );
      expect(find.text('Chưa có báo cáo phù hợp.'), findsOneWidget);
      expect(find.text('Trang 0/0'), findsNothing);
      expect(find.byTooltip('Trang sau'), findsNothing);
      await tester.enterText(
        find.byKey(const ValueKey('incident-search')),
        'bản đồ',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(search.text, 'bản đồ');
      expect(searches, 1);
      await press(tester, find.byType(DropdownButtonFormField<String>).first);
      await press(tester, find.text('Đang xử lý').last);
      expect(statusValue, 'IN_PROGRESS');
      await press(tester, find.byType(DropdownButtonFormField<String>).last);
      await press(tester, find.text('Hợp đồng').last);
      expect(categoryValue, 'CONTRACT');
      await press(tester, find.text('Xóa bộ lọc'));
      expect(clears, 1);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('Narrow dark enlarged cards and pagination remain usable', (
    tester,
  ) async {
    int? selected, next;
    await openView(
      tester,
      data: IncidentPageData({
        'items': [reportRow(9, 'IN_PROGRESS')],
        'total': 21,
        'page': 0,
        'totalPages': 2,
      }),
      width: 320,
      scale: 1.5,
      detail: (id) => selected = id,
      page: (value) => next = value,
    );
    expect(find.byType(DataTable), findsNothing);
    await press(tester, find.text('Xem và xử lý'));
    expect(selected, 9);
    await press(tester, find.byTooltip('Trang sau'));
    expect(next, 1);
    expect(tester.takeException(), isNull);
  });
}
