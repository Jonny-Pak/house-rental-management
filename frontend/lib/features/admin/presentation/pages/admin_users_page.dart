import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../data/models/admin_user.dart';
import '../../data/repositories/admin_user_repository.dart';
import '../widgets/admin_user_dialog.dart';
import '../widgets/admin_user_badges.dart';
import '../widgets/admin_create_user_dialog.dart';

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key, this.repository});
  final AdminUserRepository? repository;

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  late final _repository =
      widget.repository ?? AdminUserRepository(ApiClient());
  final _search = TextEditingController();
  AdminUserPage? _data;
  String? _role;
  String? _status;
  bool? _verified;
  String? _error;
  bool _loading = true;
  bool _acting = false;
  int _request = 0;
  int _page = 0;

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
    setState(() {
      _loading = true;
      _error = null;
      _page = page;
    });
    try {
      final data = await _repository.search(
        query: _search.text,
        role: _role,
        status: _status,
        verified: _verified,
        page: page,
      );
      if (!mounted || request != _request) return;
      if (page > 0 && data.items.isEmpty) {
        await _load(page: page - 1);
        return;
      }
      setState(() {
        _data = data;
        _loading = false;
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

  void _message(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _add() async {
    if (_acting) return;
    setState(() => _acting = true);
    try {
      final user = await showDialog<AdminUser>(
        context: context,
        barrierDismissible: false,
        builder: (_) => AdminCreateUserDialog(repository: _repository),
      );
      if (user == null || !mounted) return;
      _search.clear();
      setState(() {
        _role = null;
        _status = null;
        _verified = null;
      });
      _message('Đã tạo ${user.email}. Người dùng cần xác thực OTP trên app.');
      await _load();
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  Future<void> _open(AdminUser row, {bool readOnly = false}) async {
    if (_acting) return;
    setState(() => _acting = true);
    try {
      final user = await _repository.detail(row.id);
      if (!mounted) return;
      final saved = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => AdminUserDialog(
          user: user,
          repository: _repository,
          readOnly: readOnly,
        ),
      );
      if (saved == true && mounted) {
        _message('Đã cập nhật người dùng.');
        await _load(page: _page);
      }
    } catch (error) {
      if (mounted) _message(adminUserError(error));
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  Future<void> _changeStatus(AdminUser user) async {
    if (_acting || user.isAdmin) return;
    final action = user.locked ? 'Mở khóa' : 'Khóa';
    setState(() => _acting = true);
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('$action tài khoản?'),
          content: Text(
            '$action tài khoản ${user.fullName} (${user.email}). '
            '${user.locked ? 'Người dùng có thể đăng nhập trở lại.' : 'Người dùng sẽ không thể đăng nhập hoặc sử dụng phiên đăng nhập cũ.'}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(action),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
      await _repository.changeStatus(
        user.id,
        user.locked ? 'ACTIVE' : 'LOCKED',
      );
      if (!mounted) return;
      _message('Đã ${action.toLowerCase()} tài khoản.');
      await _load(page: _page);
    } catch (error) {
      if (mounted) _message(adminUserError(error));
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  Color get _border => Theme.of(context).brightness == Brightness.dark
      ? Theme.of(context).colorScheme.outlineVariant.withValues(alpha: .6)
      : const Color(0xFFE6E9EE);
  Color get _muted => Theme.of(context).brightness == Brightness.dark
      ? Theme.of(context).colorScheme.onSurfaceVariant
      : const Color(0xFF667085);
  Color get _surface => Theme.of(context).brightness == Brightness.dark
      ? Theme.of(context).colorScheme.surface
      : Colors.white;

  BoxDecoration get _panel => BoxDecoration(
    color: _surface,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: _border),
  );

  InputDecoration _input(String hint, {Widget? prefix, Widget? suffix}) =>
      InputDecoration(
        hintText: hint,
        prefixIcon: prefix,
        suffixIcon: suffix,
        counterText: '',
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceContainerLowest,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: _border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFD66A2B)),
        ),
      );

  Widget _filter(
    String label,
    String value,
    Map<String, String> options,
    ValueChanged<String?> onChanged,
  ) => SizedBox(
    width: 200,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: _muted,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          key: ValueKey('$label:$value'),
          initialValue: value,
          isExpanded: true,
          decoration: _input(''),
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 20,
            color: _muted,
          ),
          style: Theme.of(context).textTheme.bodyMedium,
          items: options.entries
              .map(
                (entry) => DropdownMenuItem(
                  value: entry.key,
                  child: Text(entry.value),
                ),
              )
              .toList(),
          onChanged: _acting ? null : onChanged,
        ),
      ],
    ),
  );

  Widget _action(
    String tooltip,
    IconData icon,
    VoidCallback? onTap,
    Color color,
  ) => DecoratedBox(
    decoration: BoxDecoration(
      border: Border.all(color: _border),
      borderRadius: BorderRadius.circular(9),
    ),
    child: IconButton(
      tooltip: tooltip,
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      color: color,
      constraints: const BoxConstraints.tightFor(width: 38, height: 38),
      padding: const EdgeInsets.all(8),
    ),
  );

  Widget _actions(AdminUser user) => Wrap(
    spacing: 6,
    runSpacing: 6,
    children: [
      _action(
        'Xem chi tiết',
        Icons.visibility_outlined,
        _acting ? null : () => _open(user, readOnly: true),
        _muted,
      ),
      _action(
        'Chỉnh sửa',
        Icons.edit_outlined,
        _acting || user.isAdmin ? null : () => _open(user),
        const Color(0xFFD66A2B),
      ),
      _action(
        user.locked ? 'Mở khóa' : 'Khóa tài khoản',
        user.locked ? Icons.lock_open_rounded : Icons.lock_outline_rounded,
        _acting || user.isAdmin ? null : () => _changeStatus(user),
        user.locked ? const Color(0xFF268265) : const Color(0xFFCC4D56),
      ),
    ],
  );

  Widget _identity(AdminUser user) => Row(
    children: [
      AdminUserAvatar(user: user),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user.fullName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              'ID #${user.id}',
              style: TextStyle(fontSize: 12, color: _muted),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _contact(AdminUser user) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        user.email,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 13),
      ),
      const SizedBox(height: 5),
      Text(
        user.phoneNumber ?? 'Chưa có số điện thoại',
        style: TextStyle(fontSize: 12, color: _muted),
      ),
    ],
  );

  Widget _table(List<AdminUser> users) => LayoutBuilder(
    builder: (context, constraints) => SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: constraints.maxWidth),
        child: DataTable(
          columnSpacing: 24,
          horizontalMargin: 22,
          headingRowHeight: 48,
          dataRowMinHeight: 82,
          dataRowMaxHeight: 96,
          dividerThickness: .6,
          headingRowColor: WidgetStatePropertyAll(
            Theme.of(context).colorScheme.surfaceContainerLowest,
          ),
          headingTextStyle: TextStyle(
            color: _muted,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          columns: const [
            DataColumn(label: Text('NGƯỜI DÙNG')),
            DataColumn(label: Text('LIÊN HỆ')),
            DataColumn(label: Text('VAI TRÒ')),
            DataColumn(label: Text('TRẠNG THÁI')),
            DataColumn(label: Text('XÁC THỰC EMAIL')),
            DataColumn(label: Text('THAO TÁC')),
          ],
          rows: users
              .map(
                (user) => DataRow(
                  cells: [
                    DataCell(SizedBox(width: 235, child: _identity(user))),
                    DataCell(SizedBox(width: 225, child: _contact(user))),
                    DataCell(adminRoleBadge(user)),
                    DataCell(adminStatusBadge(user)),
                    DataCell(adminVerifiedBadge(user)),
                    DataCell(SizedBox(width: 156, child: _actions(user))),
                  ],
                ),
              )
              .toList(),
        ),
      ),
    ),
  );

  Widget _card(AdminUser user) => Container(
    margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
    padding: const EdgeInsets.all(16),
    decoration: _panel,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _identity(user),
        const SizedBox(height: 16),
        _contact(user),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            adminRoleBadge(user),
            adminStatusBadge(user),
            adminVerifiedBadge(user),
          ],
        ),
        const SizedBox(height: 14),
        Align(alignment: Alignment.centerRight, child: _actions(user)),
      ],
    ),
  );

  Widget _empty(IconData icon, String text, {Widget? action}) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
    child: Column(
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFFD66A2B).withValues(alpha: .08),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 32, color: const Color(0xFFD66A2B)),
        ),
        const SizedBox(height: 16),
        Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(color: _muted),
        ),
        if (action != null) ...[const SizedBox(height: 16), action],
      ],
    ),
  );

  Widget _pagination(AdminUserPage data) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
    decoration: BoxDecoration(
      border: Border(top: BorderSide(color: _border)),
    ),
    child: Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 16,
      runSpacing: 12,
      children: [
        Text(
          'Hiển thị ${data.page * 20 + 1}–${data.page * 20 + data.items.length} trong ${data.total} tài khoản',
          style: TextStyle(fontSize: 12, color: _muted),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _action(
              'Trang trước',
              Icons.chevron_left,
              data.page > 0 && !_acting
                  ? () => _load(page: data.page - 1)
                  : null,
              _muted,
            ),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Text(
                  'Trang ${data.page + 1}/${data.totalPages}',
                  style: const TextStyle(fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            _action(
              'Trang sau',
              Icons.chevron_right,
              data.page + 1 < data.totalPages && !_acting
                  ? () => _load(page: data.page + 1)
                  : null,
              _muted,
            ),
          ],
        ),
      ],
    ),
  );

  Widget _results(bool wide) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(60),
        child: Center(
          child: SizedBox.square(
            dimension: 28,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    if (_error != null) {
      return _empty(
        Icons.cloud_off_outlined,
        _error!,
        action: OutlinedButton.icon(
          onPressed: () => _load(page: _page),
          icon: const Icon(Icons.refresh, size: 18),
          label: const Text('Thử lại'),
        ),
      );
    }
    final data = _data!;
    if (data.items.isEmpty) {
      return _empty(
        Icons.person_search_outlined,
        'Không có người dùng phù hợp.',
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (wide) _table(data.items) else ...data.items.map(_card),
        _pagination(data),
      ],
    );
  }

  Widget _header() => Wrap(
    alignment: WrapAlignment.spaceBetween,
    spacing: 20,
    runSpacing: 16,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: const Color(0xFFD66A2B).withValues(alpha: .1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.manage_accounts_outlined,
              color: Color(0xFFD66A2B),
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          const Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'QUẢN TRỊ TÀI KHOẢN',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                    color: Color(0xFF9C765F),
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Quản lý người dùng',
                  style: TextStyle(
                    fontSize: 26,
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
        spacing: 12,
        runSpacing: 12,
        children: [
          FilledButton.icon(
            onPressed: _loading || _acting ? null : _add,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFD66A2B),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: const Icon(Icons.person_add_alt_1_outlined, size: 18),
            label: const Text('Thêm người dùng'),
          ),
          OutlinedButton.icon(
            onPressed: _loading || _acting ? null : () => _load(page: _page),
            style: OutlinedButton.styleFrom(
              foregroundColor: _muted,
              backgroundColor: _surface,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              side: BorderSide(color: _border),
            ),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Làm mới'),
          ),
        ],
      ),
    ],
  );

  void _clearFilters() {
    _search.clear();
    setState(() {
      _role = null;
      _status = null;
      _verified = null;
    });
    _load();
  }

  Widget _filters() => Container(
    padding: const EdgeInsets.all(22),
    decoration: _panel,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _search,
          maxLength: 100,
          enabled: !_acting,
          decoration: _input(
            'Tìm họ tên, email hoặc số điện thoại',
            prefix: Icon(Icons.search_rounded, size: 21, color: _muted),
            suffix: Padding(
              padding: const EdgeInsets.all(5),
              child: IconButton.filledTonal(
                tooltip: 'Tìm kiếm',
                onPressed: _acting ? null : _load,
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFD66A2B)
                      .withValues(alpha: .1),
                  foregroundColor: const Color(0xFFD66A2B),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              ),
            ),
          ),
          onSubmitted: (_) => _load(),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          crossAxisAlignment: WrapCrossAlignment.end,
          children: [
            _filter(
              'Vai trò',
              _role ?? '',
              const {
                '': 'Tất cả vai trò',
                'MEMBER': 'Member',
                'ADMIN': 'Admin',
              },
              (value) {
                setState(() => _role = value == '' ? null : value);
                _load();
              },
            ),
            _filter(
              'Trạng thái',
              _status ?? '',
              const {
                '': 'Tất cả trạng thái',
                'ACTIVE': 'Hoạt động',
                'LOCKED': 'Đã khóa',
              },
              (value) {
                setState(() => _status = value == '' ? null : value);
                _load();
              },
            ),
            _filter(
              'Xác thực email',
              _verified?.toString() ?? '',
              const {
                '': 'Tất cả',
                'true': 'Đã xác thực',
                'false': 'Chưa xác thực',
              },
              (value) {
                setState(
                  () => _verified = value == '' ? null : value == 'true',
                );
                _load();
              },
            ),
            TextButton.icon(
              onPressed: _acting ? null : _clearFilters,
              style: TextButton.styleFrom(
                foregroundColor: _muted,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 18,
                ),
              ),
              icon: const Icon(Icons.filter_alt_off_outlined, size: 17),
              label: const Text('Xóa bộ lọc'),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _listHeader() => Padding(
    padding: const EdgeInsets.all(22),
    child: Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 16,
      runSpacing: 8,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Flexible(
              child: Text(
                'Danh sách tài khoản',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
            ),
            const SizedBox(width: 10),
            AdminUserBadge(
              label: _loading || _error != null ? '—' : '${_data?.total ?? 0}',
              color: const Color(0xFFD66A2B),
            ),
          ],
        ),
        Text(
          '20 tài khoản / trang',
          style: TextStyle(color: _muted, fontSize: 12),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => SizedBox.expand(
    child: ColoredBox(
      color: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF15171C)
          : const Color(0xFFF6F7F9),
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          padding: EdgeInsets.all(constraints.maxWidth < 600 ? 16 : 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _header(),
              const SizedBox(height: 24),
              _filters(),
              const SizedBox(height: 24),
              Container(
                decoration: _panel,
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _listHeader(),
                    Divider(height: 1, color: _border),
                    _results(constraints.maxWidth >= 1000),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.shield_outlined, size: 16, color: _muted),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tài khoản Admin được bảo vệ và chỉ có thể xem thông tin tại đây.',
                      style: TextStyle(color: _muted, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
