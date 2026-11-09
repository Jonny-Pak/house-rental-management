import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

class MembershipRankTag extends StatelessWidget {
  const MembershipRankTag({super.key, required this.rank});
  final String rank;

  @override
  Widget build(BuildContext context) {
    var colors = const [Color(0xFFF5F7F6), Color(0xFFE8EEEB)];
    var foreground = const Color(0xFF52645B);
    var border = const Color(0xFFD1DDD6);
    var icon = Symbols.person;
    var iconBackground = Colors.white.withValues(alpha: .8);

    if (rank == 'PLUS') {
      colors = const [Color(0xFFE2FAF5), Color(0xFFC1EDE6)];
      foreground = const Color(0xFF086D65);
      border = const Color(0xFF8DD7CC);
      icon = Symbols.diamond;
    } else if (rank == 'PRO') {
      colors = const [Color(0xFF173D32), Color(0xFF2C5E4B)];
      foreground = const Color(0xFFFFE2A1);
      border = const Color(0xFFCBA86A);
      icon = Symbols.workspace_premium;
      iconBackground = const Color(0xFFFFDA88).withValues(alpha: .15);
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(5, 4, 12, 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: border.withValues(alpha: .16),
            blurRadius: 7,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              size: 17,
              color: foreground,
              fill: rank == 'PRO' ? 1 : 0,
              weight: 500,
            ),
          ),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              'Hạng $rank',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: foreground,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: .5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
