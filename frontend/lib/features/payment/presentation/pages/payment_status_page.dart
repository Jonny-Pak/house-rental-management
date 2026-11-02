import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/payment_transaction.dart';
import '../../data/repositories/payment_repository.dart';

class PaymentStatusPage extends StatefulWidget {
  const PaymentStatusPage({
    super.key,
    required this.reference,
    this.repository,
    this.autoCheck = true,
    this.onDone,
  });
  final String reference;
  final PaymentRepository? repository;
  final bool autoCheck;
  final ValueChanged<bool>? onDone;
  @override
  State<PaymentStatusPage> createState() => _PaymentStatusPageState();
}

class _PaymentStatusPageState extends State<PaymentStatusPage>
    with WidgetsBindingObserver {
  late final repository = widget.repository ?? PaymentRepository(ApiClient());
  PaymentTransaction? _payment;
  Timer? _timer;
  String? _error;
  bool _loading = false;
  bool _foreground = true;
  int _checks = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _foreground =
        WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    _load();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _timer?.cancel();
    if (_foreground) _load();
  }

  Future<void> _load() async {
    if (_loading) return;
    _timer?.cancel();
    if (!RegExp(r'^[a-zA-Z0-9_-]{1,100}$').hasMatch(widget.reference)) {
      setState(
        () => _error = 'Đường dẫn không có mã giao dịch hợp lệ. Hãy mở lịch sử thanh toán trong Gói dịch vụ.',
      );
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final payment = await repository.getStatus(widget.reference);
      if (mounted) setState(() => _payment = payment);
    } catch (error) {
      if (mounted) {
        setState(() => _error = PaymentRepository.errorMessage(error));
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
        _checks++;
        if (widget.autoCheck &&
            _foreground &&
            _error == null &&
            _payment?.pending == true &&
            _checks < 36) {
          _timer = Timer(const Duration(seconds: 5), () {
            if (mounted && ModalRoute.of(context)?.isCurrent == true) _load();
          });
        }
      }
    }
  }

  void _done() {
    if (widget.onDone != null) {
      widget.onDone!(_payment != null);
    } else {
      Navigator.pop(context, _payment?.success == true);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final payment = _payment;
    return Scaffold(
      appBar: AppBar(title: const Text('Kết quả thanh toán')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              if (_loading) const LinearProgressIndicator(),
              const SizedBox(height: 24),
              Icon(
                payment?.success == true
                    ? Icons.check_circle
                    : Icons.receipt_long,
                size: 64,
                color: AppColors.primary,
              ),
              const SizedBox(height: 20),
              Text(
                payment?.statusLabel ?? 'Kiểm tra thanh toán VNPAY',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              if (_error != null)
                Text(_error!, style: const TextStyle(color: Colors.red)),
              if (payment != null) ...[
                Text(payment.packageName, textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text(
                  '${NumberFormat('#,###', 'vi_VN').format(payment.amount)} đ',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                SelectableText(
                  'Mã giao dịch: ${payment.reference}',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Text(
                  payment.success
                      ? 'Quyền lợi gói dịch vụ đã được cập nhật vào tài khoản của bạn.'
                      : payment.pending
                      ? 'Hoàn tất thanh toán trong trình duyệt. Khi quay lại app, trạng thái sẽ được kiểm tra lại. '
                            'Nếu đã bị trừ tiền, hãy kiểm tra giao dịch này trước khi tạo thanh toán mới.'
                      : 'Giao dịch này chưa cấp thêm quyền lợi. Nếu đã bị trừ tiền, hãy kiểm tra lại hoặc gửi báo cáo kèm mã giao dịch.',
                  style: const TextStyle(height: 1.6),
                ),
              ],
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: _loading ? null : _load,
                child: const Text('Kiểm tra lại'),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _done,
                child: Text(payment?.success == true ? 'Hoàn tất' : 'Đóng'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
