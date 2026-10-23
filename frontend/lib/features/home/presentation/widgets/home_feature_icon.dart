import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_symbols_icons/symbols.dart';

class HomeFeatureIcon extends StatelessWidget {
  const HomeFeatureIcon({super.key, required this.icon, this.size = 56});

  final IconData icon;
  final double size;

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
