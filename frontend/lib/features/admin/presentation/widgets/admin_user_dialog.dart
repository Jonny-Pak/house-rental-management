import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/models/admin_user.dart';
import 'admin_user_badges.dart';
import '../../data/repositories/admin_user_repository.dart';

class AdminUserDialog extends StatefulWidget {
  const AdminUserDialog({
    super.key,
    required this.user,
    required this.repository,
    this.readOnly = false,
  });
  final AdminUser user;
  final AdminUserRepository repository;
  final bool readOnly;

  @override
  State<AdminUserDialog> createState() => _AdminUserDialogState();
}

class _AdminUserDialogState extends State<AdminUserDialog> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.user.fullName);
  late final _phone = TextEditingController(
    text: widget.user.phoneNumber ?? '',
  );
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate() || _saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.repository.update(
        widget.user.id,
        _name.text,
        _phone.text,
        'MEMBER',
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = adminUserError(error);
        });
      }
    }
  }

  String _date(DateTime? date) =>
      date == null ? 'Chưa có' : DateFormat('dd/MM/yyyy HH:mm').format(date);

  Widget _info(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ],
    ),
  );

  InputDecoration _field(String label) => InputDecoration(
    labelText: label,
    filled: true,
    fillColor: Theme.of(context).colorScheme.surfaceContainerLowest,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(
        color: Theme.of(context).colorScheme.outlineVariant,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final readOnly = widget.readOnly || user.isAdmin;
    return PopScope(
      canPop: !_saving,
      child: AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
        title: Row(
          children: [
            AdminUserAvatar(user: user, size: 48),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                readOnly
                    ? 'Thông tin người dùng #${user.id}'
                    : 'Chỉnh sửa người dùng',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Form(
              key: _form,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _info('Email', user.email),
                  if (readOnly) ...[
                    _info('Họ và tên', user.fullName),
                    _info('Số điện thoại', user.phoneNumber ?? 'Chưa có'),
                    _info('Vai trò', user.roleLabel),
                  ] else ...[
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _name,
                      enabled: !_saving,
                      maxLength: 150,
                      decoration: _field('Họ và tên'),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Vui lòng nhập họ và tên.'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phone,
                      enabled: !_saving,
                      maxLength: 15,
                      keyboardType: TextInputType.phone,
                      decoration: _field('Số điện thoại'),
                      validator: (value) {
                        final phone = value?.trim() ?? '';
                        if (phone.isEmpty ||
                            RegExp(r'^[0-9+][0-9]{8,14}$').hasMatch(phone)) {
                          return null;
                        }
                        return 'Số điện thoại không hợp lệ.';
                      },
                    ),
                    const SizedBox(height: 12),
                    _info('Vai trò', 'Member'),
                    const SizedBox(height: 12),
                    const Text('Email và trạng thái xác thực được giữ nguyên.'),
                  ],
                  const SizedBox(height: 12),
                  _info('Trạng thái', user.locked ? 'Đã khóa' : 'Hoạt động'),
                  _info(
                    'Xác thực email',
                    user.verified ? 'Đã xác thực' : 'Chưa xác thực',
                  ),
                  _info('Ngày tạo', _date(user.createdAt)),
                  _info('Cập nhật', _date(user.updatedAt)),
                  if (user.isAdmin)
                    const Text('Tài khoản Admin chỉ được xem tại trang này.'),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
          if (!readOnly)
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Đang lưu...' : 'Lưu thay đổi'),
            ),
        ],
      ),
    );
  }
}
