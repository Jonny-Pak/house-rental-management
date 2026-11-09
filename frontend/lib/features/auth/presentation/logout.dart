import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'bloc/auth_bloc.dart';
import 'bloc/auth_event.dart';
import 'bloc/auth_state.dart';
import 'pages/login_page.dart';

Future<void> logout(BuildContext context) async {
  try {
    final authBloc = context.read<AuthBloc>();
    final result = authBloc.stream.firstWhere(
      (state) => state is AuthUnauthenticated || state is AuthError,
    );
    authBloc.add(const LogoutRequested());
    if (await result is AuthError) throw StateError('Logout failed');
    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (_) => false,
    );
  } catch (_) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Chưa đăng xuất được. Vui lòng thử lại.')),
    );
  }
}
