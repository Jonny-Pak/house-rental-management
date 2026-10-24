import 'package:flutter/material.dart';

const areaAccent = Color(0xFFD66A2B);

Color areaTypeColor(String type) => switch (type) {
  'PROVINCE' => const Color(0xFF5177B7),
  'COMMUNE' => const Color(0xFF298774),
  'SPECIAL' => const Color(0xFF8761BD),
  'DISTRICT' => const Color(0xFF7A8495),
  _ => areaAccent,
};

IconData areaTypeIcon(String type) => switch (type) {
  'PROVINCE' => Icons.account_balance_outlined,
  'COMMUNE' => Icons.cottage_outlined,
  'SPECIAL' => Icons.landscape_outlined,
  'DISTRICT' => Icons.history_outlined,
  _ => Icons.location_city_outlined,
};

Color areaBorder(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
    ? const Color(0xFF343A45)
    : const Color(0xFFE7EAF0);

Color areaMuted(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
    ? const Color(0xFFACB5C4)
    : const Color(0xFF7A8495);

InputDecoration areaInput(
  BuildContext context,
  String label, {
  IconData? icon,
  bool search = false,
}) {
  final dark = Theme.of(context).brightness == Brightness.dark;
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: BorderSide(color: areaBorder(context)),
  );
  return InputDecoration(
    labelText: search ? null : label,
    hintText: search ? label : null,
    labelStyle: TextStyle(color: areaMuted(context), fontSize: 13),
    hintStyle: TextStyle(color: areaMuted(context), fontSize: 13),
    filled: true,
    fillColor: dark ? const Color(0xFF242933) : const Color(0xFFF8F9FC),
    isDense: true,
    counterText: '',
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 17),
    prefixIcon: icon == null
        ? null
        : Icon(icon, size: 19, color: areaMuted(context)),
    border: border,
    enabledBorder: border,
    disabledBorder: border,
    focusedBorder: border.copyWith(
      borderSide: const BorderSide(color: areaAccent, width: 1.4),
    ),
    errorBorder: border.copyWith(
      borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
    ),
    focusedErrorBorder: border.copyWith(
      borderSide: BorderSide(
        color: Theme.of(context).colorScheme.error,
        width: 1.4,
      ),
    ),
  );
}
