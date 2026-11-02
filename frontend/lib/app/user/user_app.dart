import '../../features/payment/data/repositories/payment_repository.dart';
import '../../features/payment/data/payment_link.dart';
import '../../features/payment/presentation/pages/payment_status_page.dart';
import '../../features/home/presentation/pages/main_page.dart';

import 'package:frontend/core/theme/app_colors.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../core/network/api_client.dart';
import '../../core/layout/app_layout.dart';
import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/repositories/auth_repository.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/pages/login_page.dart';

class MyApp extends StatelessWidget {
  final bool hasToken;
  const MyApp({super.key, this.hasToken = false, this.paymentRepository});
  final PaymentRepository? paymentRepository;

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
        scrollBehavior: const AppScrollBehavior(),
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary)
              .copyWith(
                primary: AppColors.primary,
                onPrimary: Colors.white,
                secondary: AppColors.primaryDark,
                secondaryContainer: AppColors.primaryLight,
                onSecondaryContainer: AppColors.primaryDark,
              ),
          inputDecorationTheme: const InputDecorationTheme(
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
        ),
        onGenerateRoute: _paymentRoute,
        onUnknownRoute: (settings) =>
            MaterialPageRoute(builder: (_) => const LoginPage()),
        onGenerateInitialRoutes: (route) {
          final payment = _paymentRoute(RouteSettings(name: route));
          final routes = <Route<dynamic>>[
            MaterialPageRoute(
              builder: (_) => const LoginPage(),
              settings: const RouteSettings(name: '/'),
            ),
          ];
          if (payment != null) routes.add(payment);
          return routes;
        },
      ),
    );
  }

  Route<dynamic>? _paymentRoute(RouteSettings settings) {
    final reference = paymentReferenceFromLink(settings.name ?? '');
    if (reference == null) return null;
    return MaterialPageRoute(
      settings: settings,
      builder: (context) => PaymentStatusPage(
        reference: reference,
        repository: paymentRepository,
        onDone: (authenticated) {
          if (authenticated) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const MainPage()),
              (_) => false,
            );
          } else {
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        },
      ),
    );
  }
}
