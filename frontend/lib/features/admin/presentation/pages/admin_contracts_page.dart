import 'package:flutter/material.dart';

import '../../../../core/layout/app_layout.dart';
import '../../../../core/network/api_client.dart';
import '../../data/repositories/admin_contract_repository.dart';
import '../../../contract/data/models/contract_model.dart';
import '../../../contract/presentation/pages/my_contracts_page.dart'
    show contractStatus, contractMoney, contractDate;
import '../../../listing/data/repositories/listing_repository.dart';
import 'admin_contract_detail_page.dart';

const adminContractStatuses = {
  'DRAFT': 'Chờ người thuê xác nhận',
  'ACTIVE': 'Đang hiệu lực',
  'EXPIRED': 'Đã hết hạn',
  'TERMINATED': 'Đã kết thúc',
  'CANCELLED': 'Đã hủy',
};
const adminContractTypes = {'HOUSE': 'Thuê nhà', 'ROOM': 'Thuê phòng trọ'};

class AdminContractBadge extends StatelessWidget {
  const AdminContractBadge(this.status, {super.key});
  final String status;
  @override
  Widget build(BuildContext context) {
    Color color = const Color(0xFF697586);
    if (status == 'ACTIVE') color = const Color(0xFF15803D);
    if (status == 'DRAFT') color = const Color(0xFF9A7427);
    if (status == 'CANCELLED') color = const Color(0xFFB34F4F);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        contractStatus(status),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class AdminContractsPage extends StatefulWidget {
  const AdminContractsPage({super.key, this.repository});
  final AdminContractRepository? repository;
  @override
  State<AdminContractsPage> createState() => _AdminContractsPageState();
}

class _AdminContractsPageState extends State<AdminContractsPage> {
  late final _repository =
      widget.repository ?? AdminContractRepository(ApiClient());
  final _search = TextEditingController();
  String _status = '', _type = '';
  String? _error;
  bool _busy = false;
  AdminContractPageData? _data;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load([int page = 0]) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final data = await _repository.fetch(
        query: _search.text,
        status: _status,
        type: _type,
        page: page,
      );
      if (mounted) setState(() => _data = data);
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = ListingRepository.errorMessage(error);
          _data = null;
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _panel(Widget child) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    margin: const EdgeInsets.only(bottom: 18),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      border: Border.all(
        color: Theme.of(context).colorScheme.outlineVariant
            .withValues(alpha: .5),
      ),
      borderRadius: BorderRadius.circular(22),
    ),
    child: child,
  );

  InputDecoration _input(String label) => InputDecoration(
    labelText: label,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
  );

  Widget _filter(
    String label,
    String value,
    Map<String, String> options,
    ValueChanged<String> changed,
  ) => DropdownButtonFormField<String>(
    key: ValueKey('$label-$value'),
    initialValue: value,
    isExpanded: true,
    decoration: _input(label),
    items: [
      const DropdownMenuItem(value: '', child: Text('Tất cả')),
      for (final entry in options.entries)
        DropdownMenuItem(value: entry.key, child: Text(entry.value)),
    ],
    onChanged: _busy
        ? null
        : (value) {
            changed(value ?? '');
            _load();
          },
  );

  void _detail(ContractModel contract) => Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) =>
          AdminContractDetailPage(id: contract.id, repository: _repository),
    ),
  );

  Widget _open(ContractModel contract) => TextButton.icon(
    onPressed: _busy ? null : () => _detail(contract),
    icon: const Icon(Icons.visibility_outlined, size: 18),
    label: const Text('Xem chi tiết'),
  );

  Widget _list(double width) {
    final items = _data!.items;
    if (items.isEmpty) {
      return _panel(
        const Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(
                Icons.description_outlined,
                size: 48,
                color: Color(0xFF15803D),
              ),
              SizedBox(height: 14),
              Text('Không có hợp đồng phù hợp.', textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }
    if (width >= 1100) {
      return _panel(
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Hợp đồng')),
              DataColumn(label: Text('Hai bên tham gia')),
              DataColumn(label: Text('Thời hạn')),
              DataColumn(label: Text('Tiền thuê / tháng')),
              DataColumn(label: Text('Trạng thái')),
              DataColumn(label: Text('Thao tác')),
            ],
            rows: [
              for (final item in items)
                DataRow(
                  cells: [
                    DataCell(
                      SizedBox(
                        width: 220,
                        child: Text(
                          '#${item.id} · ${item.listingName ?? 'Hợp đồng thuê'}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 200,
                        child: Text(
                          'Chủ nhà: ${item.landlordName ?? '—'}\nNgười thuê: ${item.tenantName ?? '—'}',
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        '${contractDate(item.startDate)}\n${contractDate(item.endDate)}',
                      ),
                    ),
                    DataCell(Text(contractMoney(item.monthlyRent))),
                    DataCell(AdminContractBadge(item.status)),
                    DataCell(_open(item)),
                  ],
                ),
            ],
            dataRowMinHeight: 80,
            dataRowMaxHeight: 104,
          ),
        ),
      );
    }
    return Column(
      children: [
        for (final item in items)
          _panel(
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    Text(
                      'Hợp đồng #${item.id}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    AdminContractBadge(item.status),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  item.listingName ?? 'Hợp đồng thuê',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(item.address ?? 'Chưa có địa chỉ'),
                const SizedBox(height: 12),
                Text('Chủ nhà: ${item.landlordName ?? '—'}'),
                Text('Người thuê: ${item.tenantName ?? '—'}'),
                const SizedBox(height: 12),
                Text(
                  '${contractDate(item.startDate)} – ${contractDate(item.endDate)}',
                ),
                Text(
                  contractMoney(item.monthlyRent),
                  style: const TextStyle(
                    color: Color(0xFF15803D),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Align(alignment: Alignment.centerRight, child: _open(item)),
              ],
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => AppContent(
    maxWidth: 1500,
    child: LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: 20,
              runSpacing: 12,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quản lý hợp đồng',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Tra cứu hợp đồng và theo dõi trạng thái trong hệ thống.',
                    ),
                  ],
                ),
                OutlinedButton.icon(
                  onPressed: _busy ? null : () => _load(_data?.page ?? 0),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Làm mới'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _panel(
              LayoutBuilder(
                builder: (context, box) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      key: const ValueKey('admin-contract-search'),
                      controller: _search,
                      enabled: !_busy,
                      maxLength: 100,
                      decoration:
                          _input(
                            'Tìm mã, tin thuê, tên, email hoặc số điện thoại',
                          ).copyWith(
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: IconButton(
                              tooltip: 'Tìm hợp đồng',
                              onPressed: _busy ? null : () => _load(),
                              icon: const Icon(Icons.arrow_forward),
                            ),
                          ),
                      onSubmitted: (_) => _load(),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 14,
                      runSpacing: 14,
                      children: [
                        SizedBox(
                          width: box.maxWidth < 600 ? box.maxWidth : 270,
                          child: _filter(
                            'Trạng thái',
                            _status,
                            adminContractStatuses,
                            (value) => setState(() => _status = value),
                          ),
                        ),
                        SizedBox(
                          width: box.maxWidth < 600 ? box.maxWidth : 220,
                          child: _filter(
                            'Loại hợp đồng',
                            _type,
                            adminContractTypes,
                            (value) => setState(() => _type = value),
                          ),
                        ),
                        TextButton(
                          onPressed: _busy
                              ? null
                              : () {
                                  setState(() {
                                    _status = '';
                                    _type = '';
                                    _search.clear();
                                  });
                                  _load();
                                },
                          child: const Text('Xóa bộ lọc'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (_busy) const LinearProgressIndicator(),
            if (_error != null)
              _panel(
                Column(
                  children: [
                    Text(_error!, textAlign: TextAlign.center),
                    TextButton(
                      onPressed: () => _load(),
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            if (_data != null) ...[
              Text('${_data!.total} hợp đồng phù hợp'),
              const SizedBox(height: 16),
              _list(constraints.maxWidth),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                children: [
                  IconButton(
                    tooltip: 'Trang trước',
                    onPressed: _busy || _data!.page == 0
                        ? null
                        : () => _load(_data!.page - 1),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Text(
                    'Trang ${_data!.totalPages == 0 ? 0 : _data!.page + 1}/${_data!.totalPages}',
                  ),
                  IconButton(
                    tooltip: 'Trang sau',
                    onPressed: _busy || _data!.page + 1 >= _data!.totalPages
                        ? null
                        : () => _load(_data!.page + 1),
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    ),
  );
}
