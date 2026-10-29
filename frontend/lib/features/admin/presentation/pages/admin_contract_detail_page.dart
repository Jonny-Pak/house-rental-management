import 'package:flutter/material.dart';

import '../../../../core/layout/app_layout.dart';
import '../../data/repositories/admin_contract_repository.dart';
import '../../../contract/data/models/contract_model.dart';
import '../../../contract/presentation/pages/my_contracts_page.dart'
    show contractDate, contractMoney;
import '../../../contract/presentation/widgets/contract_document_view.dart';
import '../../../listing/data/repositories/listing_repository.dart';
import 'admin_contracts_page.dart';

class AdminContractDetailPage extends StatefulWidget {
  const AdminContractDetailPage({
    super.key,
    required this.id,
    required this.repository,
  });
  final int id;
  final AdminContractRepository repository;
  @override
  State<AdminContractDetailPage> createState() =>
      _AdminContractDetailPageState();
}

class _AdminContractDetailPageState extends State<AdminContractDetailPage> {
  ContractModel? _contract;
  String? _error;
  bool _busy = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final contract = await widget.repository.detail(widget.id);
      if (mounted) setState(() => _contract = contract);
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = ListingRepository.errorMessage(error);
          _contract = null;
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _section(String title, Widget child) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(22),
    margin: const EdgeInsets.only(bottom: 18),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      borderRadius: BorderRadius.circular(22),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 16),
        child,
      ],
    ),
  );

  Widget _line(String label, String? value) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: SelectableText(
      '$label: ${value == null || value.isEmpty ? 'Chưa có' : value}',
      style: const TextStyle(height: 1.5),
    ),
  );

  Widget _body(ContractModel item) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _section(
        'Thông tin hợp đồng',
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AdminContractBadge(item.status),
            const SizedBox(height: 18),
            _line('Tin thuê #${item.listingId}', item.listingName),
            _line('Địa chỉ', item.address),
            _line('Loại hợp đồng', adminContractTypes[item.contractType]),
            _line('Bắt đầu', contractDate(item.startDate)),
            _line('Kết thúc', contractDate(item.endDate)),
            _line('Tiền thuê / tháng', contractMoney(item.monthlyRent)),
            _line('Tiền đặt cọc', contractMoney(item.depositAmount)),
            _line(
              'Ngày tạo',
              item.createdAt == null ? null : contractDate(item.createdAt!),
            ),
            _line(
              'Người thuê xác nhận',
              item.acceptedAt == null
                  ? 'Chưa xác nhận'
                  : contractDate(item.acceptedAt!),
            ),
          ],
        ),
      ),
      _section(
        'Hai bên tham gia',
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _line('Chủ nhà', item.landlordName),
            _line(
              'Điện thoại chủ nhà',
              item.details['landlordPhone']?.toString(),
            ),
            _line('Người thuê', item.tenantName),
            _line(
              'Điện thoại người thuê',
              item.details['tenantPhone']?.toString(),
            ),
          ],
        ),
      ),
      if (item.note?.isNotEmpty == true)
        _section('Ghi chú', SelectableText(item.note!)),
      _section(
        'Nội dung thỏa thuận',
        item.documentText?.isNotEmpty == true
            ? ContractDocumentView(content: item.documentText!)
            : const Text(
                'Hợp đồng này chưa có bản nội dung thỏa thuận được lưu.',
              ),
      ),
      const Padding(
        padding: EdgeInsets.only(bottom: 20),
        child: Text(
          'Admin tra cứu để giám sát và hỗ trợ. Việc sửa, xác nhận và kết thúc hợp đồng do các bên tham gia thực hiện.',
          style: TextStyle(fontSize: 13, height: 1.6),
        ),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text('Hợp đồng #${widget.id}'),
      actions: [
        IconButton(
          tooltip: 'Tải lại hợp đồng',
          onPressed: _busy ? null : _load,
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: AppContent(
      maxWidth: 960,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_busy) const LinearProgressIndicator(),
            if (_error != null)
              _section(
                'Không tải được hợp đồng',
                Column(
                  children: [
                    Text(_error!, textAlign: TextAlign.center),
                    TextButton(onPressed: _load, child: const Text('Thử lại')),
                  ],
                ),
              ),
            if (_contract != null && _error == null) _body(_contract!),
          ],
        ),
      ),
    ),
  );
}
