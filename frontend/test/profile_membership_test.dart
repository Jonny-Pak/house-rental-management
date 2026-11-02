import 'package:flutter/material.dart';
import 'package:frontend/features/home/presentation/pages/main_page.dart';

import 'home_listings_fixture.dart';
import 'notification_test.dart' show MemoryNotifications;

import 'package:frontend/features/auth/presentation/pages/password_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:frontend/features/user/data/models/user_profile.dart';
import 'package:frontend/features/user/data/repositories/user_repository.dart';
import 'package:frontend/features/user/presentation/bloc/profile_bloc.dart';
import 'package:frontend/features/user/presentation/bloc/profile_event.dart';
import 'package:frontend/features/user/presentation/pages/profile_page.dart';

class ProfileRepository implements UserRepository {
  ProfileRepository(this.profile);
  final UserProfile profile;
  int loads = 0;
  @override
  Future<UserProfile> getProfile() async {
    loads++;
    return profile;
  }

  @override
  Future<UserProfile> updateAvatar(String url) async => profile;
  @override
  Future<String> uploadImage(XFile file) async => '';
}

UserProfile member({String? status = 'ACTIVE', String? package = 'Gói PRO'}) =>
    UserProfile(
      id: 1,
      fullName: 'Ngọc Thuận',
      email: 'thuan@example.com',
      phoneNumber: '0901234567',
      listingCount: 3,
      contractCount: 2,
      savedListingCount: 12,
      interests: const ['CAT_LOVER', 'TIDY', 'STUDY'],
      membershipPackageName: package,
      subscriptionStatus: status,
      remainingStandardQuota: 18,
      remainingVipQuota: 3,
      remainingRefreshQuota: 8,
    );

Widget page(UserProfile profile, {bool large = false}) => MaterialApp(
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context)
        .copyWith(textScaler: TextScaler.linear(large ? 2 : 1)),
    child: child!,
  ),
  home: BlocProvider(
    create: (_) =>
        ProfileBloc(ProfileRepository(profile))..add(FetchProfileEvent()),
    child: const ProfilePage(),
  ),
);

void main() {
  test('Profile parses subscription fields and supports old responses', () {
    final json = {'id': 1, 'fullName': 'Thuận', 'email': 'thuan@example.com'};
    expect(UserProfile.fromJson(json).membershipPackageName, isNull);
    expect(UserProfile.fromJson(json).listingCount, isNull);
    final counts = UserProfile.fromJson({
      ...json,
      'listingCount': 3,
      'contractCount': 2,
      'savedListingCount': 12,
    });
    expect(counts.withInterests(['CAT_LOVER']).listingCount, 3);
    expect(counts.contractCount, 2);
    expect(counts.savedListingCount, 12);
    final profile = UserProfile.fromJson({
      ...json,
      'membershipPackageName': 'Gói PLUS',
      'subscriptionStatus': 'ACTIVE',
      'remainingStandardQuota': 0,
      'remainingVipQuota': 0,
      'remainingRefreshQuota': 5,
    });
    expect(profile.membershipPackageName, 'Gói PLUS');
    expect(profile.remainingStandardQuota, 0);
  });

  testWidgets('Profile shows active package and actual remaining quotas', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 950));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(page(member()));
    await tester.pumpAndSettle();
    expect(find.text('Gói PRO'), findsOneWidget);
    expect(find.text('Người yêu mèo'), findsOneWidget);
    expect(find.text('Sạch sẽ, gọn gàng'), findsOneWidget);
    expect(find.text('Học bá'), findsOneWidget);
    expect(find.text('Hạng PRO'), findsOneWidget);
    final name = tester.getRect(find.byKey(const ValueKey('profile-name')));
    final avatar = tester.getRect(find.byKey(const ValueKey('profile-avatar')));
    final rank = tester.getRect(find.byKey(const ValueKey('profile-rank')));
    final interests = tester.getRect(
      find.widgetWithText(Chip, 'Người yêu mèo'),
    );
    expect(avatar.right, lessThan(name.left));
    expect(rank.top, greaterThan(avatar.bottom));
    expect(interests.top, greaterThan(rank.bottom));
    expect(find.text('Đang sử dụng'), findsOneWidget);
    expect(find.text('18 Tin thường'), findsOneWidget);
    expect(find.text('3 Tin VIP'), findsOneWidget);
    expect(find.text('8 Làm mới'), findsOneWidget);
    expect(find.text('Xem gói'), findsOneWidget);
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('profile-listings-count')))
          .data,
      '3',
    );
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('profile-contracts-count')))
          .data,
      '2',
    );
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('profile-saved-count')))
          .data,
      '12',
    );
    expect(find.text('Trợ lý AI'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('No package and inactive package are shown accurately', (
    tester,
  ) async {
    await tester.pumpWidget(page(member(package: null, status: null)));
    await tester.pumpAndSettle();
    expect(find.text('Chưa đăng ký gói'), findsOneWidget);
    expect(find.text('Hạng FREE'), findsOneWidget);
    expect(find.text('Đang sử dụng'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(page(member(status: 'EXPIRED')));
    await tester.pumpAndSettle();
    expect(find.text('Gói hiện không hoạt động'), findsOneWidget);
    expect(find.text('Hạng FREE'), findsOneWidget);
    expect(find.text('Đang sử dụng'), findsNothing);
    expect(find.text('18 Tin thường'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Personal information and settings open the existing account actions',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 950));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(page(member()));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Thông tin cá nhân'));
      await tester.pumpAndSettle();
      expect(find.byType(SelectableText), findsNWidgets(3));
      Navigator.of(tester.element(find.byType(ProfilePage))).pop();
      await tester.pumpAndSettle();
      final settings = find.widgetWithText(ListTile, 'Cài đặt');
      await tester.scrollUntilVisible(
        settings,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(settings);
      await tester.pumpAndSettle();
      expect(find.text('Khu trọ đã lưu'), findsOneWidget);
      expect(find.text('Báo cáo sự cố của tôi'), findsOneWidget);
      await tester.tap(find.widgetWithText(ListTile, 'Đổi mật khẩu'));
      await tester.pumpAndSettle();
      expect(find.byType(PasswordPage), findsOneWidget);
      Navigator.of(tester.element(find.byType(PasswordPage))).pop();
      await tester.pumpAndSettle();
      expect(find.byType(ProfilePage), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Opening profile and returning from posting reloads the account statistics',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 950));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final repository = ProfileRepository(member());
      await tester.pumpWidget(
        MaterialApp(
          home: MainPage(
            userRepository: repository,
            listingRepository: HomeListings(),
            notificationRepository: MemoryNotifications(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(repository.loads, 1);
      await tester.tap(find.byTooltip('Tài khoản'));
      await tester.pumpAndSettle();
      expect(repository.loads, 2);
      await tester.tap(find.byKey(const ValueKey('bottom-nav-2')));
      await tester.pumpAndSettle();
      expect(find.text('Đăng tin mới'), findsOneWidget);
      Navigator.of(tester.element(find.text('Đăng tin mới'))).pop();
      await tester.pumpAndSettle();
      expect(repository.loads, 3);
      expect(find.byType(ProfilePage), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Profile supports large text on narrow and wide screens', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    for (final width in [320.0, 800.0, 1440.0]) {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.binding.setSurfaceSize(Size(width, 850));
      await tester.pumpWidget(page(member(), large: true));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Đăng xuất'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });
}
