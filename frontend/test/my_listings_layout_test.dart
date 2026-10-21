import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/listing/data/models/listing_model.dart';
import 'package:frontend/features/listing/presentation/pages/my_listings_page.dart';

import 'listing_flow_test.dart' show FakeListingRepository;

class OwnerRepository extends FakeListingRepository {
  String? action;
  int? deleted;
  @override
  Future<void> updateRentalStatus(int id, String status) async {
    action = status;
  }

  @override
  Future<void> deleteListing(int id) async {
    deleted = id;
    items.removeWhere((listing) => listing.id == id);
  }
}

void main() {
  testWidgets('Owner filters listings and keeps status and deletion actions', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 950));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = OwnerRepository()
      ..items = [
        Listing(
          id: 1,
          title: 'Nhà đang cho thuê',
          rentPrice: 7500000,
          areaSqm: 30,
          approvalStatus: 'APPROVED',
        ),
        Listing(
          id: 2,
          title: 'Phòng đang chờ duyệt',
          rentPrice: 3000000,
          areaSqm: 20,
        ),
      ];
    await tester.pumpWidget(
      MaterialApp(home: MyListingsPage(repository: repository)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Chờ duyệt'));
    await tester.pumpAndSettle();
    expect(find.text('Nhà đang cho thuê'), findsNothing);
    expect(find.text('Phòng đang chờ duyệt'), findsOneWidget);
    await tester.tap(find.byTooltip('Thao tác tin 2'));
    await tester.pumpAndSettle();
    expect(find.text('Sửa và gửi duyệt lại'), findsOneWidget);
    expect(find.text('Đánh dấu đã cho thuê'), findsOneWidget);
    await tester.tap(find.text('Ẩn tin'));
    await tester.pumpAndSettle();
    expect(repository.action, 'HIDDEN');
    await tester.tap(find.byTooltip('Thao tác tin 2'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xóa tin'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hủy'));
    await tester.pumpAndSettle();
    expect(repository.deleted, isNull);
    await tester.tap(find.byTooltip('Thao tác tin 2'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xóa tin'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xóa'));
    await tester.pumpAndSettle();
    expect(repository.deleted, 2);
    expect(find.text('Chưa có tin đăng trong danh sách này.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Owner cards adapt to large text and screen widths', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = OwnerRepository()
      ..items = [
        Listing(
          id: 1,
          title: 'Cho thuê nhà nguyên căn gần trung tâm thành phố',
          address: '845/3a Nguyễn Bình, Xã Hiệp Phước, Thành phố Hồ Chí Minh',
          rentPrice: 7500000,
          areaSqm: 30,
          approvalStatus: 'REJECTED',
          rejectionReason: 'Vui lòng bổ sung ảnh rõ hơn',
        ),
      ];
    for (final width in [320.0, 800.0, 1440.0]) {
      await tester.binding.setSurfaceSize(Size(width, 800));
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: MyListingsPage(repository: repository),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Lý do từ chối: Vui lòng bổ sung ảnh rõ hơn'),
        150,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });
}
