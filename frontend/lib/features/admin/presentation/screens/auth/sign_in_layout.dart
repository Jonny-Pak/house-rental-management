import 'package:flutter/material.dart';

class SignInLayout extends StatelessWidget {
  const SignInLayout({
    super.key,
    required this.title,
    required this.subtitle,
    required this.fields,
  });
  final String title, subtitle;
  final List<Widget> fields;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: dark ? const Color(0xFF111B16) : const Color(0xFFF7F9F8),
      body: LayoutBuilder(
        builder: (context, box) => SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: box.maxHeight > 48 ? box.maxHeight - 48 : 0,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.home_work_rounded,
                          size: 32,
                          color: colors.primary,
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            'Rental Admin',
                            style: TextStyle(
                              color: colors.onSurface,
                              fontSize: 25,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Container(
                      padding: EdgeInsets.all(box.maxWidth < 400 ? 24 : 32),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: colors.outlineVariant.withValues(alpha: .6),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF153B28)
                                .withValues(alpha: dark ? .03 : .04),
                            blurRadius: 28,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -.5,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            subtitle,
                            style: TextStyle(
                              color: colors.onSurfaceVariant,
                              fontSize: 14,
                              height: 1.6,
                            ),
                          ),
                          const SizedBox(height: 28),
                          ...fields,
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
