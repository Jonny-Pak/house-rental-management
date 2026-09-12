import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../../../core/network/api_client.dart';
import '../../data/repositories/property_repository.dart';
import '../cubit/property_detail_cubit.dart';
import '../cubit/property_detail_state.dart';

class PropertyDetailPage extends StatelessWidget {
  final int propertyId;

  const PropertyDetailPage({super.key, required this.propertyId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PropertyDetailCubit(
        PropertyRepository(GetIt.I<ApiClient>()),
      )..fetchPropertyDetails(propertyId),
      child: const PropertyDetailView(),
    );
  }
}

class PropertyDetailView extends StatelessWidget {
  const PropertyDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocBuilder<PropertyDetailCubit, PropertyDetailState>(
        builder: (context, state) {
          if (state.status == PropertyDetailStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state.status == PropertyDetailStatus.error) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Lỗi: ${state.errorMessage}', style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context
                        .read<PropertyDetailCubit>()
                        .fetchPropertyDetails(context.read<PropertyDetailCubit>().state.property?.id ?? 0),
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          } else if (state.status == PropertyDetailStatus.success && state.property != null) {
            final property = state.property!;
            return CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 300,
                  pinned: true,
                  flexibleSpace: FlexibleSpaceBar(
                    background: property.imageUrls.isNotEmpty
                        ? PageView.builder(
                            itemCount: property.imageUrls.length,
                            itemBuilder: (context, index) {
                              return Image.network(
                                property.imageUrls[index],
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 50),
                              );
                            },
                          )
                        : Container(
                            color: Colors.grey[300],
                            child: const Icon(Icons.home, size: 100, color: Colors.grey),
                          ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                property.name,
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Chip(
                              label: Text(
                                property.propertyType == 'WHOLE_HOUSE' ? 'Nhà nguyên căn' : 'Khu trọ',
                                style: const TextStyle(fontSize: 12),
                              ),
                              backgroundColor: Colors.blue.shade50,
                              side: BorderSide.none,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 20, color: Colors.grey),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                property.address,
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey[700]),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 8),
                        Text('Giá dịch vụ', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Giá điện:', style: Theme.of(context).textTheme.bodyLarge),
                            Text('${property.electricityPrice} đ/kWh', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Giá nước:', style: Theme.of(context).textTheme.bodyLarge),
                            Text('${property.waterPrice} đ/khối', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 8),
                        Text('Mô tả chi tiết', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(
                          property.description,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 24),
                        Text('Danh sách phòng (${state.rooms.length})', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final room = state.rooms[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 1,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(room.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                    Text(
                                      '${room.price} đ/tháng',
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.indigo),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.square_foot, size: 16, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text('${room.area} m2', style: const TextStyle(color: Colors.grey)),
                                    const SizedBox(width: 16),
                                    const Icon(Icons.people, size: 16, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text('Tối đa ${room.maxCapacity} người', style: const TextStyle(color: Colors.grey)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: room.status == 'AVAILABLE' ? Colors.green.shade50 : Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      room.status == 'AVAILABLE' ? 'Còn trống' : 'Đã thuê',
                                      style: TextStyle(
                                        color: room.status == 'AVAILABLE' ? Colors.green : Colors.red,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      childCount: state.rooms.length,
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 80)), // Padding for bottom app bar
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
      bottomSheet: BlocBuilder<PropertyDetailCubit, PropertyDetailState>(
        builder: (context, state) {
          if (state.status == PropertyDetailStatus.success && state.property != null) {
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.grey.withAlpha(50), spreadRadius: 1, blurRadius: 5, offset: const Offset(0, -1)),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          // TODO: Implement contact action
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chức năng liên hệ đang phát triển')));
                        },
                        icon: const Icon(Icons.phone),
                        label: const Text('Liên hệ Chủ nhà'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
