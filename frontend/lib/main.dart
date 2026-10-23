import 'package:flutter/widgets.dart';

import 'app/app_launcher.dart';

export 'app/user/user_app.dart' show MyApp;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  configureApp();
  runApp(const AppLauncher());
}
