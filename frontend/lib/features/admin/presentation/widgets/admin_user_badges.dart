import 'package:flutter/material.dart';

import '../../data/models/admin_user.dart';

class AdminUserAvatar extends StatelessWidget {
  const AdminUserAvatar({super.key, required this.user, this.size = 42});
  final AdminUser user;
  final double size;

  String get initials {
    final name = user.fullName.trim();
    if (name.isEmpty) return '?';
    final words = name.split(RegExp(r'\s+'));
    final first = words.first.characters.first;
    final last = words.length > 1 ? words.last.characters.first : '';
    return '$first$last'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final color = user.isAdmin
        ? const Color(0xFF7C5CC4)
        : const Color(0xFFD36B2C);
    final placeholder = ColoredBox(
      color: color.withValues(alpha: .12),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: size * .32,
          ),
        ),
      ),
    );
    return SizedBox.square(
      dimension: size,
      child: ClipOval(
        child: user.avatarUrl == null || user.avatarUrl!.isEmpty
            ? placeholder
            : Image.network(
                user.avatarUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, error, stack) => placeholder,
              ),
      ),
    );
  }
}

class AdminUserBadge extends StatelessWidget {
  const AdminUserBadge({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.dot = false,
  });
  final String label;
  final Color color;
  final IconData? icon;
  final bool dot;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textColor = dark ? Color.lerp(color, Colors.white, .4)! : color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: dark ? .2 : .08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: textColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
          ],
          if (icon != null) ...[
            Icon(icon, size: 14, color: textColor),
            const SizedBox(width: 5),
          ],
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget adminRoleBadge(AdminUser user) => AdminUserBadge(
  label: user.roleLabel,
  color: user.isAdmin ? const Color(0xFF7956B5) : const Color(0xFFB7682C),
  icon: user.isAdmin ? Icons.shield_outlined : Icons.person_outline,
);

Widget adminStatusBadge(AdminUser user) => AdminUserBadge(
  label: user.locked ? 'Đã khóa' : 'Hoạt động',
  color: user.locked ? const Color(0xFFCC4D56) : const Color(0xFF268265),
  dot: true,
);

Widget adminVerifiedBadge(AdminUser user) => AdminUserBadge(
  label: user.verified ? 'Đã xác thực' : 'Chưa xác thực',
  color: user.verified ? const Color(0xFF268265) : const Color(0xFF9A7427),
  icon: user.verified ? Icons.verified_outlined : Icons.schedule_outlined,
);
