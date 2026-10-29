import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_symbols_icons/symbols.dart';

class HomeFeatureIcon extends StatelessWidget {
  const HomeFeatureIcon({super.key, required this.icon, this.size = 56});

  final IconData icon;
  final double size;

  Color get backgroundColor => switch (assetName) {
    'rent_house' || 'guide' => const Color(0xFFF0F8F5),
    'rent_room' || 'introduction' => const Color(0xFFF0F5FC),
    'manage_listings' || 'contact' => const Color(0xFFF6F2FC),
    'contracts' || 'report' => const Color(0xFFFDF2F4),
    'subscription' => const Color(0xFFFFF8E9),
    'map' => const Color(0xFFF1F8EF),
    'assistant' => const Color(0xFFEEF8FC),
    'rules' => const Color(0xFFFAF4EE),
    _ => const Color(0xFFFFF5EC),
  };

  String? get assetName => switch (icon) {
    Symbols.post_add => 'post_listing',
    Symbols.home_work => 'rent_house',
    Symbols.apartment || Symbols.group => 'rent_room',
    Symbols.assignment => 'manage_listings',
    Symbols.receipt_long => 'contracts',
    Symbols.payments => 'subscription',
    Symbols.map => 'map',
    Symbols.smart_toy => 'assistant',
    Symbols.menu_book || Symbols.tune => 'introduction',
    Symbols.gavel => 'rules',
    Symbols.help => 'guide',
    Symbols.report => 'report',
    Symbols.support_agent => 'contact',
    _ => null,
  };

  @override
  Widget build(BuildContext context) {
    final name = assetName;
    if (name == null) {
      return Icon(icon, size: size);
    }
    return SvgPicture.asset(
      'assets/icons/home/$name.svg',
      width: size,
      height: size,
      excludeFromSemantics: true,
    );
  }
}
