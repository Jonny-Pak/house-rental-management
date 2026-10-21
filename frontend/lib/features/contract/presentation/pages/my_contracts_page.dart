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
import '../../../home/presentation/widgets/home_feature_icon.dart';

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
    final color = switch (contract.status) {
      'ACTIVE' => const Color(0xFF387960),
      'DRAFT' => const Color(0xFFB77B25),
      'CANCELLED' => const Color(0xFFAE5141),
      _ => const Color(0xFF8A7464),
    };
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: Color(0xFFEEDFD1)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openContract(contract),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF0E1),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(
                      Symbols.description,
                      size: 22,
                      color: Color(0xFFD76B28),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'HỢP ĐỒNG #${contract.id}',
                      style: const TextStyle(
                        fontSize: 10,
                        letterSpacing: 1,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF8A7464),
                      ),
                    ),
                  ),
                  const Icon(
                    Symbols.chevron_right,
                    size: 20,
                    color: Color(0xFFAD8A68),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                contract.listingName ?? 'Hợp đồng #${contract.id}',
                style: const TextStyle(
                  fontSize: 17,
                  height: 1.4,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF38291F),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .09),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  contractStatus(contract.status),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '${contractMoney(contract.monthlyRent)}/tháng',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFD76B28),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Divider(height: 1, color: Color(0xFFF3ECE4)),
              ),
              _cardInfo(Symbols.person, otherParty),
              const SizedBox(height: 10),
              _cardInfo(
                Symbols.calendar_month,
                '${contractDate(contract.startDate)} – ${contractDate(contract.endDate)}',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cardInfo(IconData icon, String text) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 17, color: const Color(0xFFAD8A68)),
      const SizedBox(width: 7),
      Expanded(
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            height: 1.5,
            color: Color(0xFF8A7464),
          ),
        ),
      ),
    ],
  );

  Widget _emptyState() => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(top: 12),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: const Color(0xFFEEDFD1)),
    ),
    child: Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Color(0xFFFFF4E8),
            shape: BoxShape.circle,
          ),
          child: const HomeFeatureIcon(icon: Symbols.receipt_long, size: 76),
        ),
        const SizedBox(height: 20),
        const Text(
          'Chưa có hợp đồng phù hợp.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Color(0xFF38291F),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          _selectedStatus.isNotEmpty
              ? 'Thử chọn trạng thái khác để xem hợp đồng của bạn.'
              : widget.isLandlord
              ? 'Tạo hợp đồng để lưu thông tin thuê nhà và theo dõi thời hạn tại đây.'
              : 'Hợp đồng do chủ nhà tạo sẽ xuất hiện tại đây để bạn xem và xác nhận.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            height: 1.6,
            color: Color(0xFF8A7464),
          ),
        ),
        if (_selectedStatus.isNotEmpty) ...[
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => setState(() => _selectedStatus = ''),
            child: const Text('Xem tất cả hợp đồng'),
          ),
        ],
      ],
    ),
  );

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
    for (final contract in contracts) {
      cards.add(_contractCard(contract));
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
        children: [
          if (contracts.isEmpty) _emptyState(),
          ResponsiveCards(children: cards),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget? createButton;
    if (widget.isLandlord) {
      createButton = FloatingActionButton.extended(
        backgroundColor: const Color(0xFFD76B28),
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        onPressed: _create,
        icon: const Icon(Symbols.add),
        label: const Text('Tạo hợp đồng'),
      );
    }
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAF8F5),
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Hợp đồng thuê',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w700,
            color: Color(0xFF38291F),
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Làm mới',
            onPressed: _loading ? null : _load,
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF8A7464),
              side: const BorderSide(color: Color(0xFFEEDFD1)),
            ),
            icon: const Icon(Symbols.refresh, size: 21),
          ),
        ],
      ),
      floatingActionButton: createButton,
      body: AppContent(
        maxWidth: AppLayout.contentWidth,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Theo dõi thỏa thuận thuê nhà · ${_contracts.length} hợp đồng',
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.5,
                    color: Color(0xFF8A7464),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: DropdownButtonFormField<String>(
                key: ValueKey(_selectedStatus),
                initialValue: _selectedStatus,
                isExpanded: true,
                itemHeight: null,
                dropdownColor: Colors.white,
                borderRadius: BorderRadius.circular(16),
                style: const TextStyle(fontSize: 14, color: Color(0xFF38291F)),
                icon: const Icon(Symbols.expand_more, color: Color(0xFF8A7464)),
                decoration: InputDecoration(
                  labelText: 'Trạng thái',
                  labelStyle: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8A7464),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(
                    Symbols.tune,
                    size: 20,
                    color: Color(0xFFC88B53),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFEEDFD1)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFEEDFD1)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFD76B28)),
                  ),
                ),
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
