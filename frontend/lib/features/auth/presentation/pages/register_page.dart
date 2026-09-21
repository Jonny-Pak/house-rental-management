import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../../data/models/auth_models.dart';
import 'otp_page.dart';

// ─── Design System Colors ─────────────────────────────────────────────
const kPrimaryDark   = Color(0xFF2C1D11);
const kPrimaryAccent = Color(0xFFD85D15);
const kBackground    = Color(0xFFFAF8F5);
const kBorderColor   = Color(0xFFE8DED1);
const kSubText       = Color(0xFF64748B);
// ──────────────────────────────────────────────────────────────────────

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
  bool _obscurePassword = true;

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _onRegister(BuildContext context) {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
            RegisterRequested(
              RegisterRequest(
                fullName: _fullNameCtrl.text.trim(),
                email: _emailCtrl.text.trim(),
                password: _passwordCtrl.text,
                phoneNumber: _phoneCtrl.text.trim(),
                role: 'USER',
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
    bool isPassword = false,
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
          obscureText: isPassword ? _obscurePassword : false,
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
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
            suffixIcon: isPassword
                ? IconButton(
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
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
          icon: const Icon(Icons.arrow_back_ios_new, color: kPrimaryDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.redAccent,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              );
            } else if (state is AuthOtpSent) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => OtpPage(email: state.email),
                ),
              );
            }
          },
          builder: (context, state) {
            final isLoading = state is AuthLoading;
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
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
                          validator: (v) => v == null || v.isEmpty ? 'Vui lòng nhập họ tên' : null,
                        ),
                        const SizedBox(height: 20),
                        
                        _buildTextField(
                          label: 'Số điện thoại',
                          hintText: 'Nhập số điện thoại...',
                          controller: _phoneCtrl,
                          keyboardType: TextInputType.phone,
                          validator: (v) => v == null || v.isEmpty ? 'Vui lòng nhập SĐT' : null,
                        ),
                        const SizedBox(height: 20),
                        
                        _buildTextField(
                          label: 'Email',
                          hintText: 'Nhập địa chỉ email...',
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) => v == null || v.isEmpty || !v.contains('@') ? 'Email không hợp lệ' : null,
                        ),
                        const SizedBox(height: 20),
                        
                        _buildTextField(
                          label: 'Mật khẩu',
                          hintText: 'Tạo mật khẩu...',
                          controller: _passwordCtrl,
                          isPassword: true,
                          validator: (v) => v == null || v.length < 8 ? 'Mật khẩu ít nhất 8 ký tự' : null,
                        ),
                        const SizedBox(height: 32),

                        // Register Button
                        ElevatedButton(
                          onPressed: isLoading ? null : () => _onRegister(context),
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
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
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

                        // Divider
                        Row(
                          children: [
                            Expanded(child: Divider(color: kBorderColor, thickness: 1)),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'Hoặc',
                                style: TextStyle(
                                  color: kSubText,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            Expanded(child: Divider(color: kBorderColor, thickness: 1)),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // Google Sign In
                        OutlinedButton.icon(
                          onPressed: () {
                            // TODO: Implement Google Sign-In
                          },
                          icon: Image.network(
                            'https://img.icons8.com/color/48/000000/google-logo.png',
                            height: 24,
                          ),
                          label: const Text(
                            'Đăng ký với Google',
                            style: TextStyle(
                              color: kPrimaryDark,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: const BorderSide(color: kBorderColor),
                            elevation: 0,
                          ),
                        ),
                        const SizedBox(height: 32),
                        
                        // Login Link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Đã có tài khoản? ',
                              style: TextStyle(
                                color: kSubText,
                                fontSize: 15,
                              ),
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

