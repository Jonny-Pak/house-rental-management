import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../notification/presentation/notification_store.dart';
import '../../../user/data/models/user_profile.dart';

class UserNavigationDrawer extends StatelessWidget {
  const UserNavigationDrawer({
    super.key,
    required this.selectedAction,
    required this.onAction,
    required this.onClose,
    this.profile,
  });

  final String selectedAction;
  final ValueChanged<String> onAction;
  final VoidCallback onClose;
  final UserProfile? profile;

  Widget _avatar() {
    final url = profile?.avatarUrl;
    const fallback = ColoredBox(
      color: AppColors.primaryLight,
      child: Icon(Symbols.person, color: AppColors.primary, size: 30),
    );
    return ClipOval(
      child: SizedBox(
        width: 48,
        height: 48,
        child: url == null || url.isEmpty
            ? fallback
            : Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, error, trace) => fallback,
              ),
      ),
    );
  }

  Widget _contact(IconData icon, String value) => Padding(
    padding: const EdgeInsets.only(top: 3),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 12, color: AppColors.muted),
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 11, color: AppColors.muted),
          ),
        ),
      ],
    ),
  );

  Widget _header() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 6, 18),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: InkWell(
            key: const ValueKey('drawer-profile-header'),
            borderRadius: BorderRadius.circular(12),
            onTap: () => onAction('profile'),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _avatar(),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile?.fullName ?? 'Tài khoản của bạn',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text,
                        ),
                      ),
                      if (profile?.phoneNumber?.isNotEmpty == true)
                        _contact(Symbols.call, profile!.phoneNumber!),
                      if (profile != null)
                        _contact(Symbols.mail, profile!.email),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        IconButton(
          tooltip: 'Đóng menu',
          onPressed: onClose,
          icon: const Icon(Symbols.close, size: 20),
          color: AppColors.muted,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        ),
      ],
    ),
  );

  Widget _item(String action, String label, IconData symbol) {
    final selected = selectedAction == action;
    Widget icon = Icon(symbol, size: 24, weight: 400, color: AppColors.primary);
    if (action == 'notifications') icon = NotificationBadge(child: icon);
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: ListTile(
        key: ValueKey('drawer-$action'),
        selected: selected,
        selectedTileColor: const Color(0xFFE0F3E8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        horizontalTitleGap: 14,
        minTileHeight: 46,
        dense: true,
        leading: icon,
        title: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: AppColors.text,
          ),
        ),
        onTap: () => onAction(action),
      ),
    );
  }

  Widget _membership() {
    final active = profile?.subscriptionStatus == 'ACTIVE';
    final name = active ? profile?.membershipPackageName : null;
    final quota = profile?.remainingStandardQuota;
    return Material(
      color: const Color(0xFFE0F3E8),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        key: const ValueKey('drawer-membership-card'),
        borderRadius: BorderRadius.circular(14),
        onTap: () => onAction('membership'),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const Icon(
                Symbols.workspace_premium,
                color: Color(0xFFD6A52D),
                size: 32,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name ?? 'Gói dịch vụ',
                      key: const ValueKey('drawer-package-name'),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      active && quota != null
                          ? 'Còn $quota lượt đăng thường'
                          : 'Khám phá quyền lợi dành cho bạn',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Symbols.chevron_right,
                color: AppColors.primary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Drawer(
    width: math.min(344, MediaQuery.sizeOf(context).width * .88),
    backgroundColor: const Color(0xFFFCFEFD),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.horizontal(right: Radius.circular(24)),
    ),
    child: SafeArea(
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              children: [
                _header(),
                _item('home', 'Trang chủ', Symbols.home),
                _item('search', 'Tìm kiếm', Symbols.search),
                _item('rent-house', 'Thuê nhà', Symbols.home_work),
                _item('rent-room', 'Thuê phòng trọ', Symbols.bed),
                _item('roommate', 'Tìm ở ghép', Symbols.group),
                _item('post', 'Đăng tin', Symbols.add_circle),
                _item('listings', 'Quản lý tin đăng', Symbols.assignment),
                _item('contracts', 'Quản lý hợp đồng', Symbols.receipt_long),
                _item('membership', 'Gói dịch vụ', Symbols.workspace_premium),
                _item('map', 'Bản đồ', Symbols.location_on),
                _item('favorites', 'Yêu thích', Symbols.favorite),
                _item('notifications', 'Thông báo', Symbols.notifications),
                _item('profile', 'Tài khoản', Symbols.person),
                _item('help', 'Trợ giúp', Symbols.help),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _membership(),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => onAction('logout'),
                  icon: const Icon(Symbols.logout, size: 20),
                  label: const Text(
                    'Đăng xuất',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFD84D50),
                    side: const BorderSide(color: Color(0xFFE99A9C)),
                    minimumSize: const Size.fromHeight(44),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
