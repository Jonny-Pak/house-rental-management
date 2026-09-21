import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/api_client.dart';
import '../../data/models/membership_package_model.dart';
import '../../data/repositories/membership_repository.dart';
import '../bloc/membership_cubit.dart';
import '../bloc/membership_state.dart';

class MembershipPage extends StatelessWidget {
  const MembershipPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => MembershipCubit(
        repository: MembershipRepository(ApiClient()),
      )..fetchPackages(),
      child: const MembershipView(),
    );
  }
}

class MembershipView extends StatelessWidget {
  const MembershipView({super.key});

  @override
  Widget build(BuildContext context) {
    const kPrimaryDark = Color(0xFF2C1D11);
    const kAccentOrange = Color(0xFFD85D15);
    const kBackground = Color(0xFFFAF8F5);

    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        title: const Text(
          'Bảng giá dịch vụ',
          style: TextStyle(color: kPrimaryDark, fontWeight: FontWeight.bold),
        ),
        backgroundColor: kBackground,
        elevation: 0,
        iconTheme: const IconThemeData(color: kPrimaryDark),
      ),
      body: BlocBuilder<MembershipCubit, MembershipState>(
        builder: (context, state) {
          if (state is MembershipLoading || state is MembershipInitial) {
            return const Center(child: CircularProgressIndicator(color: kAccentOrange));
          } else if (state is MembershipError) {
            return Center(child: Text('Lỗi: ${state.message}', style: const TextStyle(color: Colors.red)));
          } else if (state is MembershipLoaded) {
            final packages = state.packages;
            if (packages.isEmpty) {
              return const Center(child: Text('Chưa có gói dịch vụ nào.'));
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: packages.length,
              itemBuilder: (context, index) {
                final package = packages[index];
                final isVip = package.packageName.toLowerCase().contains('vip') || package.packageName.toLowerCase().contains('pro');
                
                return _buildPackageCard(package, isVip, kPrimaryDark, kAccentOrange);
              },
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildPackageCard(
    MembershipPackage package, 
    bool isVip, 
    Color primaryDark, 
    Color accentOrange,
  ) {
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isVip ? Border.all(color: accentOrange, width: 2) : Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  package.packageName,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isVip ? accentOrange : primaryDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  currencyFormatter.format(package.price),
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: primaryDark,
                  ),
                ),
                const SizedBox(height: 8),
                if (package.description != null && package.description!.isNotEmpty) ...[
                  Text(
                    package.description!,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 16),
                ],
                const Divider(),
                const SizedBox(height: 16),
                _buildFeatureRow('Tin thường: ${package.standardPostQuota} tin', accentOrange),
                const SizedBox(height: 12),
                _buildFeatureRow('Tin VIP: ${package.vipPostQuota} tin', accentOrange),
                const SizedBox(height: 12),
                _buildFeatureRow('Lượt làm mới: ${package.refreshQuota} lượt', accentOrange),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isVip ? accentOrange : primaryDark,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () {
                      // Handle buy action
                    },
                    child: const Text(
                      'Mua ngay',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isVip)
            Positioned(
              top: -12,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: accentOrange,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Phổ biến',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(String text, Color iconColor) {
    return Row(
      children: [
        Icon(Icons.check_circle_rounded, color: iconColor, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 15, color: Colors.black87),
          ),
        ),
      ],
    );
  }
}
