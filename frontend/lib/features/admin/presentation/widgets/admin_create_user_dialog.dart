import 'dart:convert';

import 'package:flutter/material.dart';

import '../../data/repositories/admin_user_repository.dart';

class AdminCreateUserDialog extends StatefulWidget {
  const AdminCreateUserDialog({super.key, required this.repository});
  final AdminUserRepository repository;

  @override
  State<AdminCreateUserDialog> createState() => _AdminCreateUserDialogState();
}

class _AdminCreateUserDialogState extends State<AdminCreateUserDialog> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  String? _error;
  bool _saving = false;
  bool _hidden = true;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (_saving || !_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final user = await widget.repository.create(
        fullName: _name.text,
        email: _email.text,
        phone: _phone.text,
        password: _password.text,
        role: 'MEMBER',
      );
      if (mounted) Navigator.pop(context, user);
    } catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = adminUserError(error);
        });
      }
    }
  }

  Widget _field(
    String key,
    String label,
    TextEditingController controller, {
    int? maxLength,
    TextInputType? keyboard,
    bool password = false,
    String? Function(String?)? validator,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextFormField(
      key: ValueKey(key),
      controller: controller,
      enabled: !_saving,
      maxLength: maxLength,
      keyboardType: keyboard,
      obscureText: password && _hidden,
      autocorrect: !password,
      enableSuggestions: !password,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        counterText: '',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        suffixIcon: password && controller == _password
            ? IconButton(
                tooltip: _hidden ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
                onPressed: _saving
                    ? null
                    : () => setState(() => _hidden = !_hidden),
                icon: Icon(
                  _hidden
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
              )
            : null,
      ),
      validator:
          validator ??
          (value) => value == null || value.trim().isEmpty
              ? 'Vui lòng nhập $label.'
              : null,
    ),
  );

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        'Thêm người dùng',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
      ),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Form(
            key: _form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Tài khoản mới cần xác thực email bằng OTP trên app trước khi đăng nhập.',
                ),
                const SizedBox(height: 20),
                _field('new-user-name', 'Họ và tên', _name, maxLength: 150),
                _field(
                  'new-user-email',
                  'Email',
                  _email,
                  maxLength: 150,
                  keyboard: TextInputType.emailAddress,
                  validator: (value) =>
                      RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                          .hasMatch(value?.trim() ?? '')
                      ? null
                      : 'Email không hợp lệ.',
                ),
                _field(
                  'new-user-phone',
                  'Số điện thoại (không bắt buộc)',
                  _phone,
                  maxLength: 15,
                  keyboard: TextInputType.phone,
                  validator: (value) {
                    final phone = value?.trim() ?? '';
                    if (phone.isEmpty ||
                        RegExp(r'^[0-9+][0-9]{8,14}$').hasMatch(phone)) {
                      return null;
                    }
                    return 'Số điện thoại không hợp lệ.';
                  },
                ),
                _field(
                  'new-user-password',
                  'Mật khẩu ban đầu',
                  _password,
                  password: true,
                  maxLength: 72,
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty ||
                        value.length < 8) {
                      return 'Mật khẩu phải có ít nhất 8 ký tự.';
                    }
                    if (utf8.encode(value).length > 72) {
                      return 'Mật khẩu quá dài, vui lòng nhập ngắn hơn.';
                    }
                    return null;
                  },
                ),
                _field(
                  'new-user-confirm',
                  'Nhập lại mật khẩu',
                  _confirmation,
                  password: true,
                  maxLength: 72,
                  validator: (value) =>
                      value == null || value.isEmpty || value != _password.text
                      ? 'Mật khẩu nhập lại chưa khớp.'
                      : null,
                ),
                const Text(
                  'Vai trò: Member · Có thể thuê nhà và đăng tin cho thuê.',
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
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
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: _saving ? null : _create,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF15803D),
            foregroundColor: Colors.white,
          ),
          child: Text(_saving ? 'Đang tạo và gửi OTP...' : 'Tạo và gửi OTP'),
        ),
      ],
    ),
  );
}
