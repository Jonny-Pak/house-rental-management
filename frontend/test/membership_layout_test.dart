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
        standardPostQuota: 3,
        vipPostQuota: 0,
        refreshQuota: 0,
      ),
    ];
  }
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
        expect(find.text('5 tin'), findsOneWidget);
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
        find.text('Chọn gói miễn phí'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Chọn gói miễn phí'));
      await tester.pump();
      expect(payments.requested, 1);
      expect(find.text('Đang xử lý yêu cầu…'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Chọn gói miễn phí'),
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
          find.text('Đăng ký ngay'),
          250,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        expect(find.text('5 tin đăng VIP'), findsOneWidget);
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
