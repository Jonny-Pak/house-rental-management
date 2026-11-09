import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../listing/data/repositories/listing_repository.dart';
import '../../data/models/subscription_benefits.dart';
import 'membership_page.dart';

class SubscriptionBenefitsPage extends StatefulWidget {
  const SubscriptionBenefitsPage({super.key, this.repository});
  final ListingRepository? repository;
  @override
  State<SubscriptionBenefitsPage> createState() =>
      _SubscriptionBenefitsPageState();
}

class _SubscriptionBenefitsPageState extends State<SubscriptionBenefitsPage> {
  late final repository = widget.repository ?? ListingRepository(ApiClient());
  SubscriptionBenefits? _benefits;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final benefits = await repository.fetchBenefits();
      if (mounted) setState(() => _benefits = benefits);
    } catch (error) {
      if (mounted) {
        setState(() => _error = ListingRepository.errorMessage(error));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _packages() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MembershipPage()),
    );
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final benefits = _benefits;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quyền lợi của tôi'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            tooltip: 'Tải lại quyền lợi',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 650),
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    if (_error != null) ...[
                      Text(_error!),
                      TextButton(
                        onPressed: _load,
                        child: const Text('Thử lại'),
                      ),
                    ] else if (benefits != null) ...[
                      Text(
                        benefits.packageName,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        benefits.status == 'ACTIVE'
                            ? 'Đang sử dụng'
                            : 'Gói đã hết hạn',
                        style: TextStyle(
                          color: benefits.status == 'ACTIVE'
                              ? AppColors.primary
                              : Colors.red,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        benefits.expiresAt == null
                            ? 'Không giới hạn thời gian sử dụng lượt.'
                            : 'Hạn sử dụng: ${DateFormat('dd/MM/yyyy HH:mm').format(benefits.expiresAt!)}',
                      ),
                      const SizedBox(height: 20),
                      _quota(
                        Icons.post_add,
                        'Lượt đăng tin còn lại',
                        benefits.standard,
                      ),
                      _quota(
                        Icons.workspace_premium,
                        'Lượt nâng VIP còn lại',
                        benefits.vip,
                      ),
                      _quota(
                        Icons.update,
                        'Lượt làm mới còn lại',
                        benefits.refresh,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        '• Mỗi tin mới dùng 1 lượt đăng, kể cả nhập Excel.\n'
                        '• Sửa, ẩn, xóa hoặc bị từ chối không hoàn lại lượt đăng. Sửa tin không trừ thêm lượt.\n'
                        '• Nâng VIP dùng 1 lượt, ưu tiên hiển thị tối đa 30 ngày và không vượt hạn gói.\n'
                        '• Làm mới dùng 1 lượt, đưa tin lên đầu nhóm thường/VIP tương ứng. Mỗi tin một lần trong 24 giờ.\n'
                        '• Chỉ tin đã duyệt và còn trống mới dùng được VIP/làm mới.\n'
                        '• Gói trả phí có hạn 30 ngày; mua thêm khi còn hạn sẽ cộng lượt và gia hạn 30 ngày từ lúc thanh toán.\n'
                        '• Gói Cơ bản chỉ cấp một lần, không tự nạp lại lượt.',
                        style: TextStyle(height: 1.7),
                      ),
                    ],
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _packages,
                      child: const Text('Khám phá gói dịch vụ'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _quota(IconData icon, String label, int count) => Card(
    child: ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(label),
      trailing: Text(
        '$count',
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    ),
  );
}
