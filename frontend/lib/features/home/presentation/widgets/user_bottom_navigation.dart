import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../notification/presentation/notification_store.dart';

class UserBottomNavigation extends StatelessWidget {
  const UserBottomNavigation({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  Widget _item(int index, String label, IconData symbol) {
    final selected = selectedIndex == index;
    Widget icon = Icon(
      symbol,
      size: 23,
      weight: selected ? 450 : 300,
      fill: selected ? 1 : 0,
      color: selected ? Colors.white : const Color(0xFF7D8982),
    );
    if (index == 3) icon = NotificationBadge(child: icon);
    return Expanded(
      child: Semantics(
        label: label,
        button: true,
        selected: selected,
        child: Tooltip(
          message: label,
          excludeFromSemantics: true,
          child: InkWell(
            key: ValueKey('bottom-nav-$index'),
            borderRadius: BorderRadius.circular(30),
            onTap: () => onSelected(index),
            child: Center(
              child: AnimatedContainer(
                key: ValueKey('bottom-bubble-$index'),
                duration: const Duration(milliseconds: 200),
                width: 42,
                height: 48,
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (selected) ...[
                      Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                    icon,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    minimum: const EdgeInsets.fromLTRB(16, 6, 16, 8),
    child: Center(
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(40),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D203E2D),
                blurRadius: 20,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: const Color(0xFFF0F2F1),
            borderRadius: BorderRadius.circular(34),
            child: SizedBox(
              height: 52,
              child: Row(
                children: [
                  _item(0, 'Trang chủ', Symbols.home),
                  _item(1, 'Yêu thích', Symbols.favorite),
                  _item(2, 'Đăng tin', Symbols.post_add),
                  _item(3, 'Thông báo', Symbols.notifications),
                  _item(4, 'Tài khoản', Symbols.person),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
