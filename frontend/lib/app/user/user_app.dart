import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../core/network/api_client.dart';
import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/repositories/auth_repository.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/pages/login_page.dart';

class MyApp extends StatelessWidget {
  final bool hasToken;
  const MyApp({super.key, this.hasToken = false});

  @override
  Widget build(BuildContext context) {
    final apiClient = ApiClient();
    if (!GetIt.I.isRegistered<ApiClient>()) {
      GetIt.I.registerSingleton<ApiClient>(apiClient);
    }

    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (_) =>
              AuthBloc(AuthRepositoryImpl(AuthRemoteDataSourceImpl(apiClient))),
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
