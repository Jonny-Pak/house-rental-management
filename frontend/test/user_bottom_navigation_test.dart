import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/features/home/presentation/widgets/user_bottom_navigation.dart';

void main() {
  testWidgets('Tabs follow the requested order and move the selected bubble', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var selected = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) => Scaffold(
            bottomNavigationBar: UserBottomNavigation(
              selectedIndex: selected,
              onSelected: (index) => setState(() => selected = index),
            ),
          ),
        ),
      ),
    );
    for (var index = 0; index < 4; index++) {
      expect(
        tester.getCenter(find.byKey(ValueKey('bottom-nav-$index'))).dx,
        lessThan(
          tester.getCenter(find.byKey(ValueKey('bottom-nav-${index + 1}'))).dx,
        ),
      );
    }
    expect(
      tester.getCenter(find.byKey(const ValueKey('bottom-nav-2'))).dx,
      closeTo(195, 1),
    );
    for (final index in [1, 2, 3, 4, 0]) {
      await tester.tap(find.byKey(ValueKey('bottom-nav-$index')));
      await tester.pumpAndSettle();
      expect(selected, index);
      for (var item = 0; item < 5; item++) {
        final bubble = tester.widget<AnimatedContainer>(
          find.byKey(ValueKey('bottom-bubble-$item')),
        );
        expect(
          (bubble.decoration as BoxDecoration).color,
          item == index ? AppColors.primary : Colors.transparent,
        );
      }
    }
    expect(find.byTooltip('Tài khoản'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Bubble bar fits small screens, large text and device bottom inset',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(2.5),
              padding: const EdgeInsets.only(bottom: 34),
            ),
            child: child!,
          ),
          home: Scaffold(
            bottomNavigationBar: UserBottomNavigation(
              selectedIndex: 0,
              onSelected: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final target = tester.getRect(find.byKey(const ValueKey('bottom-nav-4')));
      expect(target.width, greaterThanOrEqualTo(48));
      expect(target.bottom, lessThanOrEqualTo(606));
      expect(tester.takeException(), isNull);
    },
  );
}
