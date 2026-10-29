import '../../../features/incident/presentation/incidents_page.dart';

import 'package:flutter/widgets.dart';

import '../../../features/admin/presentation/pages/admin_users_page.dart';
import '../../../features/admin/presentation/pages/admin_areas_page.dart';
import '../../../features/admin/presentation/pages/admin_content_page.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../features/admin/presentation/screens/auth/auth_screens.dart';
import '../../../features/admin/presentation/screens/dashboard/dashboard_screen.dart';
import '../../../features/admin/presentation/screens/system/error_screen.dart';
import '../../../features/admin/presentation/screens/system/profile_screen.dart';
import '../../../features/admin/presentation/screens/system/settings_screen.dart';
import '../../../shared/admin/layout/app_shell.dart';
import '../../../features/admin/presentation/pages/admin_dashboard_page.dart';
import '../../../features/admin/presentation/pages/admin_contracts_page.dart';
import '../../../features/admin/presentation/pages/admin_packages_page.dart';
import '../auth/session.dart';
import 'routes.dart';

/// Bridges Riverpod state into go_router's `refreshListenable`, so signing in
/// or out re-evaluates the guard immediately rather than on the next
/// navigation.
class _SessionRefresh extends ChangeNotifier {
  _SessionRefresh(Ref ref) {
    ref.listen(sessionProvider, (_, _) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final contentKey = GlobalKey<AdminContentPageState>();
  final refresh = _SessionRefresh(ref);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: R.dashboard,
    refreshListenable: refresh,
    redirect: (context, state) {
      final signedIn = ref.read(sessionProvider) != null;
      final onAuth = R.isAuthRoute(state.matchedLocation);
      if (!signedIn && !onAuth) return R.signIn;
      if (signedIn && onAuth) return R.dashboard;
      return null;
    },
    errorBuilder: (context, state) => NotFoundScreen(location: state.uri.path),
    routes: [
      GoRoute(path: R.signIn, builder: (_, _) => const SignInScreen()),
      GoRoute(path: R.signUp, builder: (_, _) => const SignUpScreen()),
      GoRoute(path: R.forgot, builder: (_, _) => const ForgotPasswordScreen()),
      GoRoute(path: R.otp, builder: (_, _) => const OtpScreen()),
      GoRoute(path: R.lock, builder: (_, _) => const LockScreen()),

      // Everything below renders inside the persistent shell: the sidebar and
      // top bar survive navigation instead of rebuilding on every route.
      ShellRoute(
        builder: (context, state, child) =>
            AppShell(location: state.matchedLocation, child: child),
        routes: [
          GoRoute(
            path: R.dashboard,
            builder: (_, _) => const DashboardScreen(),
          ),
          GoRoute(
            path: R.listings,
            builder: (_, _) => const AdminDashboardPage(),
          ),
          GoRoute(
            path: R.incidents,
            builder: (_, _) => const IncidentsPage(admin: true),
          ),
          GoRoute(path: R.users, builder: (_, _) => const AdminUsersPage()),
          GoRoute(path: R.areas, builder: (_, _) => const AdminAreasPage()),
          GoRoute(
            path: R.content,
            builder: (_, _) => AdminContentPage(key: contentKey),
            onExit: (context, state) async {
              if (ref.read(sessionProvider) == null) return true;
              return await contentKey.currentState?.confirmLeave() ?? true;
            },
          ),
          GoRoute(
            path: R.contracts,
            builder: (_, _) => const AdminContractsPage(),
          ),
          GoRoute(
            path: R.memberships,
            builder: (_, _) => const AdminPackagesPage(),
          ),
          GoRoute(path: R.settings, builder: (_, _) => const SettingsScreen()),
          GoRoute(path: R.profile, builder: (_, _) => const ProfileScreen()),
          GoRoute(
            path: R.serverError,
            builder: (_, _) => const ServerErrorScreen(),
          ),
        ],
      ),
    ],
  );
});
