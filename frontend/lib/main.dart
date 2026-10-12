import 'package:flutter/foundation.dart';

import 'main_admin.dart' as admin;
import 'main_user.dart' as user;

export 'app/user/user_app.dart' show MyApp;

// Preserve the existing default: web opens Admin, other platforms open the user app.
Future<void> main() async {
  if (kIsWeb) {
    admin.main();
  } else {
    await user.main();
  }
}
