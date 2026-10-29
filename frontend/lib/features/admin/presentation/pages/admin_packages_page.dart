import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/api_client.dart';
import '../../../membership/data/models/membership_package_model.dart';
import '../../data/repositories/admin_package_repository.dart';
import 'package_editor.dart';

class AdminPackagesPage extends StatefulWidget {
  const AdminPackagesPage({super.key, this.repository});
  final AdminPackageRepository? repository;
  @override
  State<AdminPackagesPage> createState() => _AdminPackagesPageState();
}

class _AdminPackagesPageState extends State<AdminPackagesPage> {
  late final _repository =
      widget.repository ?? AdminPackageRepository(ApiClient());
  final _search = TextEditingController();
  AdminPackagePageData? _data;
  bool? _active;
  bool _busy = false;
  String? _error;
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
        active: _active,
        page: page,
      );
      if (mounted) setState(() => _data = data);
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = packageError(error);
          _data = null;
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _edit([MembershipPackage? item]) async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PackageEditor(repository: _repository, item: item),
    );
    if (saved == true && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Đã lưu gói dịch vụ.')));
      await _load();
    }
  }

  Future<void> _action(MembershipPackage item, bool delete) async {
    final title = delete
        ? 'Xóa gói chưa sử dụng?'
        : item.active
        ? 'Ngừng bán gói?'
        : 'Mở bán lại gói?';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(
          delete
              ? 'Chỉ xóa được gói chưa có người mua hoặc giao dịch. Nếu gói đã sử dụng, hãy ngừng bán.'
              : 'Gói đã mua và giao dịch đang chờ vẫn giữ quyền lợi tại thời điểm mua.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (delete) {
        await _repository.delete(item);
      } else {
        await _repository.status(item);
      }
      if (!mounted) return;
      setState(() => _busy = false);
      await _load();
    } catch (error) {
      if (mounted) setState(() => _error = packageError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _panel(Widget child) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: Theme.of(context).dividerColor.withValues(alpha: .15),
      ),
    ),
    child: child,
  );
  Widget _badge(MembershipPackage item) => Text(
    item.active ? 'Đang bán' : 'Ngừng bán',
    style: TextStyle(
      color: item.active ? const Color(0xFF298774) : const Color(0xFF9A7272),
      fontWeight: FontWeight.w600,
    ),
  );
  Widget _actions(MembershipPackage item) => Wrap(
    children: [
      IconButton(
        tooltip: 'Sửa ${item.packageName}',
        onPressed: _busy ? null : () => _edit(item),
        icon: const Icon(Icons.edit_outlined),
      ),
      IconButton(
        tooltip: item.active
            ? 'Ngừng bán ${item.packageName}'
            : 'Mở bán ${item.packageName}',
        onPressed: _busy ? null : () => _action(item, false),
        icon: Icon(
          item.active ? Icons.pause_circle_outline : Icons.play_circle_outline,
        ),
      ),
      IconButton(
        tooltip: 'Xóa ${item.packageName}',
        onPressed: _busy ? null : () => _action(item, true),
        icon: const Icon(Icons.delete_outline, color: Color(0xFFB34F4F)),
      ),
    ],
  );
  Widget _packages(bool wide) {
    final items = _data!.items;
    if (items.isEmpty) {
      return _panel(const Center(child: Text('Chưa có gói dịch vụ phù hợp.')));
    }
    if (wide) {
      return _panel(
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Gói dịch vụ')),
              DataColumn(label: Text('Giá (VND)')),
              DataColumn(label: Text('Tin thường')),
              DataColumn(label: Text('Tin VIP')),
              DataColumn(label: Text('Làm mới')),
              DataColumn(label: Text('Trạng thái')),
              DataColumn(label: Text('Thao tác')),
            ],
            rows: [
              for (final item in items)
                DataRow(
                  cells: [
                    DataCell(
                      SizedBox(
                        width: 170,
                        child: Text(
                          item.packageName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        NumberFormat.decimalPattern('vi_VN').format(item.price),
                      ),
                    ),
                    DataCell(Text('${item.standardPostQuota}')),
                    DataCell(Text('${item.vipPostQuota}')),
                    DataCell(Text('${item.refreshQuota}')),
                    DataCell(_badge(item)),
                    DataCell(_actions(item)),
                  ],
                ),
            ],
          ),
        ),
      );
    }
    return Column(
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _panel(
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    item.packageName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _badge(item),
                  const SizedBox(height: 12),
                  Text(
                    '${NumberFormat.decimalPattern('vi_VN').format(item.price)} đ',
                    style: const TextStyle(
                      color: Color(0xFF15803D),
                      fontWeight: FontWeight.w700,
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${item.standardPostQuota} tin thường · ${item.vipPostQuota} tin VIP · ${item.refreshQuota} lượt làm mới',
                  ),
                  if (item.description?.isNotEmpty == true) ...[
                    const SizedBox(height: 10),
                    Text(item.description!),
                  ],
                  Align(
                    alignment: Alignment.centerRight,
                    child: _actions(item),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) => SingleChildScrollView(
      padding: EdgeInsets.all(box.maxWidth < 650 ? 16 : 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Quản lý gói dịch vụ',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          const Text(
            'Quản lý giá bán, quyền lợi và trạng thái hiển thị cho người dùng.',
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.icon(
                onPressed: _busy ? null : () => _edit(),
                icon: const Icon(Icons.add),
                label: const Text('Thêm gói dịch vụ'),
              ),
              OutlinedButton.icon(
                onPressed: _busy ? null : () => _load(),
                icon: const Icon(Icons.refresh),
                label: const Text('Làm mới'),
              ),
            ],
          ),
          const SizedBox(height: 22),
          _panel(
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  key: const ValueKey('package-search'),
                  controller: _search,
                  enabled: !_busy,
                  maxLength: 100,
                  decoration: InputDecoration(
                    labelText: 'Tìm tên gói dịch vụ',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      tooltip: 'Tìm gói',
                      onPressed: _busy ? null : () => _load(),
                      icon: const Icon(Icons.arrow_forward),
                    ),
                  ),
                  onSubmitted: (_) => _load(),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SizedBox(
                      width: 230,
                      child: DropdownButtonFormField<String>(
                        key: ValueKey('package-filter-$_active'),
                        initialValue: _active == null ? '' : _active.toString(),
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Trạng thái',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: '', child: Text('Tất cả')),
                          DropdownMenuItem(
                            value: 'true',
                            child: Text('Đang bán'),
                          ),
                          DropdownMenuItem(
                            value: 'false',
                            child: Text('Ngừng bán'),
                          ),
                        ],
                        onChanged: _busy
                            ? null
                            : (value) {
                                setState(
                                  () => _active = value == ''
                                      ? null
                                      : value == 'true',
                                );
                                _load();
                              },
                      ),
                    ),
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () {
                              setState(() {
                                _active = null;
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
          const SizedBox(height: 20),
          if (_busy) const LinearProgressIndicator(),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: _panel(
                Column(
                  children: [
                    Text(_error!),
                    TextButton(
                      onPressed: _busy ? null : () => _load(),
                      child: const Text('Tải lại danh sách'),
                    ),
                  ],
                ),
              ),
            ),
          if (_data != null) ...[
            Text('${_data!.total} gói phù hợp'),
            const SizedBox(height: 16),
            _packages(box.maxWidth >= 1100),
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
  );
}
