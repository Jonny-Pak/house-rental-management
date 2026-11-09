import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/home/presentation/pages/main_page.dart';
import 'package:frontend/features/home/presentation/widgets/user_navigation_drawer.dart';
import 'package:frontend/features/listing/presentation/pages/listing_browse_page.dart';
import 'package:frontend/features/user/data/models/user_profile.dart';

import 'home_listings_fixture.dart';
import 'notification_test.dart' show MemoryNotifications;
import 'responsive_ui_test.dart' show TestProfileRepository;

const profile = UserProfile(
  id: 1,
  fullName: 'Ngọc Thuận',
  email: 'thuan@example.com',
  phoneNumber: '0901234567',
  membershipPackageName: 'Gói PRO',
  subscriptionStatus: 'ACTIVE',
  remainingStandardQuota: 12,
);

void main() {
  testWidgets(
    'Drawer shows actual profile, package and dispatches every menu action',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 940));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      String? action;
      bool closed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UserNavigationDrawer(
              profile: profile,
              selectedAction: 'home',
              onAction: (value) => action = value,
              onClose: () => closed = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Ngọc Thuận'), findsOneWidget);
      expect(find.text('0901234567'), findsOneWidget);
      expect(find.text('thuan@example.com'), findsOneWidget);
      expect(find.text('Gói PRO'), findsOneWidget);
      expect(find.text('Còn 12 lượt đăng thường'), findsOneWidget);
      expect(
        tester
            .widget<ListTile>(find.byKey(const ValueKey('drawer-home')))
            .selected,
        isTrue,
      );
      await tester.tap(find.byTooltip('Đóng menu'));
      expect(closed, isTrue);
      await tester.tap(find.byKey(const ValueKey('drawer-profile-header')));
      expect(action, 'profile');
      for (final item in [
        'home',
        'search',
        'rent-house',
        'rent-room',
        'roommate',
        'post',
        'listings',
        'contracts',
        'membership',
        'map',
        'favorites',
        'notifications',
        'profile',
        'chatbot',
        'help',
      ]) {
        final target = find.byKey(ValueKey('drawer-$item'));
        await tester.scrollUntilVisible(
          target,
          100,
          scrollable: find.byType(Scrollable),
        );
        await tester.pumpAndSettle();
        await tester.tap(target);
        expect(action, item);
      }
      await tester.tap(find.byKey(const ValueKey('drawer-membership-card')));
      expect(action, 'membership');
      await tester.tap(find.text('Đăng xuất'));
      expect(action, 'logout');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Drawer fits enlarged text and never invents a paid membership', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    for (final size in [const Size(320, 640), const Size(640, 320)]) {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: Scaffold(
            body: UserNavigationDrawer(
              selectedAction: 'profile',
              onAction: (_) {},
              onClose: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Gói PRO'), findsNothing);
      expect(find.text('Gói dịch vụ'), findsWidgets);
      expect(
        tester.getRect(find.text('Đăng xuất')).bottom,
        lessThan(size.height),
      );
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('Drawer closes and opens rental pages with the right filters', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: MainPage(
          userRepository: TestProfileRepository(),
          notificationRepository: MemoryNotifications(),
          listingRepository: HomeListings(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final types = {
      'rent-house': 'WHOLE_HOUSE',
      'rent-room': 'BOARDING_ROOM',
      'roommate': 'SHARED_ROOM',
      'search': null,
    };
    for (final action in types.keys) {
      await tester.tap(find.byTooltip('Mở menu'));
      await tester.pumpAndSettle();
      final target = find.byKey(ValueKey('drawer-$action'));
      await tester.ensureVisible(target);
      await tester.pumpAndSettle();
      await tester.tap(target);
      await tester.pumpAndSettle();
      expect(find.byType(Drawer), findsNothing);
      final page = tester.widget<ListingBrowsePage>(
        find.byType(ListingBrowsePage),
      );
      expect(page.listingType, types[action]);
      Navigator.of(tester.element(find.byType(ListingBrowsePage))).pop();
      await tester.pumpAndSettle();
    }
    expect(tester.takeException(), isNull);
  });
}
