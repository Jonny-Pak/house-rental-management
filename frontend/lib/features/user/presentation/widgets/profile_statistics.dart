import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/user_profile.dart';

class ProfileStatistics extends StatelessWidget {
  const ProfileStatistics({
    super.key,
    required this.profile,
    required this.onListings,
    required this.onContracts,
    required this.onSaved,
  });
  final UserProfile profile;
  final VoidCallback onListings, onContracts, onSaved;

  Widget _card(
    String key,
    String label,
    int? count,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) => Material(
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: const BorderSide(color: AppColors.border),
    ),
    child: InkWell(
      key: ValueKey(key),
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(
              count?.toString() ?? '—',
              key: ValueKey('$key-count'),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.muted,
              ),
            ),
          ],
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final large = MediaQuery.textScalerOf(context).scale(12) > 20;
      final width = large
          ? constraints.maxWidth
          : (constraints.maxWidth - 16) / 3;
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          SizedBox(
            width: width,
            child: _card(
              'profile-listings',
              'Tin đăng',
              profile.listingCount,
              Symbols.description,
              AppColors.primary,
              onListings,
            ),
          ),
          SizedBox(
            width: width,
            child: _card(
              'profile-contracts',
              'Hợp đồng',
              profile.contractCount,
              Symbols.receipt_long,
              const Color(0xFF329B8E),
              onContracts,
            ),
          ),
          SizedBox(
            width: width,
            child: _card(
              'profile-saved',
              'Tin đã lưu',
              profile.savedListingCount,
              Symbols.favorite,
              const Color(0xFFEC617B),
              onSaved,
            ),
          ),
        ],
      );
    },
  );
}
