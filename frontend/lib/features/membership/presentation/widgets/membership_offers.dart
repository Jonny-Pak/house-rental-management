import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/membership_package_model.dart';
import 'membership_comparison.dart';

class MembershipOffers extends StatefulWidget {
  const MembershipOffers({
    super.key,
    required this.packages,
    required this.busy,
    required this.onSubscribe,
    this.currentPackageId,
    this.currentPackageActive = false,
  });
  final List<MembershipPackage> packages;
  final bool busy;
  final ValueChanged<MembershipPackage> onSubscribe;
  final int? currentPackageId;
  final bool currentPackageActive;
  @override
  State<MembershipOffers> createState() => _MembershipOffersState();
}

class _MembershipOffersState extends State<MembershipOffers> {
  bool _comparison = false;

  Widget _banner() => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF147D58), Color(0xFF39B994)],
      ),
      borderRadius: BorderRadius.circular(22),
      boxShadow: const [
        BoxShadow(
          color: Color(0x1415803D),
          blurRadius: 16,
          offset: Offset(0, 6),
        ),
      ],
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0x26FFFFFF),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Symbols.workspace_premium,
            fill: 1,
            color: Color(0xFFFFDC85),
            size: 34,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nâng tầm hiệu quả cho thuê',
                style: TextStyle(
                  fontSize: 16,
                  height: 1.3,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Thêm lượt đăng, làm mới tin và quyền lợi phù hợp với bạn.',
                style: TextStyle(
                  fontSize: 12,
                  height: 1.4,
                  color: Color(0xFFE4FAEF),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _tab(String label, bool comparison) => Expanded(
    child: TextButton(
      key: ValueKey(
        comparison ? 'membership-tab-comparison' : 'membership-tab-packages',
      ),
      onPressed: widget.busy
          ? null
          : () => setState(() => _comparison = comparison),
      style: TextButton.styleFrom(
        backgroundColor: _comparison == comparison
            ? AppColors.primary
            : Colors.transparent,
        foregroundColor: _comparison == comparison
            ? Colors.white
            : AppColors.primaryDark,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
      ),
    ),
  );

  Color _color(MembershipPackage package) {
    if (package.price == 0) return const Color(0xFF527C91);
    if (package.vipPostQuota > 0) return const Color(0xFF936712);
    return AppColors.primary;
  }

  Widget _benefit(String text, Color color, {bool included = true}) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          included ? Symbols.check : Symbols.remove,
          size: 15,
          weight: 650,
          color: included ? color : AppColors.muted,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 11,
              height: 1.45,
              color: included ? AppColors.text : AppColors.muted,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _card(MembershipPackage package) {
    final free = package.price == 0;
    final vip = package.vipPostQuota > 0;
    final normalizedName = package.packageName.toUpperCase();
    final isPlusOrPro =
        normalizedName.contains('PLUS') || normalizedName.contains('PRO');
    final currentPackage =
        isPlusOrPro &&
        widget.currentPackageActive &&
        widget.currentPackageId == package.id;
    final color = _color(package);
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 14, 10, 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: free
              ? [const Color(0xFFF5F9FC), Colors.white]
              : vip
              ? [const Color(0xFFFFF6E6), const Color(0xFFFFFCF5)]
              : [const Color(0xFFEAF9F1), Colors.white],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: free ? .18 : .45),
          width: free ? 1 : 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: .05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            free
                ? Symbols.home_work
                : vip
                ? Symbols.workspace_premium
                : Symbols.verified,
            color: color,
            size: 30,
            fill: vip ? 1 : 0,
          ),
          const SizedBox(height: 8),
          Text(
            package.packageName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: .09),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              package.defaultPackage
                  ? 'Tự động cấp'
                  : free
                  ? 'Miễn phí'
                  : vip
                  ? 'Có tin VIP'
                  : package.standardPostQuota > 0
                  ? 'Thêm lượt đăng'
                  : 'Làm mới tin',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontSize: 10,
                height: 1.3,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _benefit(
            '${package.standardPostQuota} tin đăng thường',
            color,
            included: package.standardPostQuota > 0,
          ),
          _benefit(
            package.vipPostQuota > 0
                ? '${package.vipPostQuota} lượt nâng VIP'
                : 'Không có tin VIP',
            color,
            included: package.vipPostQuota > 0,
          ),
          _benefit(
            package.refreshQuota > 0
                ? '${package.refreshQuota} lượt làm mới tin'
                : 'Không có lượt làm mới',
            color,
            included: package.refreshQuota > 0,
          ),
          if (package.description?.isNotEmpty == true)
            Tooltip(
              message: package.description!,
              child: Text(
                package.description!,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.5,
                  color: AppColors.muted,
                ),
              ),
            ),
          const Spacer(),
          const SizedBox(height: 18),
          Text(
            '${NumberFormat.decimalPattern('vi_VN').format(package.price)} đ',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            package.defaultPackage
                ? 'Nhận khi đăng ký tài khoản'
                : free
                ? '(Miễn phí)'
                : 'Giá gói dịch vụ',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10, color: AppColors.muted),
          ),
          const SizedBox(height: 14),
          if (currentPackage)
            Container(
              key: ValueKey('membership-current-plan-${package.id}'),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFE6F4EA),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Text(
                'Gói hiện tại',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDark,
                ),
              ),
            )
          else if (package.defaultPackage)
            Container(
              key: const ValueKey('membership-default-plan'),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFE6EDF2),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Text(
                'Gói mặc định',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF35566B),
                ),
              ),
            )
          else
            FilledButton(
              key: ValueKey('membership-subscribe-${package.id}'),
              onPressed: widget.busy ? null : () => widget.onSubscribe(package),
              style: FilledButton.styleFrom(
                backgroundColor: free ? const Color(0xFFE6EDF2) : color,
                foregroundColor: free ? const Color(0xFF35566B) : Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: Text(
                free ? 'Chọn miễn phí' : 'Đăng ký',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _cards() => LayoutBuilder(
    builder: (context, constraints) {
      final largeText = MediaQuery.textScalerOf(context).scale(12) > 17;
      final minimumWidth = largeText ? 240.0 : 105.0;
      final width =
          (constraints.maxWidth - (widget.packages.length - 1) * 8) /
          widget.packages.length;
      if (widget.packages.length <= 3 && width >= minimumWidth) {
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < widget.packages.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(child: _card(widget.packages[i])),
              ],
            ],
          ),
        );
      }
      return SingleChildScrollView(
        key: const ValueKey('membership-cards-scroll'),
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(bottom: 10),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < widget.packages.length; i++) ...[
                if (i > 0) const SizedBox(width: 12),
                SizedBox(
                  width: largeText ? 260 : 190,
                  child: _card(widget.packages[i]),
                ),
              ],
            ],
          ),
        ),
      );
    },
  );

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _banner(),
      const SizedBox(height: 18),
      if (widget.packages.isEmpty)
        Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: const Text(
            'Chưa có gói dịch vụ nào.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted),
          ),
        )
      else ...[
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFFE1F1E7),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Row(
            children: [
              _tab('Các gói dịch vụ', false),
              _tab('So sánh quyền lợi', true),
            ],
          ),
        ),
        const SizedBox(height: 18),
        if (_comparison)
          MembershipComparison(packages: widget.packages)
        else
          _cards(),
      ],
    ],
  );
}
