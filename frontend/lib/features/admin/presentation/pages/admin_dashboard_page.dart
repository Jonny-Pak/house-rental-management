import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../data/models/admin_listing_model.dart';
import '../bloc/admin_listing_cubit.dart';
import '../bloc/admin_listing_state.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({Key? key}) : super(key: key);

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  @override
  void initState() {
    super.initState();
    context.read<AdminListingCubit>().fetchPendingListings();
  }

  void _showReviewDialog(BuildContext context, AdminListingModel listing) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: 600,
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chi tiết bài đăng',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Image placeholder (horizontal scroll)
                  SizedBox(
                    height: 150,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: 3, // Dummy image count
                      itemBuilder: (context, index) {
                        return Container(
                          width: 200,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: const Center(
                            child: Icon(Icons.image, size: 50, color: Colors.grey),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  _buildDetailRow('Tiêu đề:', listing.title),
                  _buildDetailRow('Địa chỉ:', listing.address),
                  _buildDetailRow('Diện tích:', '${listing.areaSqm} m2'),
                  _buildDetailRow('Giá thuê:', NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(listing.rentPrice)),
                  _buildDetailRow('Loại nhà:', listing.houseType ?? 'N/A'),
                  _buildDetailRow('Giấy tờ pháp lý:', listing.legalDocuments ?? 'N/A'),
                  _buildDetailRow('Mô tả:', listing.description),
                  
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('Đóng'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          _showRejectDialog(context, listing.id);
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        child: const Text('Từ chối', style: TextStyle(color: Colors.white)),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          context.read<AdminListingCubit>().approveListing(listing.id);
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        child: const Text('Phê duyệt', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showRejectDialog(BuildContext context, int listingId) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Lý do từ chối'),
          content: TextField(
            controller: reasonController,
            decoration: const InputDecoration(
              hintText: 'Nhập lý do từ chối (VD: Ảnh không hợp lệ)',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                if (reasonController.text.trim().isEmpty) return;
                Navigator.of(ctx).pop();
                context.read<AdminListingCubit>().rejectListing(listingId, reasonController.text.trim());
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Xác nhận từ chối', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản trị hệ thống'),
        centerTitle: true,
      ),
      body: BlocConsumer<AdminListingCubit, AdminListingState>(
        listener: (context, state) {
          if (state is AdminListingActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.green),
            );
          } else if (state is AdminListingError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          }
        },
        builder: (context, state) {
          if (state is AdminListingLoading && context.read<AdminListingCubit>().state is! AdminListingLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          List<AdminListingModel> listings = [];
          if (state is AdminListingLoaded) {
            listings = state.pendingListings;
          } else if (context.read<AdminListingCubit>().state is AdminListingLoaded) {
            listings = (context.read<AdminListingCubit>().state as AdminListingLoaded).pendingListings;
          }

          if (listings.isEmpty && state is! AdminListingLoading) {
            return const Center(child: Text('Không có bài đăng nào cần duyệt.'));
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: isWideScreen
                ? _buildDataTable(listings)
                : _buildListView(listings),
          );
        },
      ),
    );
  }

  Widget _buildDataTable(List<AdminListingModel> listings) {
    return SingleChildScrollView(
      child: SizedBox(
        width: double.infinity,
        child: DataTable(
          headingRowColor: const WidgetStatePropertyAll(Color(0xFFEEEEEE)),
          columns: const [
            DataColumn(label: Text('ID')),
            DataColumn(label: Text('Tiêu đề')),
            DataColumn(label: Text('Loại')),
            DataColumn(label: Text('Chủ sở hữu')),
            DataColumn(label: Text('Ngày tạo')),
            DataColumn(label: Text('Thao tác')),
          ],
          rows: listings.map((listing) {
            return DataRow(
              cells: [
                DataCell(Text(listing.id.toString())),
                DataCell(
                  SizedBox(
                    width: 250,
                    child: Text(listing.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ),
                DataCell(Text(listing.listingType ?? 'N/A')),
                DataCell(Text(listing.ownerName ?? 'N/A')),
                DataCell(Text(listing.createdAt?.substring(0, 10) ?? 'N/A')),
                DataCell(
                  ElevatedButton.icon(
                    onPressed: () => _showReviewDialog(context, listing),
                    icon: const Icon(Icons.preview, size: 16),
                    label: const Text('Xem xét'),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildListView(List<AdminListingModel> listings) {
    return ListView.builder(
      itemCount: listings.length,
      itemBuilder: (context, index) {
        final listing = listings[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text(
              listing.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('ID: ${listing.id} - Loại: ${listing.listingType ?? 'N/A'}'),
                Text('Chủ: ${listing.ownerName ?? 'N/A'} - Ngày: ${listing.createdAt?.substring(0, 10) ?? 'N/A'}'),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.arrow_forward_ios, size: 16),
              onPressed: () => _showReviewDialog(context, listing),
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }
}
