import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/listing/presentation/cubit/create_listing_cubit.dart';
import 'package:frontend/features/listing/presentation/pages/listing_details_step.dart';

void main() {
  testWidgets(
    'House details preserve validation, selection and counter actions',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final cubit = CreateListingCubit()..updatePropertyType('WHOLE_HOUSE');
      addTearDown(cubit.close);
      var next = false;
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: cubit,
            child: ListingDetailsStep(onNext: () => next = true, onBack: () {}),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      await tester.tap(find.byType(DropdownButton<String>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Nhà ngõ hẻm').last);
      await tester.pumpAndSettle();
      expect(cubit.state.houseType, 'NGO_HEM');
      await tester.tap(find.byTooltip('Tăng Phòng ngủ *'));
      await tester.tap(find.byTooltip('Tăng Phòng tắm *'));
      await tester.pumpAndSettle();
      expect(cubit.state.bedrooms, 1);
      expect(cubit.state.bathrooms, 1);
      await tester.tap(find.byTooltip('Giảm Phòng ngủ *'));
      await tester.pumpAndSettle();
      expect(cubit.state.bedrooms, 0);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      await tester.tap(find.byTooltip('Tăng Phòng ngủ *'));
      final furniture = find.byType(DropdownButton<String>).last;
      await tester.ensureVisible(furniture);
      await tester.pumpAndSettle();
      await tester.tap(furniture);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Nội thất cơ bản').last);
      await tester.pumpAndSettle();
      expect(cubit.state.furnitureStatus, 'BASIC');
      await tester.tap(find.text('Tiếp tục'));
      expect(next, isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Details adapt to narrow screens, large text and room listings', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final cubit = CreateListingCubit()..updatePropertyType('WHOLE_HOUSE');
    addTearDown(cubit.close);
    for (final width in [320.0, 800.0, 1440.0]) {
      await tester.binding.setSurfaceSize(Size(width, 700));
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: BlocProvider.value(
            value: cubit,
            child: ListingDetailsStep(onNext: () {}, onBack: () {}),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Tình trạng nội thất *'),
        200,
        scrollable: find.byType(Scrollable),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
    cubit.updatePropertyType('BOARDING_ROOM');
    await tester.pumpAndSettle();
    expect(find.text('Không gian & kết cấu'), findsNothing);
    expect(find.text('Nội thất phòng trọ'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    cubit.updateFurnitureStatus('EMPTY');
    await tester.pumpAndSettle();
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );
    expect(tester.takeException(), isNull);
  });
}
