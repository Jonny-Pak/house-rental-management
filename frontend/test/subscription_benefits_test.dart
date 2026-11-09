import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/listing/data/models/listing_filter.dart';
import 'package:frontend/features/listing/data/models/listing_model.dart';
import 'package:frontend/features/listing/data/repositories/listing_repository.dart';
import 'package:frontend/features/listing/presentation/pages/my_listings_page.dart';
import 'package:frontend/features/membership/data/models/subscription_benefits.dart';
import 'package:frontend/features/membership/presentation/pages/subscription_benefits_page.dart';

class BenefitRepository extends ListingRepository {
  BenefitRepository() : super(ApiClient());
  bool failRead = false, failAction = false, expired = false;
  int vipCalls = 0, refreshCalls = 0;
  List<Listing> items = [listing(1)];

  @override
  Future<SubscriptionBenefits> fetchBenefits() async {
    if (failRead) throw Exception('Không tải được quyền lợi');
    return SubscriptionBenefits(
      packageName: 'Gói PRO',
      status: expired ? 'EXPIRED' : 'ACTIVE',
      standard: expired ? 0 : 10,
      vip: expired ? 0 : 2,
      refresh: expired ? 0 : 5,
      expiresAt: DateTime(2027, 1, 1),
    );
  }

  @override
  Future<List<Listing>> fetchMyListings() async => items;
  @override
  Future<void> promoteVip(int id) async {
    vipCalls++;
    if (failAction) throw Exception('Bạn đã hết lượt nâng VIP');
    items = [listing(id, vip: true)];
  }

  @override
  Future<void> refreshListing(int id) async {
    refreshCalls++;
    if (failAction) {
      throw Exception('Mỗi tin chỉ được làm mới một lần trong 24 giờ');
    }
  }
}

Listing listing(
  int id, {
  bool vip = false,
  bool expired = false,
  String approval = 'APPROVED',
  String rental = 'AVAILABLE',
  String? refreshed,
}) => Listing.fromJson({
  'id': id,
  'title': 'Tin kiểm thử $id',
  'rentPrice': id * 1000000,
  'areaSqm': 30,
  'approvalStatus': approval,
  'rentalStatus': rental,
  'isVip': vip,
  'vipExpiresAt': DateTime.now()
      .add(Duration(days: expired ? -1 : 30))
      .toIso8601String(),
  'createdAt': '2026-01-0${id}T12:00:00',
  'refreshedAt': refreshed,
});

Future<void> openMenu(WidgetTester tester) async {
  await tester.ensureVisible(find.byTooltip('Thao tác tin 1'));
  await tester.pumpAndSettle();
  await tester.tap(find.byTooltip('Thao tác tin 1'));
  await tester.pumpAndSettle();
}

void main() {
  test('Default order uses active VIP and refresh; explicit price sort stays correct', () {
    final vip = listing(1, vip: true);
    final refreshed = listing(2, refreshed: '2026-12-01T12:00:00');
    final normal = listing(3);
    expect(
      const ListingFilter()
          .apply([normal, refreshed, vip])
          .map((item) => item.id),
      [1, 2, 3],
    );
    expect(
      const ListingFilter(sort: 'priceDesc')
          .apply([normal, vip])
          .map((item) => item.id),
      [3, 1],
    );
    expect(
      const ListingFilter()
          .apply([listing(1, vip: true, expired: true), normal])
          .first
          .id,
      3,
    );
    expect(listing(1, vip: true, expired: true).isVip, isFalse);
  });

  testWidgets(
    'Benefits page loads actual balances and retries a failed request',
    (tester) async {
      final repository = BenefitRepository()..failRead = true;
      await tester.pumpWidget(
        MaterialApp(home: SubscriptionBenefitsPage(repository: repository)),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Không tải được quyền lợi'), findsOneWidget);
      repository.failRead = false;
      await tester.tap(find.text('Thử lại'));
      await tester.pumpAndSettle();
      expect(find.text('Gói PRO'), findsOneWidget);
      expect(find.text('10'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Expired package shows no usable balance on a narrow screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: SubscriptionBenefitsPage(
          repository: BenefitRepository()..expired = true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Gói đã hết hạn'), findsOneWidget);
    expect(find.text('0'), findsNWidgets(3));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'VIP requires confirmation; success reloads card and blocks another VIP action',
    (tester) async {
      final repository = BenefitRepository();
      await tester.pumpWidget(
        MaterialApp(home: MyListingsPage(repository: repository)),
      );
      await tester.pumpAndSettle();
      await openMenu(tester);
      await tester.tap(find.text('Nâng VIP · 1 lượt'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hủy'));
      await tester.pumpAndSettle();
      expect(repository.vipCalls, 0);
      await openMenu(tester);
      await tester.tap(find.text('Nâng VIP · 1 lượt'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sử dụng 1 lượt'));
      await tester.pumpAndSettle();
      expect(repository.vipCalls, 1);
      await openMenu(tester);
      expect(find.text('Nâng VIP · 1 lượt'), findsNothing);
      expect(find.text('Làm mới tin · 1 lượt'), findsOneWidget);
    },
  );

  testWidgets('Refresh error is visible and a retry calls refresh only', (
    tester,
  ) async {
    final repository = BenefitRepository()..failAction = true;
    await tester.pumpWidget(
      MaterialApp(home: MyListingsPage(repository: repository)),
    );
    await tester.pumpAndSettle();
    await openMenu(tester);
    await tester.tap(find.text('Làm mới tin · 1 lượt'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sử dụng 1 lượt'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Mỗi tin chỉ được làm mới'), findsOneWidget);
    expect(repository.refreshCalls, 1);
    expect(repository.vipCalls, 0);
    repository.failAction = false;
    await openMenu(tester);
    await tester.tap(find.text('Làm mới tin · 1 lượt'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sử dụng 1 lượt'));
    await tester.pumpAndSettle();
    expect(find.text('Đã làm mới tin.'), findsOneWidget);
    expect(repository.refreshCalls, 2);
  });

  testWidgets('Pending or hidden listings have no promotion actions', (
    tester,
  ) async {
    final repository = BenefitRepository()
      ..items = [listing(1, approval: 'PENDING')];
    await tester.pumpWidget(
      MaterialApp(home: MyListingsPage(repository: repository)),
    );
    await tester.pumpAndSettle();
    await openMenu(tester);
    expect(find.text('Nâng VIP · 1 lượt'), findsNothing);
    expect(find.text('Làm mới tin · 1 lượt'), findsNothing);
  });

  testWidgets('Owner can open current balances from listing management', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: MyListingsPage(repository: BenefitRepository())),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Quyền lợi của tôi'));
    await tester.pumpAndSettle();
    expect(find.text('Gói PRO'), findsOneWidget);
    expect(find.text('Lượt đăng tin còn lại'), findsOneWidget);
  });
}
