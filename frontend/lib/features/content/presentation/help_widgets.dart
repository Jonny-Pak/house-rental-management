import 'package:flutter/material.dart';

class HelpHero extends StatelessWidget {
  const HelpHero({
    super.key,
    required this.title,
    required this.caption,
    required this.icon,
    this.accent = const Color(0xFF15803D),
    this.footer,
  });
  final String title, caption;
  final IconData icon;
  final Color accent;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: dark
              ? [const Color(0xFF173B2C), const Color(0xFF19332C)]
              : [const Color(0xFFE2F4E9), const Color(0xFFF1F8F1)],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: accent.withValues(alpha: .14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(icon, color: accent, size: 30),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'RENTAL / ĐỒNG HÀNH CÙNG BẠN',
                  style: TextStyle(
                    color: dark
                        ? const Color(0xFFA7DCBC)
                        : const Color(0xFF34724D),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              Icon(
                Icons.spa_outlined,
                size: 32,
                color: accent.withValues(alpha: .3),
              ),
            ],
          ),
          const SizedBox(height: 22),
          SelectableText(
            title,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              height: 1.25,
              letterSpacing: -.5,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            caption,
            style: TextStyle(
              fontSize: 14,
              height: 1.6,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          if (footer != null) ...[const SizedBox(height: 18), footer!],
        ],
      ),
    );
  }
}

class HelpLink extends StatelessWidget {
  const HelpLink({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });
  final String title, subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    elevation: 0,
    color: Theme.of(context).colorScheme.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: BorderSide(
        color: Theme.of(context).colorScheme.outlineVariant
            .withValues(alpha: .5),
      ),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0x1415803D),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: const Color(0xFF15803D), size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_rounded, size: 18),
          ],
        ),
      ),
    ),
  );
}

String contentCaption(String slug) {
  switch (slug) {
    case 'rules':
      return 'Cùng xây dựng cộng đồng tìm thuê minh bạch, tôn trọng và đáng tin cậy.';
    case 'guide':
      return 'Bắt đầu dễ dàng, từ tìm một nơi ở đến quản lý việc cho thuê.';
    case 'contact':
      return 'Một nơi để tìm thông tin liên hệ và nhận hỗ trợ khi bạn cần.';
    case 'support':
      return 'Mô tả đúng vấn đề để đội ngũ quản trị có thể tiếp nhận và hỗ trợ bạn.';
    default:
      return 'Kết nối người tìm nơi ở với người cho thuê, trong một trải nghiệm đơn giản.';
  }
}
