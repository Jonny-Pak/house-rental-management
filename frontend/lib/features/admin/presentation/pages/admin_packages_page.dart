import 'package:frontend/core/theme/app_colors.dart';

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
      borderRadius: BorderRadius.circular(22),
      border: Border.all(
        color: Theme.of(context).dividerColor.withValues(alpha: .15),
      ),
    ),
    child: child,
  );
  Widget _badge(MembershipPackage item) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final color = item.active
        ? (dark ? const Color(0xFF86E0A1) : AppColors.primary)
        : (dark ? const Color(0xFFBAC4D3) : const Color(0xFF697586));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 6, color: color),
          const SizedBox(width: 6),
          Text(
            item.defaultPackage
                ? 'Gói mặc định'
                : item.active
                ? 'Đang bán'
                : 'Ngừng bán',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

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
        onPressed: _busy || item.defaultPackage
            ? null
            : () => _action(item, false),
        icon: Icon(
          item.active ? Icons.pause_circle_outline : Icons.play_circle_outline,
        ),
      ),
      IconButton(
        tooltip: 'Xóa ${item.packageName}',
        onPressed: _busy || item.defaultPackage
            ? null
            : () => _action(item, true),
        icon: const Icon(Icons.delete_outline, color: Color(0xFFB34F4F)),
      ),
    ],
  );
  Widget _benefit(IconData icon, String label, int count, Color accent) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: .08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: accent),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
            const SizedBox(width: 10),
            Text(
              '$count',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      );

  Widget _packageCard(MembershipPackage item) {
    final colors = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final accent = item.vipPostQuota > 0
        ? (dark ? const Color(0xFFBBA4EA) : const Color(0xFF7760B4))
        : item.price > 0
        ? (dark ? const Color(0xFF86E0A1) : AppColors.primary)
        : (dark ? const Color(0xFFA7C3D7) : const Color(0xFF58768B));
    final icon = item.vipPostQuota > 0
        ? Icons.workspace_premium_outlined
        : item.price > 0
        ? Icons.rocket_launch_outlined
        : Icons.layers_outlined;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accent.withValues(alpha: .22)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: .05),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 5,
            color: accent.withValues(alpha: item.active ? .8 : .25),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: .1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(icon, color: accent, size: 28),
                    ),
                    _badge(item),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  item.packageName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.end,
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    Text(
                      NumberFormat.decimalPattern('vi_VN').format(item.price),
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: accent,
                        letterSpacing: -1,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Text(
                        'VNĐ / gói',
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 44),
                  child: Tooltip(
                    message: item.description ?? '',
                    child: Text(
                      item.description?.isNotEmpty == true
                          ? item.description!
                          : 'Quyền lợi đăng tin và làm mới theo cấu hình gói.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.6,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Divider(color: colors.outlineVariant.withValues(alpha: .5)),
                const SizedBox(height: 8),
                _benefit(
                  Icons.article_outlined,
                  'Tin thường',
                  item.standardPostQuota,
                  accent,
                ),
                _benefit(
                  Icons.star_outline_rounded,
                  'Nâng VIP',
                  item.vipPostQuota,
                  accent,
                ),
                _benefit(
                  Icons.autorenew_rounded,
                  'Lượt làm mới',
                  item.refreshQuota,
                  accent,
                ),
                const SizedBox(height: 12),
                Divider(color: colors.outlineVariant.withValues(alpha: .5)),
                const SizedBox(height: 8),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Text(
                      'Mã gói #${item.id}',
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    _actions(item),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _packages() {
    final items = _data!.items;
    if (items.isEmpty) {
      return _panel(
        const Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 44,
                color: Color(0xFF58768B),
              ),
              SizedBox(height: 14),
              Text('Chưa có gói dịch vụ phù hợp.', textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, box) {
        final columns = box.maxWidth >= 1100
            ? 3
            : box.maxWidth >= 720
            ? 2
            : 1;
        final width = (box.maxWidth - (columns - 1) * 20) / columns;
        return Wrap(
          spacing: 20,
          runSpacing: 20,
          children: [
            for (final item in items)
              SizedBox(width: width, child: _packageCard(item)),
          ],
        );
      },
    );
  }

  InputDecoration _input(String label) => InputDecoration(
    labelText: label,
    counterText: '',
    filled: true,
    fillColor: Theme.of(context).colorScheme.surfaceContainerLowest,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(
        color: Theme.of(context).colorScheme.outlineVariant
            .withValues(alpha: .6),
      ),
    ),
  );

  Widget _header() => Wrap(
    alignment: WrapAlignment.spaceBetween,
    spacing: 24,
    runSpacing: 20,
    children: [
      const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DỊCH VỤ & QUYỀN LỢI',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 11,
              letterSpacing: 1.8,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Quản lý gói dịch vụ',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 10),
          Text(
            'Thiết lập giá bán, quyền lợi và trạng thái mở bán.',
            style: TextStyle(height: 1.5),
          ),
        ],
      ),
      Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          OutlinedButton.icon(
            onPressed: _busy ? null : () => _load(),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Làm mới'),
          ),
          FilledButton.icon(
            onPressed: _busy ? null : () => _edit(),
            icon: const Icon(Icons.add_rounded, size: 20),
            label: const Text('Thêm gói dịch vụ'),
          ),
        ],
      ),
    ],
  );

  Widget _filters() => _panel(
    LayoutBuilder(
      builder: (context, box) {
        final compact = box.maxWidth < 720;
        return Wrap(
          spacing: 14,
          runSpacing: 14,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: compact ? box.maxWidth : box.maxWidth - 386,
              child: TextField(
                key: const ValueKey('package-search'),
                controller: _search,
                enabled: !_busy,
                maxLength: 100,
                decoration: _input('Tìm tên gói dịch vụ').copyWith(
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: IconButton(
                    tooltip: 'Tìm gói',
                    onPressed: _busy ? null : () => _load(),
                    icon: const Icon(Icons.arrow_forward_rounded),
                  ),
                ),
                onSubmitted: (_) => _load(),
              ),
            ),
            SizedBox(
              width: compact ? box.maxWidth : 230,
              child: DropdownButtonFormField<String>(
                key: ValueKey('package-filter-$_active'),
                initialValue: _active == null ? '' : _active.toString(),
                isExpanded: true,
                decoration: _input('Trạng thái'),
                items: const [
                  DropdownMenuItem(value: '', child: Text('Tất cả')),
                  DropdownMenuItem(value: 'true', child: Text('Đang bán')),
                  DropdownMenuItem(value: 'false', child: Text('Ngừng bán')),
                ],
                onChanged: _busy
                    ? null
                    : (value) {
                        setState(
                          () => _active = value == '' ? null : value == 'true',
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
        );
      },
    ),
  );

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF141A1D)
        : const Color(0xFFF6F8FA),
    child: LayoutBuilder(
      builder: (context, box) => SingleChildScrollView(
        padding: EdgeInsets.all(box.maxWidth < 650 ? 16 : 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _header(),
            const SizedBox(height: 26),
            _filters(),
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
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                spacing: 12,
                runSpacing: 8,
                children: [
                  Text(
                    '${_data!.total} gói phù hợp',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'Giá và quyền lợi áp dụng cho lần mua mới',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _packages(),
              const SizedBox(height: 20),
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
