import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../app/admin/auth/session.dart';
import '../../../../../app/admin/theme/app_theme.dart';
import '../../../../../core/layout/app_layout.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../auth/data/repositories/password_repository.dart';
import '../../../../auth/presentation/pages/password_page.dart';
import '../../../../user/data/datasources/user_remote_data_source.dart';
import '../../../../user/data/models/user_profile.dart';
import '../../../../user/data/repositories/user_repository.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({
    super.key,
    this.accountRepository,
    this.passwordRepository,
  });
  final UserRepository? accountRepository;
  final PasswordRepository? passwordRepository;
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final _accounts =
      widget.accountRepository ??
      UserRepositoryImpl(UserRemoteDataSourceImpl(ApiClient()));
  UserProfile? _profile;
  String? _error;
  bool _loading = false, _leaving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final profile = await _accounts.getProfile();
      if (mounted) setState(() => _profile = profile);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Chưa tải được thông tin tài khoản. Vui lòng thử lại.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _setMode(ThemeMode mode) async {
    final saved = await ref.read(themeProvider.notifier).setMode(mode);
    if (!saved && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Đã đổi giao diện nhưng chưa lưu được lựa chọn trên trình duyệt.',
          ),
        ),
      );
    }
  }

  Future<void> _changePassword() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PasswordPage(
          changePassword: true,
          repository: widget.passwordRepository,
        ),
      ),
    );
    if (changed == true && mounted) await _signOut(confirm: false);
  }

  Future<void> _signOut({bool confirm = true}) async {
    if (_leaving) return;
    if (confirm) {
      final accepted = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Đăng xuất?'),
          content: const Text('Bạn muốn kết thúc phiên đăng nhập hiện tại?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Đăng xuất'),
            ),
          ],
        ),
      );
      if (accepted != true || !mounted || _leaving) return;
    }
    setState(() => _leaving = true);
    try {
      await ref.read(sessionProvider.notifier).signOut();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Chưa đăng xuất được. Vui lòng thử lại.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _leaving = false);
    }
  }

  Widget _card(
    IconData icon,
    String title,
    List<Widget> children, {
    Widget action = const SizedBox.shrink(),
  }) {
    final colors = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: dark ? const Color(0xFF303B35) : const Color(0xFFE3E9E5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: colors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              action,
            ],
          ),
          const SizedBox(height: 18),
          ...children,
        ],
      ),
    );
  }

  Widget _appearance(ThemeState theme) =>
      _card(Icons.palette_outlined, 'Giao diện', [
        LayoutBuilder(
          builder: (context, box) {
            final width = box.maxWidth >= 520
                ? (box.maxWidth - 24) / 3
                : box.maxWidth;
            return Wrap(
              spacing: 12,
              runSpacing: 10,
              children: [
                SizedBox(
                  width: width,
                  child: _mode(
                    theme.mode,
                    ThemeMode.light,
                    Icons.light_mode_outlined,
                    'Sáng',
                  ),
                ),
                SizedBox(
                  width: width,
                  child: _mode(
                    theme.mode,
                    ThemeMode.dark,
                    Icons.dark_mode_outlined,
                    'Tối',
                  ),
                ),
                SizedBox(
                  width: width,
                  child: _mode(
                    theme.mode,
                    ThemeMode.system,
                    Icons.brightness_auto_outlined,
                    'Theo hệ thống',
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        Text(
          'Tự động lưu lựa chọn trên trình duyệt này.',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 12,
            height: 1.5,
          ),
        ),
      ]);

  Widget _mode(ThemeMode current, ThemeMode mode, IconData icon, String label) {
    final colors = Theme.of(context).colorScheme;
    final selected = current == mode;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: selected ? colors.primary.withValues(alpha: .07) : colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: selected
              ? colors.primary
              : dark
              ? const Color(0xFF303B35)
              : const Color(0xFFE3E9E5),
        ),
      ),
      child: InkWell(
        key: ValueKey('admin-theme-${mode.name}'),
        borderRadius: BorderRadius.circular(10),
        onTap: () => _setMode(mode),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? colors.primary : colors.onSurfaceVariant,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
              if (selected) ...[
                const SizedBox(width: 6),
                Icon(Icons.check_rounded, size: 18, color: colors.primary),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _fact(String label, String? value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      const SizedBox(height: 6),
      SelectableText(
        value == null || value.isEmpty ? 'Chưa cập nhật' : value,
        style: const TextStyle(
          fontSize: 14,
          height: 1.5,
          fontWeight: FontWeight.w500,
        ),
      ),
    ],
  );

  Widget _account() {
    final session = ref.watch(sessionProvider);
    final role = _profile?.role ?? session?.role;
    return _card(
      Icons.account_circle_outlined,
      'Tài khoản quản trị',
      [
        if (_loading) ...[
          const LinearProgressIndicator(),
          const SizedBox(height: 18),
        ],
        if (_error != null) ...[
          Text(
            _error!,
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: _loading ? null : _load,
              child: const Text('Thử tải lại'),
            ),
          ),
        ],
        LayoutBuilder(
          builder: (context, box) {
            final width = box.maxWidth >= 520
                ? (box.maxWidth - 24) / 2
                : box.maxWidth;
            return Wrap(
              spacing: 24,
              runSpacing: 18,
              children: [
                SizedBox(
                  width: width,
                  child: _fact(
                    'Họ và tên',
                    _profile?.fullName ?? session?.name,
                  ),
                ),
                SizedBox(
                  width: width,
                  child: _fact(
                    'Email đăng nhập',
                    _profile?.email ?? session?.email,
                  ),
                ),
                SizedBox(
                  width: width,
                  child: _fact('Số điện thoại', _profile?.phoneNumber),
                ),
                SizedBox(
                  width: width,
                  child: _fact(
                    'Vai trò',
                    role == 'ADMIN'
                        ? 'Quản trị viên'
                        : role == 'MEMBER'
                        ? 'Thành viên'
                        : role,
                  ),
                ),
              ],
            );
          },
        ),
      ],
      action: IconButton(
        tooltip: 'Tải lại tài khoản',
        onPressed: _loading ? null : _load,
        icon: const Icon(Icons.refresh_rounded, size: 18),
      ),
    );
  }

  Widget _security() => _card(Icons.lock_outline_rounded, 'Bảo mật', [
    Wrap(
      spacing: 12,
      runSpacing: 10,
      children: [
        OutlinedButton.icon(
          onPressed: _leaving ? null : _changePassword,
          icon: const Icon(Icons.lock_reset_rounded, size: 18),
          label: const Text('Đổi mật khẩu'),
        ),
        TextButton.icon(
          onPressed: _leaving ? null : () => _signOut(),
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
          ),
          icon: const Icon(Icons.logout_rounded, size: 18),
          label: Text(_leaving ? 'Đang đăng xuất…' : 'Đăng xuất'),
        ),
      ],
    ),
    const SizedBox(height: 12),
    Text(
      'Bạn sẽ cần đăng nhập lại sau khi đổi mật khẩu.',
      style: TextStyle(
        fontSize: 12,
        height: 1.5,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    ),
  ]);

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeProvider);
    return ColoredBox(
      color: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF141A1D)
          : const Color(0xFFF7F9F8),
      child: AppContent(
        maxWidth: 940,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Cài đặt',
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'Quản lý tài khoản và tùy chỉnh giao diện.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 22),
              _account(),
              _appearance(theme),
              _security(),
            ],
          ),
        ),
      ),
    );
  }
}
