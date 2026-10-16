import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/app/admin/admin_app.dart';
import 'package:frontend/app/admin/auth/session.dart';
import 'package:frontend/app/admin/router/app_router.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/admin/data/models/admin_listing_model.dart';
import 'package:frontend/features/admin/data/repositories/admin_listing_repository.dart';
import 'package:frontend/features/admin/presentation/pages/admin_dashboard_page.dart';
import 'package:frontend/shared/admin/layout/app_shell.dart';

class TestAdminSession extends SessionController {
  @override
  SessionUser? build() =>
      const SessionUser(name: 'Admin', email: 'admin@example.com');
}

class TestAdminListings extends AdminListingRepository {
  TestAdminListings() : super(ApiClient());
  @override
  Future<List<AdminListingModel>> getPendingListings() async => [
    AdminListingModel(
      id: 1,
      title: 'Nhà cho thuê thử nghiệm',
      description: 'Nhà đầy đủ tiện nghi.',
      address: 'Phường Tân Mỹ, Thành phố Hồ Chí Minh',
      rentPrice: 5000000,
      areaSqm: 45,
      approvalStatus: 'PENDING',
      ownerName: 'Chủ nhà',
      listingType: 'WHOLE_HOUSE',
    ),
  ];
}

void main() {
  testWidgets('Admin uses cards on compact windows and a table on desktop', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final router = GoRouter(
      initialLocation: '/listings',
      routes: [
        GoRoute(
          path: '/listings',
          builder: (_, _) => AppShell(
            location: '/listings',
            child: AdminDashboardPage(repository: TestAdminListings()),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      return tester.binding.setSurfaceSize(null);
    });
    await resize(tester, const Size(390, 860));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionProvider.overrideWith(TestAdminSession.new),
          routerProvider.overrideWithValue(router),
        ],
        child: const KiteApp(),
      ),
    );
    await tester.pumpAndSettle();
    for (final width in [320.0, 820.0, 1024.0, 1440.0]) {
      await resize(tester, Size(width, 900));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Nhà cho thuê thử nghiệm'));
      await tester.pumpAndSettle();
      expect(find.text('Xem xét'), findsOneWidget);
      expect(
        find.text('Phê duyệt'),
        width < 1440 ? findsOneWidget : findsNothing,
        reason: 'Width: $width',
      );
      expect(tester.takeException(), isNull, reason: 'Width: $width');
    }
    await resize(tester, const Size(320, 720));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Xem xét'));
    await tester.tap(find.text('Xem xét'));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}

Future<void> resize(WidgetTester tester, Size size) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  await tester.binding.setSurfaceSize(size);
}
