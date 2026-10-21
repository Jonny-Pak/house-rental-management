import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:frontend/features/listing/presentation/cubit/create_listing_cubit.dart';
import 'package:frontend/features/listing/presentation/pages/listing_location_map_step.dart';

void main() {
  testWidgets('Location layout adapts and confirms the selected pin', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final cubit = CreateListingCubit();
    addTearDown(cubit.close);
    var confirmed = false;
    for (final size in [
      const Size(320, 580),
      const Size(430, 860),
      const Size(1440, 900),
    ]) {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: cubit,
            child: ListingLocationMapStep(onConfirm: () => confirmed = true),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Vị trí & diện tích'), findsOneWidget);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      expect(tester.takeException(), isNull);
    }
    cubit.updateAddress('Nguyễn Bình, TP.HCM');
    cubit.updatePinnedLocation(const LatLng(10.7769, 106.7009));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xác nhận vị trí'));
    expect(confirmed, isTrue);
    expect(tester.takeException(), isNull);
    await tester.binding.setSurfaceSize(const Size(320, 580));
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: BlocProvider.value(
          value: cubit,
          child: const ListingLocationMapStep(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('Vẽ diện tích'));
    cubit.addPolygonPoint(const LatLng(10.7769, 106.7009));
    cubit.addPolygonPoint(const LatLng(10.7770, 106.7009));
    cubit.addPolygonPoint(const LatLng(10.7770, 106.7010));
    await tester.pumpAndSettle();
    expect(find.text('Đang vẽ · 3 điểm'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
