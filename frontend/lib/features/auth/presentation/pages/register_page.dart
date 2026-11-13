import 'package:frontend/core/theme/app_colors.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/auth_bloc.dart';
import '../widgets/google_login_button.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../../data/models/auth_models.dart';
import 'otp_page.dart';
import '../../../home/presentation/pages/main_page.dart';

const kPrimaryDark = AppColors.text;
const kPrimaryAccent = AppColors.primary;
const kBackground = AppColors.background;
const kBorderColor = AppColors.border;
const kSubText = Color(0xFF64748B);

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  void _onRegister(BuildContext context) {
    if (context.read<AuthBloc>().state is AuthLoading) return;
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
        RegisterRequested(
          RegisterRequest(
            fullName: _fullNameCtrl.text.trim(),
            email: _emailCtrl.text.trim(),
            password: _passwordCtrl.text,
            phoneNumber: _phoneCtrl.text.trim(),
            role: 'MEMBER',
          ),
        ),
      );
    }
  }

  Widget _buildTextField({
    required String label,
    required String hintText,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction textInputAction = TextInputAction.next,
    bool obscureText = false,
    VoidCallback? onToggleObscure,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: kPrimaryDark,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          onFieldSubmitted: (_) {
            if (textInputAction == TextInputAction.done) {
              if (context.read<AuthBloc>().state is! AuthLoading) {
                _onRegister(context);
              }
            } else {
              FocusScope.of(context).nextFocus();
            }
          },
          obscureText: obscureText,
          style: const TextStyle(fontSize: 15, color: kPrimaryDark),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(
              color: kSubText,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kBorderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kBorderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kPrimaryAccent, width: 1.5),
            ),
            suffixIcon: onToggleObscure != null
                ? IconButton(
                    onPressed: onToggleObscure,
                    icon: Icon(
                      obscureText
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: kSubText,
                      size: 20,
                    ),
                  )
                : null,
          ),
          validator: validator,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: kPrimaryDark,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {
            if (ModalRoute.of(context)?.isCurrent != true) return;
            if (state is AuthError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.redAccent,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              );
            } else if (state is AuthAuthenticated) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const MainPage()),
                (_) => false,
              );
            } else if (state is AuthOtpSent) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => OtpPage(email: state.email)),
              );
            }
          },
          builder: (context, state) {
            final isLoading = state is AuthLoading;
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Tạo tài khoản',
                          style: TextStyle(
                            color: kPrimaryDark,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Đăng ký để tìm và đăng tin phòng trọ dễ dàng hơn bao giờ hết.',
                          style: TextStyle(
                            color: kSubText,
                            fontSize: 15,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 32),

                        _buildTextField(
                          label: 'Họ và tên',
                          hintText: 'Nhập họ và tên...',
                          controller: _fullNameCtrl,
                          validator: (v) {
                            final trimmed = v?.trim() ?? '';
                            if (trimmed.isEmpty) return 'Vui lòng nhập họ tên';
                            if (trimmed.length > 150) {
                              return 'Họ tên không được vượt quá 150 ký tự';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        _buildTextField(
                          label: 'Số điện thoại',
                          hintText: 'Nhập số điện thoại...',
                          controller: _phoneCtrl,
                          keyboardType: TextInputType.phone,
                          validator: (v) {
                            final trimmed = v?.trim() ?? '';
                            if (trimmed.isEmpty) return 'Vui lòng nhập SĐT';
                            if (trimmed.length < 9 ||
                                trimmed.length > 15 ||
                                !RegExp(r'^[0-9+]+$').hasMatch(trimmed)) {
                              return 'Số điện thoại không hợp lệ (9-15 chữ số)';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        _buildTextField(
                          label: 'Email',
                          hintText: 'Nhập địa chỉ email...',
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            final trimmed = v?.trim() ?? '';
                            if (trimmed.isEmpty ||
                                trimmed.length > 150 ||
                                !RegExp(
                                  r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                                ).hasMatch(trimmed)) {
                              return 'Email không hợp lệ';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        _buildTextField(
                          label: 'Mật khẩu',
                          hintText: 'Tạo mật khẩu...',
                          controller: _passwordCtrl,
                          obscureText: _obscurePassword,
                          onToggleObscure: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                          validator: (v) =>
                              v == null || v.trim().isEmpty || v.length < 8
                              ? 'Mật khẩu ít nhất 8 ký tự'
                              : null,
                        ),
                        const SizedBox(height: 20),
                        _buildTextField(
                          label: 'Xác nhận mật khẩu',
                          hintText: 'Nhập lại mật khẩu...',
                          controller: _confirmPasswordCtrl,
                          textInputAction: TextInputAction.done,
                          obscureText: _obscureConfirmPassword,
                          onToggleObscure: () {
                            setState(() {
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword;
                            });
                          },
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Vui lòng xác nhận mật khẩu';
                            }
                            if (v != _passwordCtrl.text) {
                              return 'Mật khẩu xác nhận không khớp';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 32),

                        ElevatedButton(
                          onPressed: isLoading
                              ? null
                              : () => _onRegister(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimaryAccent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Text(
                                  'Đăng ký',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                        const SizedBox(height: 32),

                        Row(
                          children: [
                            Expanded(
                              child: Divider(color: kBorderColor, thickness: 1),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'Hoặc',
                                style: TextStyle(color: kSubText, fontSize: 13),
                              ),
                            ),
                            Expanded(
                              child: Divider(color: kBorderColor, thickness: 1),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        GoogleLoginButton(loading: isLoading, register: true),
                        const SizedBox(height: 32),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Đã có tài khoản? ',
                              style: TextStyle(color: kSubText, fontSize: 15),
                            ),
                            InkWell(
                              onTap: () => Navigator.pop(context),
                              child: const Text(
                                'Đăng nhập',
                                style: TextStyle(
                                  color: kPrimaryAccent,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
