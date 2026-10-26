import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/layout/app_layout.dart';
import '../../../../core/network/api_client.dart';
import '../../data/repositories/password_repository.dart';

class PasswordPage extends StatefulWidget {
  const PasswordPage({
    super.key,
    this.changePassword = false,
    this.initialEmail = '',
    this.repository,
    this.onComplete,
  });
  final bool changePassword;
  final String initialEmail;
  final PasswordRepository? repository;
  final VoidCallback? onComplete;
  @override
  State<PasswordPage> createState() => _PasswordPageState();
}

class _PasswordPageState extends State<PasswordPage> {
  late final _repository = widget.repository ?? PasswordRepository(ApiClient());
  final _form = GlobalKey<FormState>();
  late final _email = TextEditingController(text: widget.initialEmail);
  final _otp = TextEditingController();
  final _current = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false, _sent = false, _done = false;
  bool _hideCurrent = true, _hidePassword = true, _hideConfirm = true;
  String? _error, _message;
  int _seconds = 0;
  Timer? _timer;
  static const _accent = Color(0xFFD76B28);

  @override
  void dispose() {
    _timer?.cancel();
    _email.dispose();
    _otp.dispose();
    _current.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _cooldown() {
    _timer?.cancel();
    _seconds = 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _seconds--);
      if (_seconds <= 0) timer.cancel();
    });
  }

  Future<void> _send() async {
    if (_busy || _seconds > 0) return;
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(_email.text.trim())) {
      setState(() => _error = 'Vui lòng nhập email hợp lệ.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _message = null;
    });
    try {
      final message = await _repository.requestReset(_email.text);
      if (!mounted) return;
      setState(() {
        _sent = true;
        _message = message;
        _otp.clear();
        _cooldown();
      });
    } catch (error) {
      if (mounted) setState(() => _error = passwordError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submit() async {
    if (_busy || !_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
      _message = null;
    });
    try {
      if (widget.changePassword) {
        await _repository.change(_current.text, _password.text);
      } else {
        await _repository.reset(_email.text, _otp.text, _password.text);
      }
      if (!mounted) return;
      _timer?.cancel();
      _current.clear();
      _password.clear();
      _confirm.clear();
      _otp.clear();
      setState(() {
        _done = true;
        _busy = false;
      });
      if (widget.changePassword) {
        await WidgetsBinding.instance.endOfFrame;
        if (mounted) _complete();
      }
    } catch (error) {
      if (mounted) setState(() => _error = passwordError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _complete() {
    if (widget.onComplete != null) {
      widget.onComplete!();
    } else {
      Navigator.of(context).pop(true);
    }
  }

  InputDecoration _decoration(String label) => InputDecoration(
    labelText: label,
    filled: true,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    contentPadding: const EdgeInsets.all(18),
  );

  String? _validatePassword(String? value) {
    if (value == null || value.trim().isEmpty || value.length < 8) {
      return 'Mật khẩu cần ít nhất 8 ký tự.';
    }
    if (utf8.encode(value).length > 72) return 'Mật khẩu tối đa 72 byte UTF-8.';
    if (widget.changePassword && value == _current.text) {
      return 'Mật khẩu mới phải khác mật khẩu hiện tại.';
    }
    return null;
  }

  Widget _passwordField(
    String label,
    String key,
    TextEditingController controller,
    bool hidden,
    VoidCallback toggle,
    FormFieldValidator<String> validator,
  ) => TextFormField(
    key: ValueKey(key),
    controller: controller,
    enabled: !_busy,
    obscureText: hidden,
    autocorrect: false,
    enableSuggestions: false,
    decoration: _decoration(label).copyWith(
      suffixIcon: IconButton(
        tooltip: hidden ? 'Hiện $label' : 'Ẩn $label',
        onPressed: toggle,
        icon: Icon(
          hidden ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        ),
      ),
    ),
    validator: validator,
  );

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: Scaffold(
      appBar: AppBar(
        title: Text(widget.changePassword ? 'Đổi mật khẩu' : 'Quên mật khẩu'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _busy
              ? null
              : () {
                  if (widget.onComplete != null) {
                    widget.onComplete!();
                  } else {
                    Navigator.maybePop(context);
                  }
                },
        ),
      ),
      body: AppContent(
        maxWidth: AppLayout.formWidth,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  _done ? Icons.check_circle_outline : Icons.lock_reset,
                  size: 52,
                  color: _accent,
                ),
                const SizedBox(height: 20),
                if (_done) ...[
                  const Text(
                    'Mật khẩu đã được cập nhật. Vui lòng đăng nhập bằng mật khẩu mới.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _complete,
                    child: const Text('Quay lại đăng nhập'),
                  ),
                ] else ...[
                  Text(
                    widget.changePassword
                        ? 'Nhập mật khẩu hiện tại và mật khẩu mới. Sau khi đổi, bạn sẽ cần đăng nhập lại.'
                        : 'Nhận mã OTP qua email để đặt lại mật khẩu. Mã có hiệu lực 5 phút, được nhập sai tối đa 5 lần.',
                    style: const TextStyle(height: 1.6),
                  ),
                  const SizedBox(height: 22),
                  if (_message != null) ...[
                    Text(
                      _message!,
                      style: const TextStyle(
                        color: Color(0xFF298774),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],
                  if (_error != null) ...[
                    Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],
                  if (!widget.changePassword) ...[
                    TextFormField(
                      key: const ValueKey('password-email'),
                      controller: _email,
                      enabled: !_busy && !_sent,
                      keyboardType: TextInputType.emailAddress,
                      decoration: _decoration('Email đăng ký'),
                    ),
                    const SizedBox(height: 16),
                    if (_sent) ...[
                      TextFormField(
                        key: const ValueKey('password-otp'),
                        controller: _otp,
                        enabled: !_busy,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: _decoration('Mã OTP 6 chữ số'),
                        validator: (value) =>
                            value == null ||
                                !RegExp(r'^[0-9]{6}$').hasMatch(value)
                            ? 'Nhập đủ 6 chữ số OTP.'
                            : null,
                      ),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          TextButton(
                            onPressed: _busy || _seconds > 0 ? null : _send,
                            child: Text(
                              _seconds > 0
                                  ? 'Gửi lại sau $_seconds giây'
                                  : 'Gửi lại mã',
                            ),
                          ),
                          TextButton(
                            onPressed: _busy
                                ? null
                                : () => setState(() {
                                    _sent = false;
                                    _seconds = 0;
                                    _message = null;
                                    _error = null;
                                    _timer?.cancel();
                                    _otp.clear();
                                  }),
                            child: const Text('Đổi email'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ],
                  if (widget.changePassword) ...[
                    _passwordField(
                      'Mật khẩu hiện tại',
                      'password-current',
                      _current,
                      _hideCurrent,
                      () => setState(() => _hideCurrent = !_hideCurrent),
                      (value) => value == null || value.isEmpty
                          ? 'Nhập mật khẩu hiện tại.'
                          : null,
                    ),
                    const SizedBox(height: 18),
                  ],
                  if (_sent || widget.changePassword) ...[
                    _passwordField(
                      'Mật khẩu mới',
                      'password-new',
                      _password,
                      _hidePassword,
                      () => setState(() => _hidePassword = !_hidePassword),
                      _validatePassword,
                    ),
                    const SizedBox(height: 18),
                    _passwordField(
                      'Nhập lại mật khẩu mới',
                      'password-confirm',
                      _confirm,
                      _hideConfirm,
                      () => setState(() => _hideConfirm = !_hideConfirm),
                      (value) =>
                          value == null ||
                              value.isEmpty ||
                              value != _password.text
                          ? 'Mật khẩu nhập lại chưa khớp.'
                          : null,
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _busy ? null : _submit,
                      child: Text(
                        widget.changePassword
                            ? 'Đổi mật khẩu'
                            : 'Đặt lại mật khẩu',
                      ),
                    ),
                  ] else
                    FilledButton(
                      onPressed: _busy ? null : _send,
                      child: const Text('Gửi mã OTP'),
                    ),
                  if (_busy)
                    const Padding(
                      padding: EdgeInsets.only(top: 18),
                      child: LinearProgressIndicator(),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
