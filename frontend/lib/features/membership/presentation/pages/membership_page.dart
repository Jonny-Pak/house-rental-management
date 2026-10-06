import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/api_client.dart';
import '../../data/models/membership_package_model.dart';
import '../../data/repositories/membership_repository.dart';
import '../bloc/membership_cubit.dart';
import '../bloc/membership_state.dart';

import '../../../payment/data/repositories/payment_repository.dart';
import '../../../payment/presentation/cubit/payment_cubit.dart';
import '../../../payment/presentation/cubit/payment_state.dart';

class MembershipPage extends StatelessWidget {
  const MembershipPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => MembershipCubit(
            repository: MembershipRepository(ApiClient()),
          )..fetchPackages(),
        ),
        BlocProvider(
          create: (context) => PaymentCubit(
            repository: PaymentRepository(ApiClient()),
          ),
        ),
      ],
      child: const MembershipView(),
    );
  }
}

class MembershipView extends StatelessWidget {
  const MembershipView({super.key});

  @override
  Widget build(BuildContext context) {
    const kAccentOrange = Color(0xFFF67522);
    const kBackground = Color(0xFFF9F9F9);

    return Scaffold(
      backgroundColor: kBackground,
      body: BlocConsumer<PaymentCubit, PaymentState>(
        listener: (context, state) {
          if (state is PaymentError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message, style: const TextStyle(color: Colors.white)), backgroundColor: Colors.red),
            );
          } else if (state is PaymentSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Đăng ký gói thành công!', style: TextStyle(color: Colors.white)), backgroundColor: Colors.green),
            );
            if (state.paymentUrl == 'FREE_SUCCESS') {
              Future.delayed(const Duration(seconds: 1), () {
                if (context.mounted) Navigator.pop(context);
              });
            }
          }
        },
        builder: (context, paymentState) {
          return Stack(
            children: [
              Column(
                children: [
                  _buildHeader(context, kAccentOrange),
                  Expanded(
                    child: BlocBuilder<MembershipCubit, MembershipState>(
                      builder: (context, state) {
                        if (state is MembershipLoading || state is MembershipInitial) {
                          return const Center(child: CircularProgressIndicator(color: kAccentOrange));
                        } else if (state is MembershipError) {
                          return Center(child: Text('Lỗi: ${state.message}', style: const TextStyle(color: Colors.red)));
                        } else if (state is MembershipLoaded) {
                          final uniquePackages = <int, MembershipPackage>{};
                          for (var p in state.packages) {
                            uniquePackages[p.id] = p;
                          }
                          final packages = uniquePackages.values.toList()..sort((a, b) => a.price.compareTo(b.price));
                          if (packages.isEmpty) {
                            return const Center(child: Text('Chưa có gói dịch vụ nào.'));
                          }

                          return ListView(
                            padding: EdgeInsets.zero,
                            children: [
                              const SizedBox(height: 24),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                                child: RichText(
                                  textAlign: TextAlign.center,
                                  text: const TextSpan(
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                      height: 1.4,
                                    ),
                                    children: [
                                      TextSpan(text: 'Nâng cấp để tận hưởng nhiều đặc\nquyền và quyền lợi hơn của '),
                                      TextSpan(text: 'NhaTot', style: TextStyle(color: kAccentOrange)),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              ...packages.map((package) {
                                return _buildPackageCard(context, package, kAccentOrange);
                              }),
                              const SizedBox(height: 40),
                            ],
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ],
              ),
              if (paymentState is PaymentLoading)
                Container(
                  color: Colors.black54,
                  child: const Center(
                    child: CircularProgressIndicator(color: kAccentOrange),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Color accentOrange) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        bottom: 20,
        left: 16,
        right: 16,
      ),
      decoration: BoxDecoration(
        color: accentOrange,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
            },
            child: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
          ),
          const Expanded(
            child: Text(
              'Gói dịch vụ',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 28),
        ],
      ),
    );
  }

  Widget _buildPackageCard(
    BuildContext context,
    MembershipPackage package, 
    Color accentOrange,
  ) {
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accentOrange, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              package.packageName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${currencyFormatter.format(package.price)} / vĩnh viễn',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            Divider(color: accentOrange, thickness: 1.5),
            const SizedBox(height: 16),
            const Text(
              'Quyền lợi:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            if (package.standardPostQuota > 0)
              _buildFeatureRow('${package.standardPostQuota} tin đăng thường'),
            if (package.vipPostQuota > 0)
              _buildFeatureRow('${package.vipPostQuota} tin đăng VIP'),
            if (package.refreshQuota > 0)
              _buildFeatureRow('${package.refreshQuota} lượt làm mới tin'),
            if (package.description != null && package.description!.isNotEmpty)
              _buildFeatureRow(package.description!),
            const SizedBox(height: 32),
            Center(
              child: SizedBox(
                width: 180,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    context.read<PaymentCubit>().initiatePayment(package.id);
                  },
                  child: const Text(
                    'Đăng ký ngay',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
