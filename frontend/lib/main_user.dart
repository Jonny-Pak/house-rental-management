import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'app/user/user_app.dart';
import 'core/storage/token_storage.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (
        X509Certificate cert,
        String host,
        int port,
      ) => true;
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) HttpOverrides.global = MyHttpOverrides();
  final token = await TokenStorage.getToken();
  runApp(MyApp(hasToken: token != null && token.isNotEmpty));
}
