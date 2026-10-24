import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/excel/excel_files.dart';
import 'package:frontend/core/excel/excel_page.dart';
import 'package:frontend/core/excel/excel_repository.dart';
import 'package:frontend/core/network/api_client.dart';

class MemoryExcel extends ExcelRepository {
  MemoryExcel() : super(ApiClient(), 'listings');
  int previews = 0, imports = 0;
  final downloads = <bool>[];
  bool invalid = false, changed = false;
  Completer<void>? pending;
  @override
  Future<Uint8List> download({required bool template}) async {
    downloads.add(template);
    return Uint8List.fromList([80, 75, 3, 4]);
  }

  @override
  Future<ExcelResult> upload(ExcelUpload file, {required bool preview}) async {
    if (preview) {
      previews++;
    } else {
      imports++;
    }
    if (pending != null) await pending!.future;
    final hasError = invalid || (!preview && changed);
    return ExcelResult(
      totalRows: 1,
      importedRows: preview || hasError ? 0 : 1,
      rows: hasError
          ? []
          : [
              {
                'row': 2,
                'title': 'Phòng từ Excel',
                'description': 'Địa chỉ tiếng Việt',
              },
            ],
      errors: hasError
          ? [
              {'row': 2, 'message': 'Giá thuê không hợp lệ.'},
            ]
          : [],
    );
  }
}

class MemoryFiles extends ExcelFiles {
  bool cancel = false;
  final names = <String>[];
  @override
  Future<ExcelUpload?> pick() async =>
      cancel ? null : ExcelUpload('test.xlsx', Uint8List.fromList([80, 75]));
  @override
  Future<bool> save(Uint8List bytes, String name) async {
    names.add(name);
    return !cancel;
  }
}

class ExcelApi extends ApiClient {
  String? path;
  FormData? form;
  @override
  Future<Response> getBytes(String path) async {
    this.path = path;
    return Response(
      requestOptions: RequestOptions(path: path),
      data: [80, 75, 3, 4],
    );
  }

  @override
  Future<Response> post(String path, dynamic data, {Options? options}) async {
    this.path = path;
    form = data as FormData;
    return Response(
      requestOptions: RequestOptions(path: path),
      data: {'totalRows': 1, 'importedRows': 0, 'rows': [], 'errors': []},
    );
  }
}

Widget page(
  MemoryExcel repository,
  MemoryFiles files, {
  bool landlord = true,
  String module = 'listings',
  double scale = 1,
}) => MaterialApp(
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: child!,
  ),
  home: ExcelPage(
    module: module,
    title: module == 'contracts' ? 'Hợp đồng' : 'Tin đăng',
    allowImport: landlord,
    repository: repository,
    files: files,
  ),
);

Future<void> tapText(WidgetTester tester, String text) async {
  final finder = find.text(text);
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(finder, 200);
  }
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  test(
    'Excel repository uses authenticated endpoints and multipart bytes',
    () async {
      final api = ExcelApi();
      final repo = ExcelRepository(api, 'contracts');
      expect(await repo.download(template: true), [80, 75, 3, 4]);
      expect(api.path, '/contracts/excel/template');
      final file = ExcelUpload('hop-dong.xlsx', Uint8List.fromList([1, 2]));
      await repo.upload(file, preview: true);
      expect(api.path, '/contracts/excel/preview');
      expect(api.form!.files.single.key, 'file');
      expect(api.form!.files.single.value.filename, 'hop-dong.xlsx');
      expect(api.form!.fields, isEmpty);
      await repo.upload(file, preview: false);
      expect(api.path, '/contracts/excel/import');
    },
  );

  testWidgets('Invalid rows display row numbers and cannot be imported', (
    tester,
  ) async {
    final repository = MemoryExcel()..invalid = true;
    await tester.pumpWidget(page(repository, MemoryFiles()));
    await tapText(tester, 'Chọn file và kiểm tra');
    await tester.scrollUntilVisible(find.text('Dòng 2'), 200);
    await tester.pumpAndSettle();
    expect(find.text('Dòng 2'), findsOneWidget);
    final button = find.widgetWithText(FilledButton, 'Xác nhận nhập 1 dòng');
    expect(tester.widget<FilledButton>(button).onPressed, isNull);
    expect(repository.imports, 0);
  });

  testWidgets(
    'Preview waits for confirmation and successful import returns count',
    (tester) async {
      final repository = MemoryExcel();
      int? imported;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  imported = await Navigator.push<int>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ExcelPage(
                        module: 'listings',
                        title: 'Tin đăng',
                        repository: repository,
                        files: MemoryFiles(),
                      ),
                    ),
                  );
                },
                child: const Text('Mở Excel'),
              ),
            ),
          ),
        ),
      );
      await tapText(tester, 'Mở Excel');
      await tapText(tester, 'Chọn file và kiểm tra');
      expect(repository.imports, 0);
      await tapText(tester, 'Xác nhận nhập 1 dòng');
      expect(imported, 1);
      expect(repository.imports, 1);
      expect(find.byType(ExcelPage), findsNothing);
    },
  );

  testWidgets(
    'Changed data between preview and confirmation stays on error screen',
    (tester) async {
      final repository = MemoryExcel()..changed = true;
      await tester.pumpWidget(page(repository, MemoryFiles()));
      await tapText(tester, 'Chọn file và kiểm tra');
      await tapText(tester, 'Xác nhận nhập 1 dòng');
      expect(find.byType(ExcelPage), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Dòng 2'), 200);
      await tester.pumpAndSettle();
      expect(find.text('Dòng 2'), findsOneWidget);
      expect(repository.imports, 1);
    },
  );

  testWidgets('File cancellation does not call import or preview', (
    tester,
  ) async {
    final repository = MemoryExcel();
    await tester.pumpWidget(page(repository, MemoryFiles()..cancel = true));
    await tapText(tester, 'Chọn file và kiểm tra');
    expect(repository.previews, 0);
    expect(repository.imports, 0);
  });

  testWidgets('Export and template write xlsx files for both modules', (
    tester,
  ) async {
    for (final module in ['listings', 'contracts']) {
      final repository = MemoryExcel(), files = MemoryFiles();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(page(repository, files, module: module));
      await tapText(tester, 'Xuất Excel');
      await tapText(tester, 'Tải file mẫu');
      expect(repository.downloads, [false, true]);
      expect(
        files.names,
        module == 'listings'
            ? ['tin-dang.xlsx', 'mau-tin-dang.xlsx']
            : ['hop-dong.xlsx', 'mau-hop-dong.xlsx'],
      );
    }
  });

  testWidgets('Tenant view only exposes contract export', (tester) async {
    await tester.pumpWidget(
      page(MemoryExcel(), MemoryFiles(), landlord: false, module: 'contracts'),
    );
    expect(find.text('Xuất Excel'), findsOneWidget);
    expect(find.text('Tải file mẫu'), findsNothing);
    expect(find.text('Chọn file và kiểm tra'), findsNothing);
  });

  testWidgets('Excel screen supports large text on phone tablet and desktop', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    for (final width in [320.0, 800.0, 1440.0]) {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.binding.setSurfaceSize(Size(width, 850));
      await tester.pumpWidget(
        page(
          MemoryExcel()..invalid = true,
          MemoryFiles(),
          module: 'contracts',
          scale: 2,
        ),
      );
      await tapText(tester, 'Chọn file và kiểm tra');
      await tester.scrollUntilVisible(find.text('Xác nhận nhập 1 dòng'), 200);
      await tester.ensureVisible(find.text('Xác nhận nhập 1 dòng'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });
}
