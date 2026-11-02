import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/admin/presentation/pages/admin_amenities_page.dart';

import 'amenity_fixture.dart';

Future<void> open(
  WidgetTester tester,
  MemoryAmenities repository, {
  double width = 1440,
  double scale = 1,
}) async {
  await tester.binding.setSurfaceSize(Size(width, 1100));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: Scaffold(body: AdminAmenitiesPage(repository: repository)),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> press(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'Admin creates a category and preserves input when saving fails',
    (tester) async {
      final repository = MemoryAmenities();
      await open(tester, repository);
      await press(tester, find.text('Thêm danh mục'));
      await press(tester, find.text('Lưu danh mục'));
      expect(repository.saves, 0);
      expect(find.text('Vui lòng nhập tên.'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('amenity-name')),
        'Tủ quần áo',
      );
      repository.failSave = true;
      await press(tester, find.text('Lưu danh mục'));
      expect(find.textContaining('Danh mục đã thay đổi'), findsOneWidget);
      expect(find.text('Tủ quần áo'), findsOneWidget);
      repository.failSave = false;
      await press(tester, find.text('Lưu danh mục'));
      expect(repository.saves, 1);
      expect(repository.saved!['name'], 'Tủ quần áo');
      expect(find.text('Tủ quần áo'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Used items cannot be deleted or change group and status requires confirmation',
    (tester) async {
      final repository = MemoryAmenities();
      await open(tester, repository);
      final delete = find.byWidgetPredicate(
        (widget) =>
            widget is IconButton &&
            widget.tooltip == 'Đã có tin sử dụng Giường',
      );
      expect(tester.widget<IconButton>(delete).onPressed, isNull);
      await press(tester, find.byTooltip('Sửa Giường'));
      final dropdown = find.descendant(
        of: find.byKey(const ValueKey('amenity-category')),
        matching: find.byWidgetPredicate(
          (widget) => widget is DropdownButton<String>,
        ),
      );
      expect(tester.widget<DropdownButton<String>>(dropdown).onChanged, isNull);
      await press(tester, find.text('Hủy'));
      await press(tester, find.byTooltip('Ngừng sử dụng Giường'));
      expect(repository.statuses, 0);
      await press(tester, find.text('Xác nhận'));
      expect(repository.statuses, 1);
      expect(
        (await repository.activeItems()).any((item) => item.id == 1),
        isFalse,
      );
      await press(tester, find.byTooltip('Sử dụng lại Giường'));
      await press(tester, find.text('Xác nhận'));
      expect(repository.statuses, 2);
      await press(tester, find.byTooltip('Xóa Wi-Fi'));
      expect(repository.deletes, 0);
      await press(tester, find.text('Xác nhận'));
      expect(repository.deletes, 1);
      expect(find.text('Wi-Fi'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Filtering, pagination and load retry call the real repository parameters',
    (tester) async {
      final repository = MemoryAmenities()..failLoad = true;
      await open(tester, repository);
      expect(find.text('Không tải được danh mục.'), findsOneWidget);
      repository.failLoad = false;
      await press(tester, find.text('Thử lại'));
      await tester.enterText(
        find.byKey(const ValueKey('amenity-search')),
        'Wi-Fi',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(find.text('Giường'), findsNothing);
      expect(find.text('Wi-Fi'), findsNWidgets(2));
      await press(tester, find.text('Xóa bộ lọc'));
      for (var id = 3; id <= 22; id++) {
        repository.rows[id] = {
          ...repository.rows[2]!,
          'id': id,
          'name': 'Tiện ích $id',
        };
      }
      await press(tester, find.text('Làm mới'));
      await press(tester, find.byTooltip('Trang sau'));
      expect(repository.lastPage, 1);
      await press(tester, find.byTooltip('Trang trước'));
      expect(repository.lastPage, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Small enlarged catalog and editor remain usable', (
    tester,
  ) async {
    final repository = MemoryAmenities();
    await open(tester, repository, width: 320, scale: 2);
    expect(tester.takeException(), isNull);
    await press(tester, find.text('Thêm danh mục'));
    expect(find.byKey(const ValueKey('amenity-name')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
