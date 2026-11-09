import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/api_client.dart';
import '../../data/models/payment_transaction.dart';
import '../../data/repositories/payment_repository.dart';
import 'payment_status_page.dart';

class PaymentHistoryPage extends StatefulWidget {
  const PaymentHistoryPage({super.key, this.repository});
  final PaymentRepository? repository;
  @override
  State<PaymentHistoryPage> createState() => _PaymentHistoryPageState();
}

class _PaymentHistoryPageState extends State<PaymentHistoryPage> {
  late final repository = widget.repository ?? PaymentRepository(ApiClient());
  List<PaymentTransaction> _items = [];
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await repository.getHistory();
      if (mounted) setState(() => _items = items);
    } catch (error) {
      if (mounted) {
        setState(() => _error = PaymentRepository.errorMessage(error));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _open(PaymentTransaction payment) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentStatusPage(
          reference: payment.reference,
          repository: repository,
        ),
      ),
    );
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Lịch sử thanh toán'),
      actions: [
        IconButton(
          onPressed: _loading ? null : _load,
          tooltip: 'Tải lại giao dịch',
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  if (_error != null) ...[
                    Text(_error!),
                    TextButton(onPressed: _load, child: const Text('Thử lại')),
                  ] else if (_items.isEmpty)
                    const Text('Bạn chưa có giao dịch thanh toán.')
                  else ...[
                    const Text(
                      '20 giao dịch gần nhất. Chọn một giao dịch để kiểm tra kết quả.',
                    ),
                    const SizedBox(height: 12),
                    for (final payment in _items)
                      Card(
                        child: ListTile(
                          title: Text(payment.packageName),
                          subtitle: Text(
                            '${payment.statusLabel}\n${NumberFormat('#,###', 'vi_VN').format(payment.amount)} đ\n'
                            '${payment.createdAt == null ? '' : DateFormat('dd/MM/yyyy HH:mm').format(payment.createdAt!)}',
                          ),
                          isThreeLine: true,
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _open(payment),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
  );
}
