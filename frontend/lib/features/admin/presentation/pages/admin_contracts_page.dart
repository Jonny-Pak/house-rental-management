import 'package:frontend/core/theme/app_colors.dart';

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
    final dark = Theme.of(context).brightness == Brightness.dark;
    Color color = dark ? const Color(0xFFADB8C7) : const Color(0xFF697586);
    if (status == 'ACTIVE') {
      color = dark ? const Color(0xFF86E0A1) : AppColors.primary;
    }
    if (status == 'DRAFT') {
      color = dark ? const Color(0xFFE8C476) : const Color(0xFF9A7427);
    }
    if (status == 'CANCELLED') {
      color = dark ? const Color(0xFFEE9C9C) : const Color(0xFFB34F4F);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 6, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              contractStatus(status),
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
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
    counterText: '',
    filled: true,
    fillColor: Theme.of(context).colorScheme.surfaceContainerLowest,
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(
        color: Theme.of(context).colorScheme.outlineVariant
            .withValues(alpha: .6),
      ),
    ),
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

  void _reset() {
    setState(() {
      _status = '';
      _type = '';
      _search.clear();
    });
    _load();
  }

  Widget _empty() => _panel(
    Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 12),
      child: Column(
        children: [
          Container(
            width: 112,
            height: 112,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: .07),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: .15),
                  ),
                ),
                child: const Icon(
                  Icons.find_in_page_outlined,
                  size: 38,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'Không có hợp đồng phù hợp.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Text(
            _status.isNotEmpty || _type.isNotEmpty || _search.text.isNotEmpty
                ? 'Thử từ khóa khác hoặc bỏ bộ lọc để xem thêm kết quả.'
                : 'Hợp đồng do các thành viên tạo sẽ được hiển thị tại đây để Admin theo dõi.',
            textAlign: TextAlign.center,
            style: TextStyle(
              height: 1.7,
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          if (_status.isNotEmpty ||
              _type.isNotEmpty ||
              _search.text.isNotEmpty) ...[
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: _busy ? null : _reset,
              icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
              label: const Text('Xem tất cả hợp đồng'),
            ),
          ],
        ],
      ),
    ),
  );

  Widget _person(String label, String? name, IconData icon, Color color) => Row(
    children: [
      Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(icon, size: 15, color: color),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              name ?? 'Chưa có',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _parties(ContractModel item) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      _person(
        'Chủ nhà',
        item.landlordName,
        Icons.home_outlined,
        const Color(0xFF368065),
      ),
      const SizedBox(height: 9),
      _person(
        'Người thuê',
        item.tenantName,
        Icons.person_outline_rounded,
        const Color(0xFF617FB1),
      ),
    ],
  );

  Widget _term(ContractModel item) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        contractDate(item.startDate),
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Icon(
          Icons.south_rounded,
          size: 12,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      Text(
        contractDate(item.endDate),
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      ),
    ],
  );

  Widget _list(double width) {
    final items = _data!.items;
    if (items.isEmpty) return _empty();
    if (width >= 1100) {
      return _panel(
        LayoutBuilder(
          builder: (context, box) => SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: box.maxWidth),
              child: DataTable(
                headingRowColor: WidgetStatePropertyAll(
                  Theme.of(context).colorScheme.onSurface
                      .withValues(alpha: .025),
                ),
                headingTextStyle: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
                columnSpacing: 24,
                horizontalMargin: 16,
                dividerThickness: .5,
                headingRowHeight: 48,
                dataRowMinHeight: 112,
                dataRowMaxHeight: 128,
                columns: const [
                  DataColumn(label: Text('HỢP ĐỒNG / TIN THUÊ')),
                  DataColumn(label: Text('HAI BÊN THAM GIA')),
                  DataColumn(label: Text('THỜI HẠN')),
                  DataColumn(label: Text('GIÁ THUÊ / THÁNG')),
                  DataColumn(label: Text('TRẠNG THÁI')),
                  DataColumn(label: Text('THAO TÁC')),
                ],
                rows: [
                  for (final item in items)
                    DataRow(
                      cells: [
                        DataCell(
                          SizedBox(
                            width: 220,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'HĐ #${item.id}',
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 7),
                                Text(
                                  item.listingName ?? 'Hợp đồng thuê',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  adminContractTypes[item.contractType] ??
                                      'Hợp đồng thuê',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        DataCell(SizedBox(width: 190, child: _parties(item))),
                        DataCell(_term(item)),
                        DataCell(
                          Text(
                            contractMoney(item.monthlyRent),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        DataCell(AdminContractBadge(item.status)),
                        DataCell(_open(item)),
                      ],
                    ),
                ],
              ),
            ),
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
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 10,
                  children: [
                    Text(
                      'Hợp đồng #${item.id}',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    AdminContractBadge(item.status),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  item.listingName ?? 'Hợp đồng thuê',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item.address ?? 'Chưa có địa chỉ',
                  style: TextStyle(
                    height: 1.5,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 18),
                Divider(
                  color: Theme.of(context).colorScheme.outlineVariant
                      .withValues(alpha: .5),
                ),
                const SizedBox(height: 12),
                _parties(item),
                const SizedBox(height: 18),
                Text(
                  '${contractDate(item.startDate)} – ${contractDate(item.endDate)}',
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 8),
                Text(
                  contractMoney(item.monthlyRent),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 20,
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

  Widget _header() => Wrap(
    alignment: WrapAlignment.spaceBetween,
    spacing: 20,
    runSpacing: 18,
    children: [
      const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'HỢP ĐỒNG & THỎA THUẬN',
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 1.7,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Quản lý hợp đồng',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 10),
          Text(
            'Tra cứu thông tin và theo dõi trạng thái hợp đồng trong hệ thống.',
            style: TextStyle(height: 1.5),
          ),
        ],
      ),
      OutlinedButton.icon(
        onPressed: _busy ? null : () => _load(_data?.page ?? 0),
        icon: const Icon(Icons.refresh_rounded, size: 18),
        label: const Text('Làm mới'),
      ),
    ],
  );

  Widget _filters() => _panel(
    LayoutBuilder(
      builder: (context, box) {
        final wide = box.maxWidth >= 1100;
        return Wrap(
          spacing: 14,
          runSpacing: 16,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: wide ? box.maxWidth - 664 : box.maxWidth,
              child: TextField(
                key: const ValueKey('admin-contract-search'),
                controller: _search,
                enabled: !_busy,
                maxLength: 100,
                decoration:
                    _input('Tìm mã, tin thuê, tên, email hoặc số điện thoại')
                        .copyWith(
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: IconButton(
                            tooltip: 'Tìm hợp đồng',
                            onPressed: _busy ? null : () => _load(),
                            icon: const Icon(Icons.arrow_forward_rounded),
                          ),
                        ),
                onSubmitted: (_) => _load(),
              ),
            ),
            SizedBox(
              width: box.maxWidth < 600 ? box.maxWidth : 280,
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
              onPressed: _busy ? null : _reset,
              child: const Text('Xóa bộ lọc'),
            ),
          ],
        );
      },
    ),
  );

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF141A1D)
        : const Color(0xFFF6F8FA),
    child: AppContent(
      maxWidth: 1500,
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _header(),
              const SizedBox(height: 26),
              _filters(),
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
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    Text(
                      '${_data!.total} hợp đồng phù hợp',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      'Danh sách hợp đồng',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _list(constraints.maxWidth),
                if (_data!.items.isNotEmpty)
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
    ),
  );
}
