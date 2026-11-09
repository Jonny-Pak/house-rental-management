import '../../../../auth/data/qr_login_repository.dart';
import '../../../../auth/presentation/widgets/qr_login_panel.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kite_ui/kite_ui.dart';

import '../../../../../app/admin/auth/session.dart';
import '../../../../../app/admin/router/routes.dart';
import 'auth_scaffold.dart';
import 'sign_in_layout.dart';
import '../../../../auth/presentation/pages/password_page.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key, this.qrRepository});
  final QrLoginRepository? qrRepository;
  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _showQr = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    final email = _email.text.trim();
    final password = _password.text;
    if (!email.contains('@')) {
      setState(() => _error = 'Vui lòng nhập địa chỉ email hợp lệ.');
      return;
    }
    if (password.isEmpty) {
      setState(() => _error = 'Vui lòng nhập mật khẩu.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(sessionProvider.notifier)
          .signIn(email: email, password: password);
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SignInLayout(
      title: _showQr ? 'Đăng nhập bằng QR' : 'Đăng nhập quản trị',
      subtitle: 'Đăng nhập vào bảng điều khiển quản trị.',
      fields: _showQr
          ? [
              QrLoginPanel(
                repository: widget.qrRepository,
                onAuthenticated: (auth) =>
                    ref.read(sessionProvider.notifier).signInWithQr(auth),
                onCancel: () => setState(() => _showQr = false),
              ),
            ]
          : [
              AuthField(
                label: 'Địa chỉ email',
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                error: _error,
              ),
              AuthField(
                label: 'Mật khẩu',
                controller: _password,
                obscure: true,
                onSubmitted: (_) => _submit(),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _busy ? null : _submit,
                child: Text(
                  _busy ? 'Đang đăng nhập…' : 'Đăng nhập',
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _busy
                    ? null
                    : () => setState(() {
                        _showQr = true;
                        _error = null;
                      }),
                icon: const Icon(Icons.qr_code_2),
                label: const Text('Đăng nhập bằng QR'),
              ),
              const SizedBox(height: KiteSpace.md),
              TextButton(
                onPressed: () => context.go(R.forgot),
                child: const Text(
                  'Quên mật khẩu?',
                  textAlign: TextAlign.center,
                ),
              ),
            ],
    );
  }
}

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});
  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AuthScaffold(
    title: 'Create account',
    subtitle: 'Fourteen days, no card required.',
    fields: [
      AuthField(label: 'Full name', controller: _name, hint: 'Ada Lovelace'),
      AuthField(
        label: 'Email',
        controller: _email,
        hint: 'you@company.com',
        keyboardType: TextInputType.emailAddress,
      ),
      AuthField(label: 'Password', controller: _password, obscure: true),
      KiteButton(
        expands: true,
        onPressed: () => context.go(R.otp),
        child: const Text('Create account'),
      ),
    ],
    footer: GestureDetector(
      onTap: () => context.go(R.signIn),
      child: const Text('Already have an account? Sign in'),
    ),
  );
}

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      PasswordPage(onComplete: () => context.go(R.signIn));
}

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});
  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _controllers = List.generate(6, (_) => TextEditingController());
  final _nodes = List.generate(6, (_) => FocusNode());

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = KiteColors.of(context);
    final t = KiteText.of(context);
    return AuthScaffold(
      title: 'Verify your email',
      subtitle: 'Enter the six-digit code we just sent.',
      fields: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (var i = 0; i < 6; i++)
              SizedBox(
                width: 46,
                child: TextField(
                  controller: _controllers[i],
                  focusNode: _nodes[i],
                  textAlign: TextAlign.center,
                  maxLength: 1,
                  keyboardType: TextInputType.number,
                  style: t.h4,
                  onChanged: (v) {
                    if (v.isNotEmpty && i < 5) _nodes[i + 1].requestFocus();
                    if (v.isEmpty && i > 0) _nodes[i - 1].requestFocus();
                  },
                  decoration: InputDecoration(
                    counterText: '',
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    filled: true,
                    fillColor: c.background,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: KiteRadius.allSm,
                      borderSide: BorderSide(color: c.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: KiteRadius.allSm,
                      borderSide: BorderSide(color: c.ring, width: 1.5),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: KiteSpace.xl),
        KiteButton(
          expands: true,
          onPressed: () => context.go(R.signIn),
          child: const Text('Verify'),
        ),
      ],
      footer: const Text("Didn't get it? Resend in 0:30"),
    );
  }
}

class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});
  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  final _password = TextEditingController();

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = KiteColors.of(context);
    final t = KiteText.of(context);
    return AuthScaffold(
      title: 'Screen locked',
      subtitle: 'Enter your password to pick up where you left off.',
      fields: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: c.muted, shape: BoxShape.circle),
              child: Text('AL', style: t.small),
            ),
            const SizedBox(width: KiteSpace.md),
            Text('Ada Lovelace', style: t.p),
          ],
        ),
        const SizedBox(height: KiteSpace.xl),
        AuthField(label: 'Password', controller: _password, obscure: true),
        KiteButton(
          expands: true,
          onPressed: () => ref
              .read(sessionProvider.notifier)
              .signIn(email: 'ada@kite.dev', password: _password.text),
          child: const Text('Unlock'),
        ),
      ],
      footer: GestureDetector(
        onTap: () => context.go(R.signIn),
        child: const Text('Sign in as someone else'),
      ),
    );
  }
}
