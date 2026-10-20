import '../../../../core/layout/app_layout.dart';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/network/api_client.dart';
import '../../../listing/data/repositories/listing_repository.dart';
import '../../data/models/contract_model.dart';
import '../../data/repositories/contract_repository.dart';
import 'contract_form_page.dart';
import '../widgets/contract_document_view.dart';

String contractStatus(String status) {
  if (status == 'DRAFT') return 'Chờ người thuê xác nhận';
  if (status == 'ACTIVE') return 'Đang hiệu lực';
  if (status == 'EXPIRED') return 'Đã hết hạn';
  if (status == 'TERMINATED') return 'Đã kết thúc';
  if (status == 'CANCELLED') return 'Đã hủy';
  return status;
}

String contractMoney(num amount) {
  return '${NumberFormat.decimalPattern('vi_VN').format(amount)} đ';
}

String contractDate(String text) {
  final date = DateTime.tryParse(text);
  if (date == null) return text;
  return DateFormat('dd/MM/yyyy').format(date);
}

class MyContractsPage extends StatefulWidget {
  const MyContractsPage({super.key, this.isLandlord = false, this.repository});
  final bool isLandlord;
  final ContractRepository? repository;
  @override
  State<MyContractsPage> createState() => _MyContractsPageState();
}

class _MyContractsPageState extends State<MyContractsPage> {
  late final _repository = widget.repository ?? ContractRepository(ApiClient());
  List<ContractModel> _contracts = [];
  bool _loading = true;
  String? _error;
  String _selectedStatus = '';
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
      final items = await _repository.getMyContracts();
      if (mounted) setState(() => _contracts = items);
    } catch (e) {
      if (mounted) setState(() => _error = ListingRepository.errorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _create() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ContractFormPage(repository: _repository),
      ),
    );
    if (mounted) await _load();
  }

  List<DropdownMenuItem<String>> _statusItems() {
    final items = <DropdownMenuItem<String>>[];
    final statuses = [
      '',
      'DRAFT',
      'ACTIVE',
      'EXPIRED',
      'TERMINATED',
      'CANCELLED',
    ];
    for (final status in statuses) {
      String label = 'Tất cả';
      if (status.isNotEmpty) label = contractStatus(status);
      items.add(DropdownMenuItem(value: status, child: Text(label)));
    }
    return items;
  }

  List<ContractModel> _filteredContracts() {
    final result = <ContractModel>[];
    for (final contract in _contracts) {
      if (_selectedStatus.isEmpty || contract.status == _selectedStatus) {
        result.add(contract);
      }
    }
    return result;
  }

  Future<void> _openContract(ContractModel contract) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ContractDetailPage(id: contract.id, repository: _repository),
      ),
    );
    if (mounted) await _load();
  }

  Widget _contractCard(ContractModel contract) {
    String otherParty = 'Chủ nhà: ${contract.landlordName}';
    if (contract.myRole == 'LANDLORD') {
      otherParty = 'Người thuê: ${contract.tenantName}';
    }
    return Card(
      child: ListTile(
        title: Text(contract.listingName ?? 'Hợp đồng #${contract.id}'),
        subtitle: Text(
          '${contractStatus(contract.status)}\n$otherParty\n${contractMoney(contract.monthlyRent)}/tháng',
        ),
        isThreeLine: true,
        trailing: const Icon(Symbols.chevron_right),
        onTap: () => _openContract(contract),
      ),
    );
  }

  Widget _buildContractList() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!),
            TextButton(onPressed: _load, child: const Text('Thử lại')),
          ],
        ),
      );
    }

    final contracts = _filteredContracts();
    final cards = <Widget>[];
    if (contracts.isEmpty) {
      cards.add(
        const Padding(
          padding: EdgeInsets.all(24),
          child: Text('Chưa có hợp đồng phù hợp.'),
        ),
      );
    }
    for (final contract in contracts) {
      cards.add(_contractCard(contract));
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
        children: [ResponsiveCards(children: cards)],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget? createButton;
    if (widget.isLandlord) {
      createButton = FloatingActionButton.extended(
        onPressed: _create,
        icon: const Icon(Symbols.add),
        label: const Text('Tạo hợp đồng'),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hợp đồng thuê'),
        actions: [
          IconButton(
            tooltip: 'Làm mới',
            onPressed: _load,
            icon: const Icon(Symbols.refresh),
          ),
        ],
      ),
      floatingActionButton: createButton,
      body: AppContent(
        maxWidth: AppLayout.contentWidth,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: DropdownButtonFormField<String>(
                initialValue: _selectedStatus,
                decoration: const InputDecoration(labelText: 'Trạng thái'),
                items: _statusItems(),
                onChanged: (status) =>
                    setState(() => _selectedStatus = status!),
              ),
            ),
            Expanded(child: _buildContractList()),
          ],
        ),
      ),
    );
  }
}

class ContractDetailPage extends StatefulWidget {
  const ContractDetailPage({
    super.key,
    required this.id,
    required this.repository,
  });
  final int id;
  final ContractRepository repository;
  @override
  State<ContractDetailPage> createState() => _ContractDetailPageState();
}

class _ContractDetailPageState extends State<ContractDetailPage> {
  ContractModel? _contract;
  String? _error;
  bool _busy = false;
  bool _readContract = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final c = await widget.repository.detail(widget.id);
      if (mounted) {
        setState(() {
          if (_contract?.version != c.version) _readContract = false;
          _contract = c;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = ListingRepository.errorMessage(e));
    }
  }

  String _confirmationMessage(String status) {
    if (status == 'ACTIVE') {
      return 'Bạn đã kiểm tra và đồng ý thông tin hợp đồng này?';
    }
    if (status == 'TERMINATED') {
      return 'Kết thúc hợp đồng? Tin sẽ được ẩn để chủ nhà kiểm tra trước khi đăng lại.';
    }
    return 'Hủy hợp đồng chờ xác nhận?';
  }

  Future<void> _action(String status) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận thao tác'),
        content: Text(_confirmationMessage(status)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Quay lại'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await widget.repository.status(widget.id, status, _contract!.version);
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ListingRepository.errorMessage(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _row(String name, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Text('$name: $value'),
  );
  Widget _buildDetailsBody() {
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!),
            TextButton(onPressed: _load, child: const Text('Thử lại')),
          ],
        ),
      );
    }
    final contract = _contract;
    if (contract == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          contract.listingName ?? '',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        Text(contract.address ?? ''),
        const SizedBox(height: 16),
        Chip(label: Text(contractStatus(contract.status))),
        _row('Chủ nhà', contract.landlordName ?? ''),
        _row('Người thuê', contract.tenantName ?? ''),
        _row('Bắt đầu', contractDate(contract.startDate)),
        _row('Kết thúc', contractDate(contract.endDate)),
        _row('Tiền thuê / tháng', contractMoney(contract.monthlyRent)),
        _row('Tiền cọc', contractMoney(contract.depositAmount)),
        if (contract.note?.isNotEmpty == true) _row('Ghi chú', contract.note!),
        const SizedBox(height: 20),
        if (contract.documentText?.isNotEmpty == true)
          ContractDocumentView(content: contract.documentText!)
        else
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              contract.status == 'DRAFT'
                  ? 'Hợp đồng cũ chưa có toàn văn theo mẫu. Chủ nhà cần bổ sung bản nháp trước khi người thuê xác nhận.'
                  : 'Hợp đồng cũ chưa có toàn văn theo mẫu. Hai bên đối chiếu bản hợp đồng đã lưu hoặc ký trước đây.',
            ),
          ),
        if (contract.acceptedAt != null)
          _row('Người thuê xác nhận trong hệ thống', contract.acceptedAt!),
        if (contract.status == 'DRAFT' &&
            contract.myRole == 'TENANT' &&
            contract.documentText?.isNotEmpty == true)
          CheckboxListTile(
            value: _readContract,
            controlAffinity: ListTileControlAffinity.leading,
            title: const Text('Tôi đã đọc toàn bộ và đồng ý nội dung hợp đồng'),
            onChanged: _busy
                ? null
                : (value) => setState(() => _readContract = value ?? false),
          ),
        if (contract.status == 'DRAFT' && contract.myRole == 'LANDLORD')
          OutlinedButton(
            onPressed: _busy
                ? null
                : () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ContractFormPage(
                          repository: widget.repository,
                          existing: contract,
                        ),
                      ),
                    );
                    if (mounted) await _load();
                  },
            child: const Text('Sửa bản nháp'),
          ),
        if (contract.status == 'DRAFT' && contract.myRole == 'TENANT')
          FilledButton(
            onPressed:
                _busy ||
                    !_readContract ||
                    contract.documentText?.isNotEmpty != true
                ? null
                : () => _action('ACTIVE'),
            child: const Text('Đồng ý hợp đồng'),
          ),
        if (contract.status == 'DRAFT')
          OutlinedButton(
            onPressed: _busy ? null : () => _action('CANCELLED'),
            child: Text(
              contract.myRole == 'TENANT' ? 'Từ chối hợp đồng' : 'Hủy bản nháp',
            ),
          ),
        if (contract.status == 'ACTIVE' && contract.myRole == 'LANDLORD')
          OutlinedButton(
            onPressed: _busy ? null : () => _action('TERMINATED'),
            child: const Text('Kết thúc hợp đồng'),
          ),
        if (_busy) const LinearProgressIndicator(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hợp đồng #${widget.id}'),
        actions: [
          IconButton(
            tooltip: 'Tải lại hợp đồng',
            onPressed: _busy ? null : _load,
            icon: const Icon(Symbols.refresh),
          ),
        ],
      ),
      body: AppContent(
        maxWidth: AppLayout.formWidth,
        child: _buildDetailsBody(),
      ),
    );
  }
}
