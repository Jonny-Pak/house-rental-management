import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/theme/app_colors.dart';

class ChatbotAvatar extends StatelessWidget {
  const ChatbotAvatar({super.key, this.size = 36});
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: const Color(0xFFE8F8EE),
      borderRadius: BorderRadius.circular(size * .35),
    ),
    child: SvgPicture.asset(
      'assets/icons/home/chatbot_robot.svg',
      excludeFromSemantics: true,
    ),
  );
}

class ChatbotWelcome extends StatelessWidget {
  const ChatbotWelcome({
    super.key,
    required this.onSend,
    required this.onDraft,
    required this.onNearby,
  });
  final ValueChanged<String> onSend;
  final ValueChanged<String> onDraft;
  final VoidCallback onNearby;

  Widget _choice(
    IconData icon,
    String label,
    VoidCallback onTap,
    double width,
  ) => SizedBox(
    width: width,
    child: Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          constraints: const BoxConstraints(minHeight: 100),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFDDEFE5)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFFE9F8EE),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.primary, size: 27),
              ),
              const SizedBox(height: 9),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF087846), Color(0xFF16A05B), Color(0xFF49BD88)],
          ),
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              left: -25,
              bottom: 5,
              child: Icon(
                Icons.apartment_rounded,
                size: 150,
                color: Colors.white.withValues(alpha: .09),
              ),
            ),
            Positioned(
              right: -22,
              bottom: 0,
              child: Icon(
                Icons.home_rounded,
                size: 170,
                color: Colors.white.withValues(alpha: .1),
              ),
            ),
            Positioned(
              top: 15,
              right: 35,
              child: Icon(
                Icons.auto_awesome,
                size: 26,
                color: Colors.white.withValues(alpha: .35),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 5, 24, 42),
              child: Column(
                children: [
                  SvgPicture.asset(
                    'assets/icons/home/chatbot_robot.svg',
                    width: 126,
                    height: 126,
                    excludeFromSemantics: true,
                  ),
                  const Text(
                    'Tìm nhà dễ hơn cùng AI',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 25,
                      height: 1.2,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    'Nơi ở phù hợp, bắt đầu từ một câu hỏi.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: .9),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      Transform.translate(
        offset: const Offset(0, -22),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5EF),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: Colors.white.withValues(alpha: .8)),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final largeText =
                    MediaQuery.textScalerOf(context).scale(13) > 19;
                final columns = constraints.maxWidth > 700
                    ? 6
                    : largeText
                    ? 2
                    : 3;
                final width =
                    (constraints.maxWidth - (columns - 1) * 9) / columns;
                return Wrap(
                  spacing: 9,
                  runSpacing: 9,
                  children: [
                    _choice(
                      Icons.home_outlined,
                      'Nhà nguyên căn',
                      () => onSend('Tìm nhà nguyên căn'),
                      width,
                    ),
                    _choice(
                      Icons.bed_outlined,
                      'Thuê phòng trọ',
                      () => onSend('Tìm phòng trọ'),
                      width,
                    ),
                    _choice(
                      Icons.people_outline,
                      'Tìm ở ghép',
                      () => onSend('Tìm người ở ghép'),
                      width,
                    ),
                    _choice(
                      Icons.payments_outlined,
                      'Giá phù hợp',
                      () => onDraft('Tìm phòng trọ dưới '),
                      width,
                    ),
                    _choice(
                      Icons.tune_rounded,
                      'Chọn tiện ích',
                      () => onDraft('Tìm phòng trọ có '),
                      width,
                    ),
                    _choice(
                      Icons.near_me_outlined,
                      'Tìm quanh đây',
                      onNearby,
                      width,
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE5EFE9)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.bolt_rounded, color: AppColors.primary),
                  SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      'Gợi ý câu hỏi cho bạn',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              for (final prompt in [
                'Phòng trọ dưới 4 triệu ở Thủ Đức',
                'Tìm người ở ghép, cho nuôi mèo',
                'Nhà nguyên căn trong bán kính 3 km',
                'Phòng trọ có máy lạnh và WiFi',
              ])
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: const Color(0xFFF7FCF9),
                    borderRadius: BorderRadius.circular(13),
                    child: InkWell(
                      onTap: () => onSend(prompt),
                      borderRadius: BorderRadius.circular(13),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 13,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(13),
                          border: Border.all(color: const Color(0xFFE1EFE6)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                prompt,
                                style: const TextStyle(
                                  fontSize: 13,
                                  height: 1.4,
                                  color: AppColors.text,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: AppColors.primary,
                              size: 21,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 4),
              const Text(
                'Tìm kiếm từ tin đã duyệt, còn trống trong hệ thống.',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.muted,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}
