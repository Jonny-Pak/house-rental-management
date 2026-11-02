import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/membership/data/models/membership_package_model.dart';
import 'package:frontend/features/membership/data/repositories/membership_repository.dart';
import 'package:frontend/features/membership/presentation/pages/membership_page.dart';
import 'package:frontend/features/membership/presentation/widgets/membership_comparison.dart';
import 'package:frontend/features/payment/data/repositories/payment_repository.dart';

class Packages extends MembershipRepository {
  Packages() : super(ApiClient());
  bool fail = false;
  bool empty = false;
  @override
  Future<List<MembershipPackage>> getPackages() async {
    if (fail) throw Exception('Không tải được dữ liệu');
    if (empty) return [];
    return [
      MembershipPackage(
        id: 2,
        packageName: 'Gói nâng cao',
        price: 199000,
        standardPostQuota: 20,
        vipPostQuota: 5,
        refreshQuota: 10,
      ),
      MembershipPackage(
        id: 1,
        packageName: 'Gói cơ bản',
        price: 0,
        defaultPackage: true,
        standardPostQuota: 3,
        vipPostQuota: 0,
        refreshQuota: 0,
      ),
    ];
  }
}

class ThreePackages extends MembershipRepository {
  ThreePackages() : super(ApiClient());
  @override
  Future<List<MembershipPackage>> getPackages() async => [
    MembershipPackage(
      id: 1,
      packageName: 'Gói Cơ Bản',
      price: 0,
      defaultPackage: true,
      standardPostQuota: 3,
      vipPostQuota: 0,
      refreshQuota: 0,
    ),
    MembershipPackage(
      id: 2,
      packageName: 'Gói PLUS',
      price: 50000,
      standardPostQuota: 10,
      vipPostQuota: 0,
      refreshQuota: 5,
    ),
    MembershipPackage(
      id: 3,
      packageName: 'Gói PRO',
      price: 150000,
      standardPostQuota: 30,
      vipPostQuota: 5,
      refreshQuota: 20,
    ),
  ];
}

class Payments extends PaymentRepository {
  Payments() : super(ApiClient());
  int? requested;
  final gate = Completer<String>();
  @override
  Future<String> getVnPayUrl(int id) async {
    requested = id;
    return gate.future;
  }
}

void main() {
  testWidgets(
    'Package tabs compare real quotas and subscribe with the chosen package ID',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final payments = Payments();
      await tester.pumpWidget(
        MaterialApp(
          home: MembershipPage(
            repository: ThreePackages(),
            paymentRepository: payments,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Gói PLUS'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('membership-default-plan')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('membership-subscribe-1')),
        findsNothing,
      );
      expect(find.text('Chọn miễn phí'), findsNothing);
      expect(payments.requested, isNull);
      expect(find.text('Gói PRO'), findsOneWidget);
      expect(find.text('150.000 đ'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('membership-tab-comparison')));
      await tester.pumpAndSettle();
      expect(find.byType(MembershipComparison), findsOneWidget);
      expect(find.text('30 tin'), findsOneWidget);
      expect(find.text('20 lượt'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('membership-tab-packages')));
      await tester.pumpAndSettle();
      final button = find.byKey(const ValueKey('membership-subscribe-2'));
      await tester.ensureVisible(button);
      await tester.pumpAndSettle();
      await tester.tap(button);
      await tester.pump();
      expect(payments.requested, 2);
      expect(find.text('Đang xử lý yêu cầu…'), findsOneWidget);
      payments.gate.completeError(Exception('Chưa thể thanh toán'));
      await tester.pumpAndSettle();
      expect(tester.widget<FilledButton>(button).onPressed, isNotNull);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'Three package cards remain readable and scroll with enlarged text',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 850));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: MembershipPage(
            repository: ThreePackages(),
            paymentRepository: Payments(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final scroll = find.byKey(const ValueKey('membership-cards-scroll'));
      await tester.ensureVisible(scroll);
      await tester.pumpAndSettle();
      await tester.drag(scroll, const Offset(-280, 0));
      await tester.pumpAndSettle();
      final state = tester.state<ScrollableState>(
        find.descendant(of: scroll, matching: find.byType(Scrollable)),
      );
      expect(state.position.pixels, greaterThan(0));
      expect(find.text('30 tin đăng thường'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'Comparison shows actual package quotas and scrolls on small screens',
    (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final packages = await Packages().getPackages();
      for (final width in [320.0, 1440.0]) {
        await tester.binding.setSurfaceSize(Size(width, 850));
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(2)),
              child: child!,
            ),
            home: Scaffold(
              body: SingleChildScrollView(
                child: MembershipComparison(packages: packages),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('20 tin'), findsOneWidget);
        expect(find.text('3 tin'), findsOneWidget);
        expect(find.text('5 lượt'), findsOneWidget);
        expect(find.text('10 lượt'), findsOneWidget);
        expect(find.text('Không bao gồm'), findsNWidgets(2));
        if (width == 320) {
          final scroll = find.byKey(
            const ValueKey('membership-comparison-scroll'),
          );
          await tester.drag(scroll, const Offset(-350, 0));
          await tester.pumpAndSettle();
          final state = tester.state<ScrollableState>(
            find.descendant(of: scroll, matching: find.byType(Scrollable)),
          );
          expect(state.position.pixels, greaterThan(0));
        }
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets(
    'Membership keeps package selection and blocks repeated payment taps',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 950));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final payments = Payments();
      await tester.pumpWidget(
        MaterialApp(
          home: MembershipPage(
            repository: Packages(),
            paymentRepository: payments,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('membership-subscribe-2')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('membership-subscribe-2')));
      await tester.pump();
      expect(payments.requested, 2);
      expect(find.text('Đang xử lý yêu cầu…'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const ValueKey('membership-subscribe-2')),
            )
            .onPressed,
        isNull,
      );
      payments.gate.completeError(Exception('Thanh toán chưa thành công'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Thanh toán chưa thành công'), findsOneWidget);
      expect(find.text('Đang xử lý yêu cầu…'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Membership packages adapt to large text and different screen widths',
    (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      for (final width in [320.0, 800.0, 1440.0]) {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.binding.setSurfaceSize(Size(width, 800));
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(2)),
              child: child!,
            ),
            home: MembershipPage(
              repository: Packages(),
              paymentRepository: Payments(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.text('Đăng ký'),
          250,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        expect(find.text('5 lượt nâng VIP'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets('Membership provides retry and empty states', (tester) async {
    final packages = Packages()..fail = true;
    await tester.pumpWidget(
      MaterialApp(
        home: MembershipPage(
          repository: packages,
          paymentRepository: Payments(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Không tải được gói dịch vụ'), findsOneWidget);
    packages.fail = false;
    packages.empty = true;
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(find.text('Chưa có gói dịch vụ nào.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
