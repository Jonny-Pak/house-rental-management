import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/network/api_client.dart';
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

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = MyHttpOverrides();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Khởi tạo ApiClient dùng chung
    final apiClient = ApiClient();

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
        home: const LoginPage(),
        // home: const AdminDashboardPage(),
      ),
    );
  }
}
