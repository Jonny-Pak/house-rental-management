import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/app/user/user_app.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/payment/data/models/payment_transaction.dart';
import 'package:frontend/features/payment/data/payment_link.dart';
import 'package:frontend/features/payment/data/repositories/payment_repository.dart';
import 'package:frontend/features/payment/presentation/cubit/payment_cubit.dart';
import 'package:frontend/features/payment/presentation/cubit/payment_state.dart';
import 'package:frontend/features/payment/presentation/pages/payment_history_page.dart';
import 'package:frontend/features/payment/presentation/pages/payment_status_page.dart';

class Payments extends PaymentRepository {
  Payments() : super(ApiClient());
  String url =
      'https://sandbox.vnpayment.vn/paymentv2/vpcpay.html?vnp_TxnRef=order_1';
  bool opened = true, failRead = false;
  int creates = 0, opens = 0, reads = 0;
  String status = 'PENDING';
  Completer<String>? gate;
  List<PaymentTransaction> history = [];

  PaymentTransaction payment(String reference) => PaymentTransaction(
    reference: reference,
    packageName: 'Gói PRO',
    amount: 150000,
    status: status,
    createdAt: DateTime(2026, 11, 2),
  );
  @override
  Future<String> getVnPayUrl(int id) async {
    creates++;
    if (gate != null) return gate!.future;
    return url;
  }

  @override
  Future<bool> openPayment(Uri uri) async {
    opens++;
    return opened;
  }

  @override
  Future<PaymentTransaction> getStatus(String reference) async {
    reads++;
    if (failRead) throw Exception('Lỗi kết nối máy chủ');
    return payment(reference);
  }

  @override
  Future<List<PaymentTransaction>> getHistory() async {
    if (failRead) throw Exception('Lỗi kết nối máy chủ');
    return history;
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('Opening a browser does not report that payment succeeded', () async {
    final repository = Payments();
    final cubit = PaymentCubit(repository: repository);
    await cubit.initiatePayment(3);
    expect(cubit.state, const PaymentOpened('order_1'));
    expect(cubit.state, isNot(isA<PaymentSuccess>()));
    expect(repository.opens, 1);
    await cubit.close();
  });

  test('Repeated payment taps are ignored while creating an order', () async {
    final repository = Payments()..gate = Completer<String>();
    final cubit = PaymentCubit(repository: repository);
    final first = cubit.initiatePayment(3);
    await cubit.initiatePayment(3);
    expect(repository.creates, 1);
    repository.gate!.complete(repository.url);
    await first;
    expect(repository.opens, 1);
    await cubit.close();
  });

  test('Free package succeeds without a browser; unsafe URLs and launch failures are errors', () async {
    final repository = Payments()..url = 'FREE_SUCCESS';
    final cubit = PaymentCubit(repository: repository);
    await cubit.initiatePayment(3);
    expect(cubit.state, isA<PaymentSuccess>());
    expect(repository.opens, 0);
    repository.url = 'https://attacker.example/pay?vnp_TxnRef=order_1';
    await cubit.initiatePayment(3);
    expect(cubit.state, isA<PaymentError>());
    expect(repository.opens, 0);
    repository.url =
        'https://sandbox.vnpayment.vn/paymentv2/vpcpay.html?vnp_TxnRef=order_1';
    repository.opened = false;
    await cubit.initiatePayment(3);
    expect(cubit.state, isA<PaymentError>());
    await cubit.close();
  });

  test('Return links extract the reference and never trust a success query parameter', () {
    expect(
      paymentReferenceFromLink(
        'houserental://payments/payment-result?reference=order_1&status=success',
      ),
      'order_1',
    );
    expect(
      paymentReferenceFromLink('/payment-result?reference=order_1'),
      'order_1',
    );
    expect(paymentReferenceFromLink('/payment-result?status=success'), '');
    expect(
      paymentReferenceFromLink(
        'https://attacker.example/payment-result?reference=order_1',
      ),
      isNull,
    );
    expect(paymentReferenceFromLink('/some-other-page'), isNull);
  });

  testWidgets(
    'Pending result refreshes from backend and then shows confirmed rights',
    (tester) async {
      final repository = Payments();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpWidget(
        MaterialApp(
          home: PaymentStatusPage(reference: 'order_1', repository: repository),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Đang chờ xác nhận'), findsOneWidget);
      repository.status = 'SUCCESS';
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      expect(find.text('Thanh toán thành công'), findsOneWidget);
      expect(
        find.textContaining('Quyền lợi gói dịch vụ đã được cập nhật'),
        findsOneWidget,
      );
      expect(repository.reads, 2);
    },
  );

  testWidgets(
    'Returning from the browser checks again; polling stops in background and after dispose',
    (tester) async {
      final repository = Payments();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpWidget(
        MaterialApp(
          home: PaymentStatusPage(reference: 'order_1', repository: repository),
        ),
      );
      await tester.pumpAndSettle();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump(const Duration(seconds: 20));
      expect(repository.reads, 1);
      repository.status = 'CANCELLED';
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(find.text('Đã hủy thanh toán'), findsOneWidget);
      expect(repository.reads, 2);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 10));
      expect(repository.reads, 2);
    },
  );

  testWidgets(
    'Network errors can retry; missing reference never sends an API request',
    (tester) async {
      final repository = Payments()..failRead = true;
      await tester.pumpWidget(
        MaterialApp(
          home: PaymentStatusPage(
            reference: 'order_1',
            repository: repository,
            autoCheck: false,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Lỗi kết nối'), findsOneWidget);
      repository.failRead = false;
      repository.status = 'FAILED';
      await tester.tap(find.text('Kiểm tra lại'));
      await tester.pumpAndSettle();
      expect(find.text('Thanh toán thất bại'), findsOneWidget);
      await tester.pumpWidget(
        MaterialApp(
          home: PaymentStatusPage(
            key: const ValueKey('invalid'),
            reference: '',
            repository: repository,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining('không có mã giao dịch hợp lệ'),
        findsOneWidget,
      );
      expect(repository.reads, 2);
    },
  );

  testWidgets(
    'History reloads after errors and opens a transaction with its server status',
    (tester) async {
      final repository = Payments()..failRead = true;
      await tester.pumpWidget(
        MaterialApp(home: PaymentHistoryPage(repository: repository)),
      );
      await tester.pumpAndSettle();
      repository.failRead = false;
      repository.status = 'EXPIRED';
      repository.history = [repository.payment('old_order')];
      await tester.tap(find.text('Thử lại'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Gói PRO'));
      await tester.pumpAndSettle();
      expect(find.text('Đã hết thời gian thanh toán'), findsOneWidget);
      expect(find.text('Mã giao dịch: old_order'), findsOneWidget);
    },
  );

  testWidgets(
    'A cold app return opens the result page and ignores forged success status',
    (tester) async {
      tester.binding.platformDispatcher.defaultRouteNameTestValue = 'houserental://payments/payment-result?reference=order_1&status=success';
      addTearDown(
        tester.binding.platformDispatcher.clearDefaultRouteNameTestValue,
      );
      final repository = Payments()..status = 'FAILED';
      await tester.pumpWidget(MyApp(paymentRepository: repository));
      await tester.pumpAndSettle();
      expect(find.text('Thanh toán thất bại'), findsOneWidget);
      expect(find.text('Thanh toán thành công'), findsNothing);
      expect(repository.reads, 1);
    },
  );

  testWidgets(
    'A running app handles a payment return and layout fits a narrow large-text screen',
    (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.binding.platformDispatcher.textScaleFactorTestValue = 1.8;
      addTearDown(
        tester.binding.platformDispatcher.clearTextScaleFactorTestValue,
      );
      final repository = Payments()..status = 'SUCCESS';
      await tester.pumpWidget(MyApp(paymentRepository: repository));
      await tester.pumpAndSettle();
      await tester.binding.handlePushRoute(
        'houserental://payments/payment-result?reference=order_1',
      );
      await tester.pumpAndSettle();
      expect(find.text('Thanh toán thành công'), findsOneWidget);
      expect(repository.reads, 1);
      expect(tester.takeException(), isNull);
    },
  );

  test('Unauthorized status reads tell the user to log in, without claiming success', () {
    final error = DioException(
      requestOptions: RequestOptions(),
      response: Response(requestOptions: RequestOptions(), statusCode: 401),
    );
    expect(PaymentRepository.errorMessage(error), contains('đăng nhập lại'));
  });
}
