import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'core/network/api_client.dart';
import 'core/storage/token_storage.dart';
import 'features/auth/data/datasources/auth_remote_data_source.dart';
import 'features/auth/data/repositories/auth_repository.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/admin/app.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // ─── Trên Web: Khởi chạy toàn bộ hệ thống Admin Dashboard từ features/admin ───
  if (kIsWeb) {
    usePathUrlStrategy();
    runApp(const ProviderScope(child: KiteApp()));
    return;
  }

  // ─── Trên Android / Mobile: Khởi chạy ứng dụng người dùng ───
  HttpOverrides.global = MyHttpOverrides();
  final token = await TokenStorage.getToken();
  runApp(MyApp(hasToken: token != null && token.isNotEmpty));
}

class MyApp extends StatelessWidget {
  final bool hasToken;
  const MyApp({super.key, this.hasToken = false});

  @override
  Widget build(BuildContext context) {
    final apiClient = ApiClient();

    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (_) => AuthBloc(
            AuthRepositoryImpl(AuthRemoteDataSourceImpl(apiClient)),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'House Rental Management',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: const Color(0xFFD85D15),
          inputDecorationTheme: const InputDecorationTheme(
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
        ),
        home: const LoginPage(),
      ),
    );
  }
}
