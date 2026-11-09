import 'dart:ui';

import 'package:flutter/material.dart';

abstract final class AppLayout {
  static const compact = 600.0;
  static const expanded = 1024.0;
  static const contentWidth = 1200.0;
  static const formWidth = 760.0;
}

class AppContent extends StatelessWidget {
  const AppContent({
    super.key,
    required this.child,
    this.maxWidth = AppLayout.contentWidth,
    this.shrinkWrap = false,
  });
  final Widget child;
  final double maxWidth;
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    heightFactor: shrinkWrap ? 1 : null,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: SizedBox(width: double.infinity, child: child),
    ),
  );
}

class ResponsiveCards extends StatelessWidget {
  const ResponsiveCards({
    super.key,
    required this.children,
    this.minCardWidth = 360,
  });
  final List<Widget> children;
  final double minCardWidth;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      const gap = 12.0;
      final columns = ((constraints.maxWidth + gap) / (minCardWidth + gap))
          .floor()
          .clamp(1, 3);
      final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (final child in children) SizedBox(width: width, child: child),
        ],
      );
    },
  );
}

class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
    PointerDeviceKind.invertedStylus,
  };
}
