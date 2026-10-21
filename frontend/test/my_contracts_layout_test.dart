import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/contract/presentation/pages/my_contracts_page.dart';
import 'package:frontend/features/contract/data/models/contract_model.dart';

import 'contract_management_test.dart' show FakeContracts, lease;

class EmptyContracts extends FakeContracts {
  @override
  Future<List<ContractModel>> getMyContracts() async => [];
}

void main() {
  testWidgets('Contract list filters, resets and opens the detail page', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(home: MyContractsPage(repository: FakeContracts())),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Đã hết hạn').last);
    await tester.pumpAndSettle();
    expect(find.text('Chưa có hợp đồng phù hợp.'), findsOneWidget);
    await tester.tap(find.text('Xem tất cả hợp đồng'));
    await tester.pumpAndSettle();
    expect(find.text('Nhà cho thuê'), findsOneWidget);
    await tester.tap(find.text('Nhà cho thuê'));
    await tester.pumpAndSettle();
    expect(find.text('Hợp đồng #1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Contract cards and empty state adapt to large text', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = FakeContracts()
      ..current = lease(role: 'LANDLORD', status: 'ACTIVE');
    for (final width in [320.0, 800.0, 1440.0]) {
      await tester.binding.setSurfaceSize(Size(width, 800));
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: MyContractsPage(isLandlord: true, repository: repository),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Người thuê: Người thuê'),
        150,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pumpAndSettle();
      expect(find.text('Tạo hợp đồng'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.binding.setSurfaceSize(const Size(320, 800));
    await tester.pumpWidget(
      MaterialApp(home: MyContractsPage(repository: EmptyContracts())),
    );
    await tester.pumpAndSettle();
    expect(find.text('Chưa có hợp đồng phù hợp.'), findsOneWidget);
    expect(find.text('Tạo hợp đồng'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
