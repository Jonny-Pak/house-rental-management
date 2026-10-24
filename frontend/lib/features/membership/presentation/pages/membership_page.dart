import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/layout/app_layout.dart';
import '../../../../core/network/api_client.dart';
import '../../../home/presentation/widgets/home_feature_icon.dart';
import '../../data/models/membership_package_model.dart';
import '../../data/repositories/membership_repository.dart';
import '../bloc/membership_cubit.dart';
import '../bloc/membership_state.dart';
import '../widgets/membership_comparison.dart';
import '../../../payment/data/repositories/payment_repository.dart';
import '../../../payment/presentation/cubit/payment_cubit.dart';
import '../../../payment/presentation/cubit/payment_state.dart';

const _accent = Color(0xFFD76B28);
const _ink = Color(0xFF38291F);
const _muted = Color(0xFF8A7464);
const _border = Color(0xFFEEDFD1);

class MembershipPage extends StatelessWidget {
  const MembershipPage({super.key, this.repository, this.paymentRepository});
  final MembershipRepository? repository;
  final PaymentRepository? paymentRepository;

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
    providers: [
      BlocProvider(
        create: (_) => MembershipCubit(
          repository: repository ?? MembershipRepository(ApiClient()),
        )..fetchPackages(),
      ),
      BlocProvider(
        create: (_) => PaymentCubit(
          repository: paymentRepository ?? PaymentRepository(ApiClient()),
        ),
      ),
    ],
    child: const MembershipView(),
  );
}

class MembershipView extends StatelessWidget {
  const MembershipView({super.key});

  @override
  Widget build(
    BuildContext context,
  ) => BlocConsumer<PaymentCubit, PaymentState>(
    listener: (context, state) {
      if (state is PaymentError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.message),
            backgroundColor: const Color(0xFFAE5141),
          ),
        );
      } else if (state is PaymentSuccess) {
        final free = state.paymentUrl == 'FREE_SUCCESS';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              free ? 'Đăng ký gói thành công!' : 'Đã mở trang thanh toán. Vui lòng hoàn tất thanh toán để đăng ký gói.',
            ),
            backgroundColor: const Color(0xFF387960),
          ),
        );
        if (free) {
          Future.delayed(const Duration(seconds: 1), () {
            if (context.mounted) Navigator.maybePop(context);
          });
        }
      }
    },
    builder: (context, paymentState) {
      final busy = paymentState is PaymentLoading;
      return Scaffold(
        backgroundColor: const Color(0xFFFAF8F5),
        appBar: AppBar(
          backgroundColor: const Color(0xFFFAF8F5),
          surfaceTintColor: Colors.transparent,
          centerTitle: true,
          title: const Text(
            'Gói dịch vụ',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: _ink,
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: IconButton(
                tooltip: 'Tải lại gói dịch vụ',
                onPressed: busy
                    ? null
                    : () => context.read<MembershipCubit>().fetchPackages(),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: _muted,
                  side: const BorderSide(color: _border),
                ),
                icon: const Icon(Symbols.refresh, size: 21),
              ),
            ),
          ],
        ),
        body: Stack(
          children: [
            AppContent(
              maxWidth: AppLayout.contentWidth,
              child: BlocBuilder<MembershipCubit, MembershipState>(
                builder: (context, state) {
                  if (state is MembershipLoading ||
                      state is MembershipInitial) {
                    return const Center(
                      child: CircularProgressIndicator(color: _accent),
                    );
                  }
                  if (state is MembershipError) {
                    return Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Symbols.cloud_off,
                              size: 42,
                              color: _muted,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Không tải được gói dịch vụ',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: _ink,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              state.message,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 13,
                                color: _muted,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: () => context
                                  .read<MembershipCubit>()
                                  .fetchPackages(),
                              child: const Text('Thử lại'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  if (state is! MembershipLoaded) {
                    return const SizedBox.shrink();
                  }
                  final unique = <int, MembershipPackage>{};
                  for (final package in state.packages) {
                    unique[package.id] = package;
                  }
                  final packages = unique.values.toList()
                    ..sort((a, b) => a.price.compareTo(b.price));
                  return RefreshIndicator(
                    onRefresh: () =>
                        context.read<MembershipCubit>().fetchPackages(),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                      children: [
                        _hero(),
                        const SizedBox(height: 28),
                        const Text(
                          'Chọn gói phù hợp',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: _ink,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'So sánh lượt đăng tin và quyền lợi của từng gói.',
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            color: _muted,
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (packages.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(28),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(color: _border),
                            ),
                            child: const Text(
                              'Chưa có gói dịch vụ nào.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: _muted),
                            ),
                          ),
                        ResponsiveCards(
                          children: [
                            for (final package in packages)
                              _packageCard(context, package, busy),
                          ],
                        ),
                        if (packages.isNotEmpty) ...[
                          const SizedBox(height: 32),
                          const Text(
                            'So sánh các gói',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: _ink,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Đối chiếu quyền lợi để chọn đúng nhu cầu. Cuộn ngang để xem tất cả gói.',
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.5,
                              color: _muted,
                            ),
                          ),
                          const SizedBox(height: 18),
                          MembershipComparison(packages: packages),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
            if (busy) ...[
              const Positioned.fill(
                child: ModalBarrier(
                  dismissible: false,
                  color: Color(0x6638291F),
                ),
              ),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: _accent),
                      SizedBox(height: 16),
                      Text(
                        'Đang xử lý yêu cầu…',
                        style: TextStyle(fontSize: 13, color: _muted),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    },
  );

  Widget _hero() => Container(
    padding: const EdgeInsets.all(26),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF253A40), Color(0xFF10282F)],
      ),
      borderRadius: BorderRadius.circular(28),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1DF),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const HomeFeatureIcon(icon: Symbols.payments, size: 72),
            ),
            const Spacer(),
            const Icon(
              Symbols.auto_awesome,
              color: Color(0xFFE8C49A),
              size: 30,
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Text(
          'GÓI DỊCH VỤ CHO BẠN',
          style: TextStyle(
            fontSize: 10,
            letterSpacing: 1.8,
            fontWeight: FontWeight.w600,
            color: Color(0xFFE8C49A),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Đầu tư cho tin đăng.\nMở thêm cơ hội.',
          style: TextStyle(
            fontSize: 28,
            height: 1.2,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Chọn quyền lợi phù hợp, nâng tầm cách bạn giới thiệu không gian cho thuê.',
          style: TextStyle(fontSize: 13, height: 1.6, color: Color(0xFFD4DEDC)),
        ),
      ],
    ),
  );

  Widget _packageCard(
    BuildContext context,
    MembershipPackage package,
    bool busy,
  ) {
    final free = package.price == 0;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: free ? _border : const Color(0xFFE9BD96)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: free
                    ? [const Color(0xFFF7F3EC), const Color(0xFFFFFCF8)]
                    : [const Color(0xFFFFE7CD), const Color(0xFFFFF7EE)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    HomeFeatureIcon(
                      icon: free
                          ? Symbols.home_work
                          : package.vipPostQuota > 0
                          ? Symbols.payments
                          : Symbols.assignment,
                      size: 82,
                    ),
                    const Spacer(),
                    Icon(
                      package.vipPostQuota > 0
                          ? Symbols.auto_awesome
                          : Symbols.verified,
                      color: const Color(0xFFC3976C),
                      size: 24,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  free
                      ? 'KHỞI ĐẦU'
                      : package.vipPostQuota > 0
                      ? 'CÓ TIN VIP'
                      : 'THÊM LƯỢT ĐĂNG',
                  style: const TextStyle(
                    fontSize: 9,
                    letterSpacing: 1.4,
                    fontWeight: FontWeight.w700,
                    color: _muted,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  package.packageName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: _ink,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            free
                ? 'Miễn phí'
                : '${NumberFormat.decimalPattern('vi_VN').format(package.price)} đ',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: _accent,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Giá gói dịch vụ',
            style: TextStyle(fontSize: 11, color: _muted),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Divider(height: 1, color: Color(0xFFF3ECE4)),
          ),
          const Text(
            'Quyền lợi của bạn',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _ink,
            ),
          ),
          const SizedBox(height: 16),
          if (package.standardPostQuota > 0)
            _feature(
              '${package.standardPostQuota} tin đăng thường',
              icon: Symbols.post_add,
            ),
          if (package.vipPostQuota > 0)
            _feature(
              '${package.vipPostQuota} tin đăng VIP',
              icon: Symbols.workspace_premium,
            ),
          if (package.refreshQuota > 0)
            _feature(
              '${package.refreshQuota} lượt làm mới tin',
              icon: Symbols.refresh,
            ),
          if (package.description?.isNotEmpty == true)
            _feature(package.description!),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: busy
                ? null
                : () =>
                      context.read<PaymentCubit>().initiatePayment(package.id),
            style: FilledButton.styleFrom(
              backgroundColor: free ? const Color(0xFFFFEBD9) : _accent,
              foregroundColor: free ? const Color(0xFFAF541E) : Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              free ? 'Chọn gói miễn phí' : 'Đăng ký ngay',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _feature(String text, {IconData icon = Symbols.check_circle}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 19, color: const Color(0xFFC08852)),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: _muted,
                ),
              ),
            ),
          ],
        ),
      );
}
