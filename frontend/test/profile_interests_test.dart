import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/preferences/presentation/pages/preferences_page.dart';
import 'package:frontend/features/preferences/data/models/user_preference.dart';
import 'package:frontend/features/user/data/models/user_profile.dart';
import 'package:frontend/features/user/presentation/bloc/profile_bloc.dart';
import 'package:frontend/features/user/presentation/bloc/profile_event.dart';
import 'package:frontend/features/user/presentation/pages/profile_page.dart';

import 'personal_interests_test.dart' show MemoryPreferences;
import 'profile_membership_test.dart' show ProfileRepository;

void main() {
  testWidgets(
    'Saving from the header shows five tags below FREE in a nested navigator',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 950));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final preferences = MemoryPreferences()..saved = const UserPreference();
      final repository = ProfileRepository(
        const UserProfile(id: 1, fullName: 'An', email: 'an@example.com'),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider(
            create: (_) => ProfileBloc(repository)..add(FetchProfileEvent()),
            child: PopScope(
              canPop: false,
              child: Navigator(
                onGenerateRoute: (_) => MaterialPageRoute(
                  builder: (_) =>
                      ProfilePage(preferenceRepository: preferences),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Sở thích của tôi'));
      await tester.pumpAndSettle();
      for (final code in [
        'CAT_LOVER',
        'DOG_LOVER',
        'PLANTS',
        'MUSIC',
        'MOVIES',
      ]) {
        final chip = find.byKey(ValueKey('interest-$code'));
        await tester.scrollUntilVisible(chip, 150);
        await tester.ensureVisible(chip);
        await tester.pumpAndSettle();
        await tester.tap(chip);
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text('Lưu sở thích'));
      await tester.pumpAndSettle();
      expect(find.byType(PreferencesPage), findsNothing);
      expect(find.byType(Chip), findsNWidgets(5));
      expect(
        find.text('Chọn tối đa 5 sở thích để giới thiệu bản thân.'),
        findsNothing,
      );
      final rank = tester.getRect(find.text('Hạng FREE'));
      for (final label in [
        'Người yêu mèo',
        'Người yêu chó',
        'Yêu cây xanh',
        'Nghe nhạc',
        'Xem phim',
      ]) {
        final tag = find.widgetWithText(Chip, label);
        expect(tag, findsOneWidget);
        expect(tester.getRect(tag).top, greaterThan(rank.bottom));
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Saving and clearing interests updates the actual profile route',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 950));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final preferences = MemoryPreferences();
      final repository = ProfileRepository(
        const UserProfile(
          id: 1,
          fullName: 'An',
          email: 'an@example.com',
          membershipPackageName: 'Gói PLUS',
          subscriptionStatus: 'ACTIVE',
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider(
            create: (_) => ProfileBloc(repository)..add(FetchProfileEvent()),
            child: ProfilePage(preferenceRepository: preferences),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final menu = find.widgetWithText(ListTile, 'Sở thích của tôi');
      await tester.scrollUntilVisible(menu, 200);
      await tester.ensureVisible(menu);
      await tester.pumpAndSettle();
      await tester.tap(menu);
      await tester.pumpAndSettle();
      expect(find.byType(PreferencesPage), findsOneWidget);
      await tester.tap(find.text('Lưu sở thích'));
      await tester.pumpAndSettle();
      expect(find.byType(PreferencesPage), findsNothing);
      await tester.drag(find.byType(ListView).first, const Offset(0, 1500));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(Chip, 'Người yêu mèo'), findsOneWidget);
      expect(find.text('Gói PLUS'), findsOneWidget);
      expect(find.text('Hạng PLUS'), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(menu, 200);
      await tester.ensureVisible(menu);
      await tester.pumpAndSettle();
      await tester.tap(menu);
      await tester.pumpAndSettle();
      final cat = find.byKey(const ValueKey('interest-CAT_LOVER'));
      await tester.ensureVisible(cat);
      await tester.pumpAndSettle();
      expect(tester.widget<FilterChip>(cat).selected, isTrue);
      await tester.tap(cat);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lưu sở thích'));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView).first, const Offset(0, 1500));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(Chip, 'Người yêu mèo'), findsNothing);
      expect(preferences.saved.interests, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );
}
