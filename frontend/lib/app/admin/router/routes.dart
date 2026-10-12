import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// Route paths in one place so the router, the sidebar and every `context.go`
/// call agree. Typed constants rather than string literals scattered around.
abstract final class R {
  static const signIn = '/sign-in';
  static const signUp = '/sign-up';
  static const forgot = '/forgot-password';
  static const otp = '/verify';
  static const lock = '/lock';

  static const dashboard = '/';
  static const listings = '/listings';
  static const contracts = '/contracts';
  static const memberships = '/memberships';
  static const settings = '/settings';
  static const profile = '/profile';
  static const serverError = '/500';

  static bool isAuthRoute(String location) =>
      location.startsWith(signIn) ||
      location.startsWith(signUp) ||
      location.startsWith(forgot) ||
      location.startsWith(otp) ||
      location.startsWith(lock);
}

@immutable
class NavItem {
  const NavItem(this.label, this.path, this.icon, {this.inSidebar = true});

  final String label;
  final String path;
  final IconData icon;
  final bool inSidebar;

  String labelOf(L l) => switch (path) {
    R.dashboard => 'Dashboard',
    R.listings => 'Duyệt bài đăng',
    R.contracts => 'Hợp đồng thuê',
    R.memberships => 'Gói thành viên',
    R.settings => 'Cài đặt',
    R.profile => l.navProfile,
    _ => label,
  };
}

@immutable
class NavGroup {
  const NavGroup(this.label, this.items);
  final String label;
  final List<NavItem> items;

  String labelOf(L l) => switch (label) {
    'Overview' => 'TỔNG QUAN',
    'Manage' => 'QUẢN LÝ',
    'System' => 'HỆ THỐNG',
    _ => label,
  };
}

const kNavGroups = <NavGroup>[
  NavGroup('Overview', [
    NavItem('Dashboard', R.dashboard, Icons.dashboard_outlined),
  ]),
  NavGroup('Manage', [
    NavItem('Duyệt bài đăng', R.listings, Icons.approval_outlined),
    NavItem('Hợp đồng thuê', R.contracts, Icons.description_outlined),
    NavItem('Gói thành viên', R.memberships, Icons.card_membership_outlined),
  ]),
  NavGroup('System', [
    NavItem('Cài đặt', R.settings, Icons.settings_outlined),
    NavItem('Profile', R.profile, Icons.person_outline, inSidebar: false),
  ]),
];

/// Flattened, for the mobile bottom bar and for resolving the page title.
final kNav = [for (final g in kNavGroups) ...g.items];
