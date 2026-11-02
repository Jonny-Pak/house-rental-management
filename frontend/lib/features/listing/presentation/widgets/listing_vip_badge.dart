import 'package:flutter/material.dart';

class ListingVipBadge extends StatelessWidget {
  const ListingVipBadge({super.key});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 6),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF3CE),
      borderRadius: BorderRadius.circular(6),
    ),
    child: const Text(
      '★ VIP',
      style: TextStyle(
        color: Color(0xFF805A00),
        fontSize: 11,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}
