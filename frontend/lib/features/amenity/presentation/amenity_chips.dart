import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/app_colors.dart';
import '../data/amenity_model.dart';

class AmenityChips extends StatelessWidget {
  const AmenityChips({super.key, required this.items});
  final List<Amenity> items;
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (final item in items)
        Chip(
          avatar: Icon(
            item.category == 'FURNITURE' ? Symbols.chair : Symbols.check_circle,
            size: 18,
            color: AppColors.primary,
          ),
          label: Text(item.name, style: const TextStyle(color: AppColors.text)),
          backgroundColor: AppColors.primaryLight,
          side: const BorderSide(color: AppColors.border),
        ),
    ],
  );
}
