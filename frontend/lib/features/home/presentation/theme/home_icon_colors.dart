import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

abstract final class HomeIconColors {
  static Color forIcon(IconData icon) => switch (icon) {
    Symbols.post_add => const Color(0xFFE66C20),
    Symbols.home_work => const Color(0xFF168B85),
    Symbols.apartment => const Color(0xFF5272C8),
    Symbols.assignment || Symbols.view_list => const Color(0xFF3478C7),
    Symbols.receipt_long => const Color(0xFF8B59BB),
    Symbols.payments => const Color(0xFFB78219),
    Symbols.map => const Color(0xFF26966B),
    Symbols.smart_toy => const Color(0xFFD15E94),
    Symbols.tune => const Color(0xFF5B7DAD),
    Symbols.gavel => const Color(0xFF996C49),
    Symbols.help => const Color(0xFF4D92CC),
    Symbols.report => const Color(0xFFD3545E),
    Symbols.support_agent => const Color(0xFF398F93),
    Symbols.favorite => const Color(0xFFC0446A),
    Symbols.notifications => const Color(0xFFAA6B13),
    Symbols.person => const Color(0xFF8056AA),
    Symbols.home => const Color(0xFFB36125),
    Symbols.logout => const Color(0xFFD3545E),
    _ => const Color(0xFF52677C),
  };
}
