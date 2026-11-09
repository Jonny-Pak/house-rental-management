import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/listing/presentation/cubit/create_listing_cubit.dart';
import 'package:frontend/features/listing/presentation/pages/listing_pricing_step.dart';

import 'area_selector_test.dart' show FakeAreas, selectProvince;

Future<void> enterField(WidgetTester tester, String hint, String value) async {
  final field = find.widgetWithText(TextField, hint);
  await tester.scrollUntilVisible(
    field,
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
  await tester.enterText(field, value);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'Pricing form preserves area selection, editing and action validation',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 950));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final cubit = CreateListingCubit();
      addTearDown(cubit.close);
      var previewed = false;
      var submitted = false;
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: cubit,
            child: ListingPricingStep(
              areas: FakeAreas(),
              onBack: () {},
              onPreview: () => previewed = true,
              onSubmit: () => submitted = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      await enterField(tester, 'Ví dụ: 30', '35,5');
      expect(cubit.state.calculatedArea, 35.5);
      await selectProvince(tester);
      await tester.tap(find.text('Chọn phường / xã / đặc khu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Phường Sài Gòn'));
      await tester.pumpAndSettle();
      expect(cubit.state.areaId, 10);
      cubit.addImages([File('assets/images/home/room.webp').absolute.path]);
      await enterField(tester, 'Nhập giá thuê', '4500000');
      await enterField(tester, 'Nhập số tiền cọc (nếu có)', '4500000');
      final poster = find.byType(DropdownButton<String>);
      await tester.scrollUntilVisible(
        poster,
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(poster);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cá nhân (Chủ nhà)').last);
      await tester.pumpAndSettle();
      await enterField(
        tester,
        'VD: Cho thuê nhà nguyên căn 2 tầng...',
        'Nhà cho thuê gần trung tâm',
      );
      await enterField(
        tester,
        'Mô tả thêm về tiện ích, an ninh, điện nước...',
        'Nhà thoáng, có bếp và chỗ để xe.',
      );
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Xem trước'));
      await tester.tap(find.text('Đăng tin'));
      expect(previewed, isTrue);
      expect(submitted, isTrue);
      expect(cubit.state.rentPrice, 4500000);
      expect(cubit.state.depositAmount, 4500000);
      await tester.scrollUntilVisible(
        find.byTooltip('Xóa ảnh 1'),
        -200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Xóa ảnh 1'));
      await tester.pumpAndSettle();
      expect(cubit.state.imagePaths, isEmpty);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Pricing supports large text and different screen widths', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final cubit = CreateListingCubit()..updatePosterType('CA_NHAN');
    addTearDown(cubit.close);
    for (final width in [320.0, 800.0, 1440.0]) {
      await tester.binding.setSurfaceSize(Size(width, 780));
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: BlocProvider.value(
            value: cubit,
            child: ListingPricingStep(
              areas: FakeAreas(),
              onBack: () {},
              onPreview: () {},
              onSubmit: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Nội dung tin đăng'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.widgetWithText(
          TextField,
          'Mô tả thêm về tiện ích, an ninh, điện nước...',
        ),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.text('Xem trước'), findsOneWidget);
      expect(find.text('Đăng tin'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });
}
