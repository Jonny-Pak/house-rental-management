import 'package:frontend/core/theme/app_colors.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kite_ui/shadcn.dart';

enum KiteAccent {
  green('Green'),
  slate('Slate'),
  blue('Blue'),
  violet('Violet');

  const KiteAccent(this.label);
  final String label;

  ShadColorScheme scheme(Brightness b) => switch ((this, b)) {
    (KiteAccent.green, Brightness.light) => const ShadGreenColorScheme.light(
      primary: AppColors.primary,
      ring: AppColors.primary,
      accent: Color(0xFFEDF8F0),
      accentForeground: AppColors.primary,
    ),
    (KiteAccent.green, Brightness.dark) => const ShadGreenColorScheme.dark(
      primary: Color(0xFF4ADE80),
      ring: Color(0xFF4ADE80),
      accent: Color(0xFF142D20),
      accentForeground: Color(0xFF86E0A1),
    ),
    (KiteAccent.slate, Brightness.light) => const ShadSlateColorScheme.light(),
    (KiteAccent.slate, Brightness.dark) => const ShadSlateColorScheme.dark(),
    (KiteAccent.blue, Brightness.light) => const ShadBlueColorScheme.light(),
    (KiteAccent.blue, Brightness.dark) => const ShadBlueColorScheme.dark(),
    (KiteAccent.violet, Brightness.light) =>
      const ShadVioletColorScheme.light(),
    (KiteAccent.violet, Brightness.dark) => const ShadVioletColorScheme.dark(),
  };
}

@immutable
class ThemeState {
  const ThemeState({
    this.mode = ThemeMode.system,
    this.accent = KiteAccent.green,
  });

  final ThemeMode mode;
  final KiteAccent accent;

  ThemeState copyWith({ThemeMode? mode, KiteAccent? accent}) =>
      ThemeState(mode: mode ?? this.mode, accent: accent ?? this.accent);

  ShadThemeData data(Brightness b) =>
      ShadThemeData(brightness: b, colorScheme: accent.scheme(b));
}

class ThemeController extends Notifier<ThemeState> {
  @override
  ThemeState build() {
    _modeChanged = false;
    _restoreMode();
    return const ThemeState();
  }

  bool _modeChanged = false;
  static const modeKey = 'admin_theme_mode';

  Future<void> _restoreMode() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final saved = preferences.getString(modeKey);
      if (!ref.mounted || _modeChanged) return;
      for (final mode in ThemeMode.values) {
        if (mode.name == saved) {
          state = state.copyWith(mode: mode);
          return;
        }
      }
    } catch (_) {}
  }

  Future<bool> setMode(ThemeMode mode) async {
    _modeChanged = true;
    state = state.copyWith(mode: mode);
    try {
      final preferences = await SharedPreferences.getInstance();
      return await preferences.setString(modeKey, mode.name);
    } catch (_) {
      return false;
    }
  }

  void setAccent(KiteAccent a) => state = state.copyWith(accent: a);

  void toggleBrightness(BuildContext context) {
    final resolved = state.mode == ThemeMode.system
        ? MediaQuery.platformBrightnessOf(context)
        : (state.mode == ThemeMode.dark ? Brightness.dark : Brightness.light);
    setMode(resolved == Brightness.dark ? ThemeMode.light : ThemeMode.dark);
  }
}

final themeProvider = NotifierProvider<ThemeController, ThemeState>(
  ThemeController.new,
);
