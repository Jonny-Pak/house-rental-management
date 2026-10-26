import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/core/excel/excel_files.dart';
import 'package:frontend/features/admin/data/repositories/report_repository.dart';
import 'package:frontend/features/admin/presentation/screens/dashboard/dashboard_screen.dart';

class TestReports extends ReportRepository {
  TestReports() : super(ApiClient());
  bool fail = false, empty = false, failExport = false;
  int loads = 0, exports = 0;
  DateTime? loadedFrom, loadedTo, exportedFrom, exportedTo;
  @override
  Future<ReportData> load(DateTime from, DateTime to) async {
    loads++;
    loadedFrom = from;
    loadedTo = to;
    if (fail) {
      throw DioException(
        requestOptions: RequestOptions(),
        response: Response(
          requestOptions: RequestOptions(),
          statusCode: 500,
          data: {'message': 'Không tải được dữ liệu kiểm thử.'},
        ),
      );
    }
    return ReportData({
      'from': reportDate(from),
      'to': reportDate(to),
      'generatedAt': '2026-10-24T22:00:00',
      'members': empty ? 0 : 3,
      'listings': empty ? 0 : 5,
      'contracts': empty ? 0 : 2,
      'revenue': empty ? 0 : 123456.78,
      'successfulPayments': empty ? 0 : 1,
      'daily': [
        for (
          DateTime day = from;
          !day.isAfter(to);
          day = day.add(const Duration(days: 1))
        )
          {
            'date': reportDate(day),
            'members': 0,
            'listings': 0,
            'contracts': 0,
            'revenue': 0,
          },
      ],
      'listingStatuses': empty
          ? []
          : [
              {'status': 'PENDING', 'count': 5},
            ],
      'contractStatuses': empty
          ? []
          : [
              {'status': 'DRAFT', 'count': 2},
            ],
    });
  }

  @override
  Future<Uint8List> export(DateTime from, DateTime to) async {
    exports++;
    exportedFrom = from;
    exportedTo = to;
    if (failExport) throw Exception('Export failed');
    return Uint8List.fromList([1, 2, 3]);
  }
}

class TestFiles extends ExcelFiles {
  Uint8List? bytes;
  String? name;
  bool cancelled = false;
  @override
  Future<bool> save(Uint8List bytes, String name) async {
    this.bytes = bytes;
    this.name = name;
    return !cancelled;
  }
}

Future<void> openReport(
  WidgetTester tester,
  TestReports repository,
  TestFiles files, {
  double width = 1440,
}) async {
  await tester.binding.setSurfaceSize(Size(width, 1000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(
        brightness: width < 400 ? Brightness.dark : Brightness.light,
      ),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(width < 400 ? 1.5 : 1)),
        child: child!,
      ),
      home: Scaffold(
        body: DashboardScreen(repository: repository, files: files),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> press(WidgetTester tester, String text) async {
  final item = find.text(text).last;
  await tester.ensureVisible(item);
  await tester.tap(item);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'Reports load real response, change period and export the same period',
    (tester) async {
      final repo = TestReports();
      final files = TestFiles();
      await openReport(tester, repo, files);
      expect(find.text('123.456,78 ₫'), findsWidgets);
      expect(find.text('Member đăng ký mới'), findsOneWidget);
      expect(find.text('284.120.000 ₫'), findsNothing);
      await press(tester, '30 ngày gần nhất');
      expect(repo.loadedTo!.difference(repo.loadedFrom!).inDays, 29);
      await press(tester, 'Xuất Excel');
      expect(repo.exportedFrom, repo.loadedFrom);
      expect(repo.exportedTo, repo.loadedTo);
      expect(files.bytes, [1, 2, 3]);
      expect(files.name, contains(reportDate(repo.loadedFrom!)));
      expect(find.text('Đã xuất báo cáo Excel.'), findsOneWidget);
      await tester.ensureVisible(find.byTooltip('Trang sau'));
      await tester.tap(find.byTooltip('Trang sau'));
      await tester.pumpAndSettle();
      expect(find.text('Trang 2/3'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Failed load disables export and retry restores the report', (
    tester,
  ) async {
    final repo = TestReports()..fail = true;
    final files = TestFiles();
    await openReport(tester, repo, files);
    expect(find.text('Không tải được dữ liệu kiểm thử.'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Xuất Excel'))
          .onPressed,
      isNull,
    );
    repo.fail = false;
    await press(tester, 'Thử lại');
    expect(repo.loads, 2);
    expect(find.text('123.456,78 ₫'), findsWidgets);
  });

  testWidgets('Empty report and narrow enlarged dark layout remain usable', (
    tester,
  ) async {
    final repo = TestReports()..empty = true;
    await openReport(tester, repo, TestFiles(), width: 320);
    expect(find.text('Chưa phát sinh doanh thu dịch vụ.'), findsOneWidget);
    expect(
      find.text('Chưa có dữ liệu trong khoảng đã chọn.'),
      findsNWidgets(2),
    );
    await tester.ensureVisible(find.byTooltip('Trang sau'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Export errors retain report and allow retry', (tester) async {
    final repo = TestReports()..failExport = true;
    final files = TestFiles();
    await openReport(tester, repo, files);
    await press(tester, 'Xuất Excel');
    expect(files.bytes, isNull);
    expect(find.text('123.456,78 ₫'), findsWidgets);
    repo.failExport = false;
    files.cancelled = true;
    await press(tester, 'Xuất Excel');
    expect(repo.exports, 2);
    expect(find.text('Đã xuất báo cáo Excel.'), findsNothing);
  });
}
