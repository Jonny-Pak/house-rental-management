import 'package:flutter/material.dart';
import '../cubit/create_listing_state.dart';

const _kAccent = Color(0xFFD85D15);
const _kDark = Color(0xFF2C1D11);
const _kBackground = Color(0xFFFAF8F5);
const _kBorder = Color(0xFFE8DED1);

class ListingPreviewPage extends StatelessWidget {
  final CreateListingState state;

  const ListingPreviewPage({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: _kDark),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Xem trước tin đăng',
          style: TextStyle(color: _kDark, fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _kBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.title.isNotEmpty ? state.title : '(Chưa có tiêu đề)',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _kDark),
                ),
                const SizedBox(height: 12),
                Text(
                  '${state.rentPrice ?? 0} VND/tháng',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kAccent),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        state.address.isNotEmpty ? state.address : '(Chưa có địa chỉ)',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 32),
                const Text(
                  'Hình ảnh đính kèm',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _kDark),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.photo_library_outlined, size: 20, color: _kAccent),
                    const SizedBox(width: 8),
                    Text(
                      '${state.imagePaths.length} ảnh',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _kDark),
                    ),
                  ],
                ),
                const Divider(height: 32),
                const Text(
                  'Thông tin chi tiết',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _kDark),
                ),
                const SizedBox(height: 12),
                _buildInfoRow('Loại hình', state.propertyType == 'WHOLE_HOUSE' ? 'Nhà nguyên căn' : 'Phòng trọ'),
                if (state.propertyType == 'WHOLE_HOUSE') ...[
                  _buildInfoRow('Phòng ngủ', '${state.bedrooms ?? 0} phòng'),
                  _buildInfoRow('Phòng tắm', '${state.bathrooms ?? 0} phòng'),
                ],
                _buildInfoRow('Nội thất', state.furnitureStatus ?? 'Chưa xác định'),
                _buildInfoRow('Cọc', '${state.depositAmount ?? 0} VND'),
                const Divider(height: 32),
                const Text(
                  'Mô tả',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _kDark),
                ),
                const SizedBox(height: 8),
                Text(
                  state.description.isNotEmpty ? state.description : '(Chưa có mô tả)',
                  style: const TextStyle(fontSize: 14, color: _kDark, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: _kBorder)),
        ),
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            style: FilledButton.styleFrom(
              backgroundColor: _kAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text(
              'Đóng xem trước',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, color: _kDark)),
        ],
      ),
    );
  }
}
