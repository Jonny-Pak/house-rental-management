import '../../../payment/presentation/pages/payment_status_page.dart';
import '../../../payment/presentation/pages/payment_history_page.dart';
import 'subscription_benefits_page.dart';

import 'package:frontend/core/theme/app_colors.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/layout/app_layout.dart';
import '../../../../core/network/api_client.dart';
import '../../data/models/membership_package_model.dart';
import '../../data/repositories/membership_repository.dart';
import '../bloc/membership_cubit.dart';
import '../bloc/membership_state.dart';
import '../widgets/membership_offers.dart';
import '../../../payment/data/repositories/payment_repository.dart';
import '../../../payment/presentation/cubit/payment_cubit.dart';
import '../../../payment/presentation/cubit/payment_state.dart';

const _accent = AppColors.primary;
const _ink = AppColors.text;
const _muted = AppColors.muted;
const _border = AppColors.border;

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
  Widget build(BuildContext context) =>
      BlocConsumer<PaymentCubit, PaymentState>(
        listener: (context, state) async {
          if (state is PaymentOpened) {
            final paid = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (_) => PaymentStatusPage(
                  reference: state.reference,
                  repository: context.read<PaymentCubit>().repository,
                ),
              ),
            );
            if (!context.mounted) return;
            if (paid == true) {
              Navigator.pop(context, true);
            } else {
              context.read<MembershipCubit>().fetchPackages();
            }
            return;
          }
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
            backgroundColor: AppColors.background,
            appBar: AppBar(
              backgroundColor: AppColors.background,
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
                IconButton(
                  tooltip: 'Lịch sử thanh toán',
                  icon: const Icon(Symbols.receipt_long),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PaymentHistoryPage(
                        repository: context.read<PaymentCubit>().repository,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Quyền lợi của tôi',
                  icon: const Icon(Symbols.workspace_premium),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SubscriptionBenefitsPage(),
                    ),
                  ),
                ),
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
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                          children: [
                            const Text(
                              'Mỗi lượt nâng VIP áp dụng cho một tin đã duyệt. Gói mua thêm có hạn sử dụng 30 ngày.',
                              style: TextStyle(
                                color: AppColors.muted,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 12),
                            MembershipOffers(
                              packages: packages,
                              busy: busy,
                              onSubscribe: (package) => context
                                  .read<PaymentCubit>()
                                  .initiatePayment(package.id),
                            ),
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
}
