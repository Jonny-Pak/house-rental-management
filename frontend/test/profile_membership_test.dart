import 'package:flutter/material.dart';
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
  @override
  Future<UserProfile> getProfile() async => profile;
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
    expect(find.text('Đang sử dụng'), findsOneWidget);
    expect(find.text('18 Tin thường'), findsOneWidget);
    expect(find.text('3 Tin VIP'), findsOneWidget);
    expect(find.text('8 Làm mới'), findsOneWidget);
    expect(find.text('Xem & nâng cấp gói'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('No package and inactive package are shown accurately', (
    tester,
  ) async {
    await tester.pumpWidget(page(member(package: null, status: null)));
    await tester.pumpAndSettle();
    expect(find.text('Chưa đăng ký gói'), findsOneWidget);
    expect(find.text('Đang sử dụng'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(page(member(status: 'EXPIRED')));
    await tester.pumpAndSettle();
    expect(find.text('Gói hiện không hoạt động'), findsOneWidget);
    expect(find.text('Đang sử dụng'), findsNothing);
    expect(find.text('18 Tin thường'), findsNothing);
    expect(tester.takeException(), isNull);
  });

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
