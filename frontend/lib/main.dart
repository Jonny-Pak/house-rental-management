import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/network/api_client.dart';
import 'core/storage/token_storage.dart';
import 'features/auth/data/datasources/auth_remote_data_source.dart';
import 'features/auth/data/repositories/auth_repository.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/admin/data/repositories/admin_listing_repository.dart';
import 'features/admin/presentation/bloc/admin_listing_cubit.dart';
import 'features/admin/presentation/pages/admin_dashboard_page.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    HttpOverrides.global = MyHttpOverrides();
  }
  // Kiểm tra token đã lưu trong bộ nhớ
  final token = await TokenStorage.getToken();
  runApp(MyApp(hasToken: token != null && token.isNotEmpty));
}

class MyApp extends StatelessWidget {
  final bool hasToken;
  const MyApp({super.key, this.hasToken = false});

  @override
  Widget build(BuildContext context) {
    // Khởi tạo ApiClient dùng chung
    final apiClient = ApiClient();

    // Điều hướng trang khởi đầu:
    // - Trên Web: nếu đã đăng nhập thì vào thẳng AdminDashboardPage, nếu chưa thì vào LoginPage
    // - Trên Mobile/Android: vào LoginPage
    final Widget initialHome = (kIsWeb && hasToken)
        ? const AdminDashboardPage()
        : const LoginPage();

    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (_) => AuthBloc(
            AuthRepositoryImpl(AuthRemoteDataSourceImpl(apiClient)),
          ),
        ),
        BlocProvider<AdminListingCubit>(
          create: (_) => AdminListingCubit(
            AdminListingRepository(apiClient),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'House Rental Management',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: Colors.indigo,
          inputDecorationTheme: const InputDecorationTheme(
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
        ),
        home: initialHome,
      ),
    );
  }
}
