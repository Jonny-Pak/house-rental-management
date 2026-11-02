import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../amenity/data/amenity_model.dart';
import '../../../amenity/data/amenity_repository.dart';
import '../../../listing/data/repositories/listing_repository.dart';
import 'amenity_editor.dart';

class AdminAmenitiesPage extends StatefulWidget {
  const AdminAmenitiesPage({super.key, this.repository});
  final AmenityRepository? repository;
  @override
  State<AdminAmenitiesPage> createState() => _AdminAmenitiesPageState();
}

class _AdminAmenitiesPageState extends State<AdminAmenitiesPage> {
  late final _repository = widget.repository ?? AmenityRepository(ApiClient());
  final _query = TextEditingController();
  AmenityPageData? _data;
  String? _category, _error;
  bool? _active;
  bool _loading = true, _busy = false;
  int _page = 0, _request = 0;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final request = ++_request;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _repository.search(
        query: _query.text,
        category: _category,
        active: _active,
        page: _page,
      );
      if (mounted && request == _request) setState(() => _data = data);
    } catch (error) {
      if (mounted && request == _request) {
        setState(() => _error = ListingRepository.errorMessage(error));
      }
    } finally {
      if (mounted && request == _request) setState(() => _loading = false);
    }
  }

  Future<void> _edit([Amenity? item]) async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AmenityEditor(repository: _repository, item: item),
    );
    if (saved == true && mounted) {
      _page = 0;
      await _load();
    }
  }

  Future<void> _action(Amenity item, bool delete) async {
    if (_busy) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          delete
              ? 'Xóa danh mục?'
              : item.active
              ? 'Ngừng sử dụng?'
              : 'Cho phép sử dụng lại?',
        ),
        content: Text(
          delete
              ? 'Xóa “${item.name}” khỏi danh mục. Chỉ xóa được mục chưa có tin sử dụng.'
              : '“${item.name}” sẽ ${item.active ? 'không còn' : 'được'} xuất hiện trong danh sách chọn mới. Các tin đã chọn mục này vẫn giữ nguyên dữ liệu.',
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
    if (confirm != true || !mounted) return;
    setState(() => _busy = true);
    try {
      if (delete) {
        await _repository.delete(item);
      } else {
        await _repository.changeStatus(item);
      }
      _page = 0;
      if (mounted) await _load();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ListingRepository.errorMessage(error))),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _actions(Amenity item) => Wrap(
    children: [
      IconButton(
        tooltip: 'Sửa ${item.name}',
        onPressed: _busy ? null : () => _edit(item),
        icon: const Icon(Icons.edit_outlined),
      ),
      IconButton(
        tooltip:
            '${item.active ? 'Ngừng sử dụng' : 'Sử dụng lại'} ${item.name}',
        onPressed: _busy ? null : () => _action(item, false),
        icon: Icon(
          item.active ? Icons.pause_circle_outline : Icons.play_circle_outline,
        ),
      ),
      IconButton(
        tooltip: item.listingCount > 0
            ? 'Đã có tin sử dụng ${item.name}'
            : 'Xóa ${item.name}',
        onPressed: _busy || item.listingCount > 0
            ? null
            : () => _action(item, true),
        icon: Icon(
          Icons.delete_outline,
          color: _busy || item.listingCount > 0
              ? Theme.of(context).disabledColor
              : Colors.red,
        ),
      ),
    ],
  );
  Widget _table() {
    final items = _data?.items ?? [];
    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(child: Text('Không có nội thất/tiện ích phù hợp.')),
      );
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Danh mục')),
          DataColumn(label: Text('Nhóm')),
          DataColumn(label: Text('Trạng thái')),
          DataColumn(label: Text('Tin sử dụng')),
          DataColumn(label: Text('Thao tác')),
        ],
        dataRowMinHeight: 64,
        dataRowMaxHeight: 130,
        rows: [
          for (final item in items)
            DataRow(
              cells: [
                DataCell(
                  SizedBox(
                    width: 230,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        if (item.description.isNotEmpty)
                          Text(
                            item.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.muted,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                DataCell(Text(item.categoryLabel)),
                DataCell(
                  Text(
                    item.active ? 'Đang sử dụng' : 'Ngừng sử dụng',
                    style: TextStyle(
                      color: item.active
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                DataCell(Text('${item.listingCount} tin')),
                DataCell(_actions(item)),
              ],
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          runSpacing: 12,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nội thất & tiện ích',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 6),
                Text('Quản lý danh mục để chủ nhà lựa chọn khi đăng tin.'),
              ],
            ),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: _loading || _busy ? null : _load,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Làm mới'),
                ),
                FilledButton.icon(
                  onPressed: _busy ? null : () => _edit(),
                  icon: const Icon(Icons.add),
                  label: const Text('Thêm danh mục'),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),
        TextField(
          key: const ValueKey('amenity-search'),
          controller: _query,
          maxLength: 100,
          decoration: InputDecoration(
            hintText: 'Tìm tên nội thất/tiện ích',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: IconButton(
              tooltip: 'Tìm danh mục',
              onPressed: () {
                _page = 0;
                _load();
              },
              icon: const Icon(Icons.arrow_forward),
            ),
          ),
          onSubmitted: (_) {
            _page = 0;
            _load();
          },
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 240,
              child: DropdownButtonFormField<String>(
                key: ValueKey('amenity-filter-category-$_category'),
                initialValue: _category ?? '',
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Nhóm'),
                items: const [
                  DropdownMenuItem(value: '', child: Text('Tất cả nhóm')),
                  DropdownMenuItem(value: 'FURNITURE', child: Text('Nội thất')),
                  DropdownMenuItem(value: 'UTILITY', child: Text('Tiện ích')),
                ],
                onChanged: (value) {
                  setState(() {
                    _category = value == '' ? null : value;
                    _page = 0;
                  });
                  _load();
                },
              ),
            ),
            SizedBox(
              width: 240,
              child: DropdownButtonFormField<String>(
                key: ValueKey('amenity-filter-active-$_active'),
                initialValue: _active?.toString() ?? '',
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Trạng thái'),
                items: const [
                  DropdownMenuItem(value: '', child: Text('Tất cả trạng thái')),
                  DropdownMenuItem(value: 'true', child: Text('Đang sử dụng')),
                  DropdownMenuItem(
                    value: 'false',
                    child: Text('Ngừng sử dụng'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _active = value == '' ? null : value == 'true';
                    _page = 0;
                  });
                  _load();
                },
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _query.clear();
                  _category = null;
                  _active = null;
                  _page = 0;
                });
                _load();
              },
              child: const Text('Xóa bộ lọc'),
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (_loading) const LinearProgressIndicator(),
        if (_error != null)
          Column(
            children: [
              Text(_error!, style: const TextStyle(color: Colors.red)),
              TextButton(onPressed: _load, child: const Text('Thử lại')),
            ],
          ),
        if (!_loading && _error == null) ...[
          Text('${_data?.total ?? 0} danh mục phù hợp'),
          const SizedBox(height: 12),
          Card(
            margin: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            child: _table(),
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              IconButton(
                tooltip: 'Trang trước',
                onPressed: _page > 0
                    ? () {
                        _page--;
                        _load();
                      }
                    : null,
                icon: const Icon(Icons.chevron_left),
              ),
              Text(
                'Trang ${(_data?.totalPages ?? 0) == 0 ? 0 : _page + 1}/${_data?.totalPages ?? 0}',
              ),
              IconButton(
                tooltip: 'Trang sau',
                onPressed: _page + 1 < (_data?.totalPages ?? 0)
                    ? () {
                        _page++;
                        _load();
                      }
                    : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ],
      ],
    ),
  );
}
