import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/preferences/data/models/user_preference.dart';
import 'package:frontend/features/preferences/data/repositories/preference_repository.dart';
import 'package:frontend/features/preferences/presentation/cubit/preferences_cubit.dart';
import 'package:frontend/features/preferences/presentation/cubit/preferences_state.dart';
import 'package:frontend/features/preferences/presentation/pages/preferences_page.dart';
import 'package:frontend/features/user/data/models/user_profile.dart';

class MemoryPreferences implements PreferenceRepository {
  UserPreference saved = const UserPreference(
    interests: ['CAT_LOVER'],
    minBudget: 1000000,
    preferredArea: 'TP HCM',
  );
  bool failLoad = false;
  bool failSave = false;
  int writes = 0;
  Completer<void>? pending;

  @override
  Future<UserPreference> getPreferences() async {
    if (failLoad) throw Exception('Không tải được');
    return saved;
  }

  @override
  Future<UserPreference> updatePreferences(UserPreference preference) async {
    writes++;
    if (pending != null) await pending!.future;
    if (failSave) throw Exception('Không lưu được');
    saved = preference;
    return saved;
  }
}

class OutdatedPreferences extends MemoryPreferences {
  @override
  Future<UserPreference> updatePreferences(UserPreference preference) async =>
      const UserPreference();
}

Widget interestsPage(MemoryPreferences repository, {double scale = 1}) =>
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: PreferencesPage(repository: repository),
    );

void main() {
  test('A response missing saved interests must not report success', () async {
    final cubit = PreferencesCubit(OutdatedPreferences());
    await cubit.loadInitialData();
    await cubit.updatePreferences();
    expect(cubit.state.status, PreferencesStatus.error);
    expect(cubit.state.interests, ['CAT_LOVER']);
    expect(
      cubit.state.errorMessage,
      contains('Máy chủ chưa lưu đúng sở thích'),
    );
    await cubit.close();
  });
  test(
    'Only five interests can be selected, removing one allows a replacement',
    () async {
      final repository = MemoryPreferences();
      final cubit = PreferencesCubit(repository);
      await cubit.loadInitialData();
      for (final code in ['QUIET', 'MUSIC', 'MOVIES', 'STUDY', 'TIDY']) {
        cubit.toggleInterest(code);
      }
      expect(cubit.state.interests.length, 5);
      expect(cubit.state.interests, isNot(contains('TIDY')));
      cubit.toggleInterest('MUSIC');
      cubit.toggleInterest('TIDY');
      await cubit.updatePreferences();
      expect(repository.saved.interests.length, 5);
      expect(repository.saved.interests, contains('TIDY'));
      await cubit.close();
    },
  );

  test(
    'Older selections exceeding five must be reduced before saving',
    () async {
      final repository = MemoryPreferences()
        ..saved = const UserPreference(
          interests: ['CAT_LOVER', 'QUIET', 'MUSIC', 'MOVIES', 'STUDY', 'TIDY'],
        );
      final cubit = PreferencesCubit(repository);
      await cubit.loadInitialData();
      await cubit.updatePreferences();
      expect(cubit.state.status, PreferencesStatus.error);
      expect(repository.writes, 0);
      cubit.toggleInterest('MUSIC');
      await cubit.updatePreferences();
      expect(repository.saved.interests.length, 5);
      await cubit.close();
    },
  );

  test(
    'Old data remains compatible and personal interests parse correctly',
    () {
      expect(UserPreference.fromJson({}).interests, isEmpty);
      expect(
        UserProfile.fromJson({'id': 1, 'fullName': 'An', 'email': 'a@b.vn'})
            .interests,
        isEmpty,
      );
      final preference = UserPreference.fromJson({
        'interests': ['QUIET', 'STUDY'],
      });
      expect(preference.toJson()['interests'], ['QUIET', 'STUDY']);
    },
  );

  test(
    'Save, reload and clear selections while preserving previous metadata',
    () async {
      final repository = MemoryPreferences();
      final cubit = PreferencesCubit(repository);
      await cubit.loadInitialData();
      cubit.toggleInterest('QUIET');
      cubit.toggleInterest('MUSIC');
      await cubit.updatePreferences();
      expect(repository.saved.interests, ['CAT_LOVER', 'QUIET', 'MUSIC']);
      expect(repository.saved.minBudget, 1000000);
      expect(repository.saved.preferredArea, 'TP HCM');
      final reopened = PreferencesCubit(repository);
      await reopened.loadInitialData();
      expect(reopened.state.interests, repository.saved.interests);
      for (final code in List.of(reopened.state.interests)) {
        reopened.toggleInterest(code);
      }
      await reopened.updatePreferences();
      expect(repository.saved.interests, isEmpty);
      await cubit.close();
      await reopened.close();
    },
  );

  test('Save failure keeps selections, retry succeeds and repeated saves are blocked', () async {
    final repository = MemoryPreferences()..failSave = true;
    final cubit = PreferencesCubit(repository);
    await cubit.loadInitialData();
    cubit.toggleInterest('STUDY');
    await cubit.updatePreferences();
    expect(cubit.state.status, PreferencesStatus.error);
    expect(cubit.state.interests, ['CAT_LOVER', 'STUDY']);
    repository.failSave = false;
    repository.pending = Completer<void>();
    final saving = cubit.updatePreferences();
    await cubit.updatePreferences();
    cubit.toggleInterest('MUSIC');
    expect(repository.writes, 2);
    expect(cubit.state.interests, ['CAT_LOVER', 'STUDY']);
    repository.pending!.complete();
    await saving;
    expect(cubit.state.status, PreferencesStatus.updateSuccess);
    await cubit.close();
  });

  testWidgets('Choices show saved state and can be changed and saved', (
    tester,
  ) async {
    final repository = MemoryPreferences();
    await tester.pumpWidget(interestsPage(repository));
    await tester.pumpAndSettle();
    final cat = find.byKey(const ValueKey('interest-CAT_LOVER'));
    await tester.ensureVisible(cat);
    expect(tester.widget<FilterChip>(cat).selected, isTrue);
    await tester.tap(cat);
    await tester.tap(find.text('Lưu sở thích'));
    await tester.pumpAndSettle();
    expect(repository.saved.interests, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Loading failure offers retry', (tester) async {
    final repository = MemoryPreferences()..failLoad = true;
    await tester.pumpWidget(interestsPage(repository));
    await tester.pumpAndSettle();
    expect(find.text('Thử lại'), findsOneWidget);
    repository.failLoad = false;
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(find.text('Một chút về bạn'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Interests support narrow and wide screens with large text', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    for (final width in [320.0, 800.0, 1440.0]) {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.binding.setSurfaceSize(Size(width, 850));
      await tester.pumpWidget(interestsPage(MemoryPreferences(), scale: 2));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('interest-SOCIABLE')),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.text('Lưu sở thích'), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'width $width');
    }
  });
}
