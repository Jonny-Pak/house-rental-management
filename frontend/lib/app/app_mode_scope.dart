import 'package:flutter/widgets.dart';

class AppModeScope extends InheritedWidget {
  const AppModeScope({super.key, required this.onSwitch, required super.child});
  final VoidCallback onSwitch;
  static AppModeScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppModeScope>();
  @override
  bool updateShouldNotify(AppModeScope oldWidget) =>
      onSwitch != oldWidget.onSwitch;
}
