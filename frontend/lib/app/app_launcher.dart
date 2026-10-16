import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/layout/app_layout.dart';
import 'admin/admin_app.dart';
import 'app_mode_scope.dart';
import 'user/user_app.dart';

class AppLauncher extends StatefulWidget {
  const AppLauncher({super.key});
  @override
  State<AppLauncher> createState() => _AppLauncherState();
}

class _AppLauncherState extends State<AppLauncher> {
  String? _mode;

  @override
  Widget build(BuildContext context) => AppModeScope(
    onSwitch: () => setState(() => _mode = null),
    child: _mode == 'admin'
        ? const ProviderScope(child: KiteApp())
        : _mode == 'user'
        ? const MyApp()
        : MaterialApp(
            debugShowCheckedModeBanner: false,
            scrollBehavior: const AppScrollBehavior(),
            theme: ThemeData(
              useMaterial3: true,
              colorSchemeSeed: const Color(0xFFD85D15),
            ),
            home: Scaffold(
              body: SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: AppContent(
                      maxWidth: 900,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.home_work_rounded,
                            size: 64,
                            color: Color(0xFFD85D15),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Quản lý nhà cho thuê',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Chọn giao diện để tiếp tục',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 32),
                          ResponsiveCards(
                            minCardWidth: 300,
                            children: [
                              _modeCard(
                                'Người dùng',
                                'Tìm nhà, đăng tin và quản lý hợp đồng thuê.',
                                Icons.person_outline,
                                'user',
                              ),
                              _modeCard(
                                'Quản trị viên',
                                'Duyệt tin và quản lý hệ thống.',
                                Icons.admin_panel_settings_outlined,
                                'admin',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
  );

  Widget _modeCard(
    String title,
    String description,
    IconData icon,
    String mode,
  ) => Card(
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: () => setState(() => _mode = mode),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 36, color: const Color(0xFFD85D15)),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(description),
            const SizedBox(height: 20),
            const Icon(Icons.arrow_forward),
          ],
        ),
      ),
    ),
  );
}
