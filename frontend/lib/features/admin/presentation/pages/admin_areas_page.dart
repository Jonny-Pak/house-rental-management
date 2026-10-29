import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../data/models/admin_area.dart';
import '../../data/repositories/admin_area_repository.dart';
import '../../data/repositories/admin_user_repository.dart' show adminUserError;
import '../widgets/admin_area_dialog.dart';
import '../widgets/admin_area_style.dart';
import '../widgets/admin_user_badges.dart' show AdminUserBadge;

class AdminAreasPage extends StatefulWidget {
  const AdminAreasPage({super.key, this.repository});
  final AdminAreaRepository? repository;
  @override
  State<AdminAreasPage> createState() => _AdminAreasPageState();
}

class _AdminAreasPageState extends State<AdminAreasPage> {
  late final _repository =
      widget.repository ?? AdminAreaRepository(ApiClient());
  final _search = TextEditingController();
  List<AdminArea> _parents = [];
  AdminAreaPage? _data;
  String? _type, _error;
  int? _parent;
  bool? _active;
  bool _loading = true, _acting = false;
  int _request = 0, _page = 0;
  static const _accent = Color(0xFF15803D);

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

  Future<void> _load({int page = 0}) async {
    final request = ++_request;
    final query = _search.text, type = _type;
    final parent = _parent, active = _active;
    setState(() {
      _loading = true;
      _error = null;
      _page = page;
    });
    try {
      final parents = await _repository.parents();
      final data = await _repository.search(
        query: query,
        type: type,
        parentId: parent,
        active: active,
        page: page,
      );
      if (!mounted || request != _request) return;
      if (page > 0 && data.items.isEmpty) {
        await _load(page: page - 1);
        return;
      }
      setState(() {
        _parents = parents;
        _data = data;
        _loading = false;
        if (_parent != null && !parents.any((p) => p.id == _parent)) {
          _parent = null;
        }
      });
    } catch (error) {
      if (mounted && request == _request) {
        setState(() {
          _error = adminUserError(error);
          _loading = false;
        });
      }
    }
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _edit([AdminArea? row]) async {
    if (_acting) return;
    setState(() => _acting = true);
    try {
      final area = row == null ? null : await _repository.detail(row.id);
      final parents = await _repository.parents();
      if (!mounted) return;
      final saved = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => AdminAreaDialog(
          repository: _repository,
          area: area,
          parents: parents,
        ),
      );
      if (saved == true && mounted) {
        if (row == null) {
          _search.clear();
          _type = null;
          _parent = null;
          _active = null;
        }
        _message(row == null ? 'Đã thêm khu vực.' : 'Đã cập nhật khu vực.');
        await _load(page: row == null ? 0 : _page);
      }
    } catch (error) {
      if (mounted) _message(adminUserError(error));
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  Future<void> _change(AdminArea area, {bool delete = false}) async {
    if (_acting) return;
    final action = delete
        ? 'Xóa khu vực'
        : area.active
        ? 'Ngừng sử dụng'
        : 'Kích hoạt';
    setState(() => _acting = true);
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(action),
          content: Text(
            delete
                ? 'Xóa ${area.name}? Chỉ xóa được khu vực chưa có dữ liệu liên quan.'
                : area.active
                ? 'Ngừng sử dụng ${area.name}? Khu vực sẽ không xuất hiện khi chọn địa chỉ mới. Tin đăng và hợp đồng cũ được giữ lại.'
                : 'Kích hoạt lại ${area.name} để người dùng có thể chọn khu vực này?',
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
      if (confirmed != true || !mounted) return;
      if (delete) {
        await _repository.delete(area.id);
      } else {
        await _repository.changeStatus(area.id, !area.active);
      }
      if (!mounted) return;
      _message('Đã cập nhật danh sách khu vực.');
      if (delete && _parent == area.id) _parent = null;
      await _load(page: _page);
    } catch (error) {
      if (mounted) _message(adminUserError(error));
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  Color get _surface => Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFF1E232C)
      : Colors.white;

  Widget _panel(
    Widget child, {
    EdgeInsetsGeometry padding = const EdgeInsets.all(22),
  }) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: _surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: areaBorder(context)),
    ),
    child: child,
  );

  Widget _tile(IconData icon, Color color, {double size = 40}) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: color.withValues(alpha: .10),
      borderRadius: BorderRadius.circular(11),
    ),
    child: Icon(icon, color: color, size: size * .5),
  );

  Widget _header() => Wrap(
    alignment: WrapAlignment.spaceBetween,
    runSpacing: 18,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _tile(Icons.location_city_outlined, _accent, size: 50),
          const SizedBox(width: 14),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'QUẢN LÝ DANH MỤC',
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 1.4,
                    fontWeight: FontWeight.w600,
                    color: areaMuted(context),
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Khu vực hành chính',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          OutlinedButton.icon(
            onPressed: _loading || _acting ? null : () => _load(page: _page),
            style: OutlinedButton.styleFrom(
              foregroundColor: areaMuted(context),
              backgroundColor: _surface,
              side: BorderSide(color: areaBorder(context)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Làm mới'),
          ),
          FilledButton.icon(
            onPressed: _acting ? null : () => _edit(),
            style: FilledButton.styleFrom(
              backgroundColor: _accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: const Icon(Icons.add_rounded, size: 19),
            label: const Text('Thêm khu vực'),
          ),
        ],
      ),
    ],
  );

  Widget _filters(double width) {
    final available = width - 46;
    final compact = available < 700;
    final fieldWidth = compact ? available : (available - 24) / 3;
    return _panel(
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 8,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.tune_rounded, size: 18, color: areaMuted(context)),
                  const SizedBox(width: 8),
                  const Flexible(
                    child: Text(
                      'Tìm kiếm & bộ lọc',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: () {
                  _search.clear();
                  setState(() {
                    _type = null;
                    _parent = null;
                    _active = null;
                  });
                  _load();
                },
                style: TextButton.styleFrom(
                  foregroundColor: areaMuted(context),
                  textStyle: Theme.of(context).textTheme.labelMedium
                      ?.copyWith(fontSize: 12),
                ),
                icon: const Icon(Icons.restart_alt_rounded, size: 16),
                label: const Text('Xóa bộ lọc'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _search,
            maxLength: 100,
            onSubmitted: (_) => _load(),
            style: const TextStyle(fontSize: 14),
            decoration:
                areaInput(
                  context,
                  'Tìm tên hoặc mã khu vực',
                  icon: Icons.search_rounded,
                  search: true,
                ).copyWith(
                  suffixIcon: IconButton(
                    tooltip: 'Tìm khu vực',
                    onPressed: () => _load(),
                    icon: const Icon(
                      Icons.arrow_forward_rounded,
                      size: 19,
                      color: areaAccent,
                    ),
                  ),
                ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 16,
            children: [
              SizedBox(
                width: fieldWidth,
                child: DropdownButtonFormField<String>(
                  key: ValueKey('area-filter-type-$_type'),
                  initialValue: _type,
                  isExpanded: true,
                  style: Theme.of(context).textTheme.bodyMedium,
                  decoration: areaInput(
                    context,
                    'Cấp hành chính',
                    icon: Icons.layers_outlined,
                  ),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('Tất cả cấp'),
                    ),
                    for (final e in areaTypes.entries)
                      DropdownMenuItem(value: e.key, child: Text(e.value)),
                  ],
                  onChanged: (v) {
                    setState(() => _type = v);
                    _load();
                  },
                ),
              ),
              SizedBox(
                width: fieldWidth,
                child: DropdownButtonFormField<int>(
                  key: ValueKey('area-filter-parent-$_parent'),
                  initialValue: _parent,
                  isExpanded: true,
                  style: Theme.of(context).textTheme.bodyMedium,
                  decoration: areaInput(
                    context,
                    'Trực thuộc',
                    icon: Icons.account_tree_outlined,
                  ),
                  items: [
                    const DropdownMenuItem<int>(
                      value: null,
                      child: Text('Tất cả đơn vị'),
                    ),
                    for (final p in _parents)
                      DropdownMenuItem(
                        value: p.id,
                        child: Text(
                          '${p.name} (${p.code})',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (v) {
                    setState(() => _parent = v);
                    _load();
                  },
                ),
              ),
              SizedBox(
                width: fieldWidth,
                child: DropdownButtonFormField<bool>(
                  key: ValueKey('area-filter-active-$_active'),
                  initialValue: _active,
                  isExpanded: true,
                  style: Theme.of(context).textTheme.bodyMedium,
                  decoration: areaInput(
                    context,
                    'Trạng thái',
                    icon: Icons.radio_button_checked_rounded,
                  ),
                  items: const [
                    DropdownMenuItem<bool>(
                      value: null,
                      child: Text('Tất cả trạng thái'),
                    ),
                    DropdownMenuItem(value: true, child: Text('Đang sử dụng')),
                    DropdownMenuItem(
                      value: false,
                      child: Text('Ngừng sử dụng'),
                    ),
                  ],
                  onChanged: (v) {
                    setState(() => _active = v);
                    _load();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _status(AdminArea area) => AdminUserBadge(
    label: area.active ? 'Đang sử dụng' : 'Ngừng sử dụng',
    color: area.active ? const Color(0xFF298774) : const Color(0xFF8792A2),
    dot: true,
  );

  Widget _typeBadge(AdminArea area) =>
      AdminUserBadge(label: area.typeLabel, color: areaTypeColor(area.type));

  Widget _actionButton(
    String tooltip,
    IconData icon,
    Color color,
    VoidCallback? action,
  ) => IconButton(
    tooltip: tooltip,
    onPressed: action,
    style: IconButton.styleFrom(
      minimumSize: const Size(36, 36),
      maximumSize: const Size(36, 36),
      padding: EdgeInsets.zero,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      backgroundColor: color.withValues(alpha: .07),
      foregroundColor: color,
      disabledForegroundColor: areaMuted(context).withValues(alpha: .35),
      disabledBackgroundColor: areaMuted(context).withValues(alpha: .04),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
    ),
    icon: Icon(icon, size: 18),
  );

  Widget _actions(AdminArea area) => Wrap(
    spacing: 7,
    runSpacing: 7,
    children: [
      _actionButton(
        'Sửa khu vực',
        Icons.edit_outlined,
        const Color(0xFF567CB5),
        _acting ? null : () => _edit(area),
      ),
      _actionButton(
        area.active ? 'Ngừng sử dụng' : 'Kích hoạt',
        area.active ? Icons.pause_rounded : Icons.play_arrow_rounded,
        area.active ? const Color(0xFFC68C37) : const Color(0xFF298774),
        _acting ? null : () => _change(area),
      ),
      _actionButton(
        area.used ? 'Đang có dữ liệu liên quan' : 'Xóa khu vực',
        Icons.delete_outline_rounded,
        const Color(0xFFC36161),
        _acting || area.used ? null : () => _change(area, delete: true),
      ),
    ],
  );

  Widget _identity(AdminArea area) => Row(
    children: [
      _tile(areaTypeIcon(area.type), areaTypeColor(area.type)),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              area.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              area.code,
              style: TextStyle(
                fontSize: 11,
                letterSpacing: .3,
                color: areaMuted(context),
              ),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _usage(AdminArea area) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.account_tree_outlined,
            size: 13,
            color: areaMuted(context),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              '${area.children} đơn vị con',
              style: TextStyle(fontSize: 12, color: areaMuted(context)),
            ),
          ),
        ],
      ),
      const SizedBox(height: 5),
      Text(
        '${area.listingCount} tin · ${area.propertyCount} khu trọ',
        style: TextStyle(fontSize: 12, color: areaMuted(context)),
      ),
    ],
  );

  Widget _table(double width) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: ConstrainedBox(
      constraints: BoxConstraints(minWidth: width),
      child: DataTable(
        horizontalMargin: 22,
        columnSpacing: 24,
        dividerThickness: .6,
        border: TableBorder(
          horizontalInside: BorderSide(color: areaBorder(context), width: .6),
        ),
        headingRowHeight: 48,
        dataRowMinHeight: 84,
        dataRowMaxHeight: 92,
        headingRowColor: WidgetStatePropertyAll(
          Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF242A34)
              : const Color(0xFFFAFBFD),
        ),
        headingTextStyle: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: areaMuted(context),
        ),
        dataTextStyle: Theme.of(context).textTheme.bodyMedium
            ?.copyWith(fontSize: 13),
        columns: const [
          DataColumn(label: Text('KHU VỰC')),
          DataColumn(label: Text('CẤP HÀNH CHÍNH')),
          DataColumn(label: Text('TRỰC THUỘC')),
          DataColumn(label: Text('TRẠNG THÁI')),
          DataColumn(label: Text('DỮ LIỆU LIÊN QUAN')),
          DataColumn(label: Text('THAO TÁC')),
        ],
        rows: [
          for (final area in _data!.items)
            DataRow(
              cells: [
                DataCell(SizedBox(width: 250, child: _identity(area))),
                DataCell(_typeBadge(area)),
                DataCell(
                  SizedBox(
                    width: 170,
                    child: Row(
                      children: [
                        Icon(
                          Icons.subdirectory_arrow_right_rounded,
                          size: 16,
                          color: areaMuted(context),
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            area.parentName ?? 'Đơn vị cấp tỉnh',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                DataCell(_status(area)),
                DataCell(_usage(area)),
                DataCell(SizedBox(width: 122, child: _actions(area))),
              ],
            ),
        ],
      ),
    ),
  );

  Widget _cards() => Column(
    children: [
      for (final area in _data!.items)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: _panel(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _identity(area),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [_typeBadge(area), _status(area)],
                ),
                const SizedBox(height: 14),
                Text(
                  area.parentName ?? 'Đơn vị cấp tỉnh',
                  style: TextStyle(fontSize: 12, color: areaMuted(context)),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1, color: areaBorder(context)),
                ),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 14,
                  runSpacing: 12,
                  children: [_usage(area), _actions(area)],
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
          ),
        ),
    ],
  );

  Widget _pagination() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    child: Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      runSpacing: 10,
      children: [
        Text(
          _data!.total == 0
              ? 'Không có kết quả'
              : 'Hiển thị ${_page * 20 + 1}–${_page * 20 + _data!.items.length} / ${_data!.total} khu vực',
          style: TextStyle(fontSize: 12, color: areaMuted(context)),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _actionButton(
              'Trang trước',
              Icons.chevron_left_rounded,
              areaMuted(context),
              _page == 0 || _acting ? null : () => _load(page: _page - 1),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                'Trang ${_data!.totalPages == 0 ? 0 : _page + 1}/${_data!.totalPages}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 12),
            _actionButton(
              'Trang sau',
              Icons.chevron_right_rounded,
              areaMuted(context),
              _page + 1 >= _data!.totalPages || _acting
                  ? null
                  : () => _load(page: _page + 1),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _results(double width) => _panel(
    Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(22),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 8,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Flexible(
                    child: Text(
                      'Danh sách khu vực',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _accent.withValues(alpha: .09),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Text(
                      '${_data!.total}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: areaAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                '20 mục / trang',
                style: TextStyle(fontSize: 11, color: areaMuted(context)),
              ),
            ],
          ),
        ),
        if (_data!.items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 44),
            child: Column(
              children: [
                _tile(
                  Icons.location_off_outlined,
                  areaMuted(context),
                  size: 56,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Chưa có khu vực phù hợp.',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Text(
                  'Thử đổi từ khóa hoặc xóa bộ lọc để tìm lại.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: areaMuted(context)),
                ),
              ],
            ),
          )
        else if (width >= 1100)
          _table(width - 2)
        else
          _cards(),
        Divider(height: 1, color: areaBorder(context)),
        _pagination(),
      ],
    ),
    padding: EdgeInsets.zero,
  );

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF171C24)
        : const Color(0xFFF5F7FA),
    child: SizedBox.expand(
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          padding: EdgeInsets.all(constraints.maxWidth < 650 ? 16 : 28),
          child: LayoutBuilder(
            builder: (context, box) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _header(),
                const SizedBox(height: 10),
                Text(
                  'Quản lý địa chỉ dùng trong tin đăng và khu trọ.',
                  style: TextStyle(fontSize: 13, color: areaMuted(context)),
                ),
                const SizedBox(height: 24),
                _filters(box.maxWidth),
                const SizedBox(height: 22),
                if (_loading)
                  _panel(
                    const Padding(
                      padding: EdgeInsets.all(48),
                      child: Center(
                        child: CircularProgressIndicator(color: areaAccent),
                      ),
                    ),
                  )
                else if (_error != null)
                  _panel(
                    Column(
                      children: [
                        Icon(
                          Icons.cloud_off_outlined,
                          color: areaMuted(context),
                          size: 32,
                        ),
                        const SizedBox(height: 12),
                        Text(_error!, textAlign: TextAlign.center),
                        TextButton(
                          onPressed: () => _load(page: _page),
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  )
                else
                  _results(box.maxWidth),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
