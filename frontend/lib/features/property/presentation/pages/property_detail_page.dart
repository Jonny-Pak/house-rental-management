import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../../../core/network/api_client.dart';
import '../../data/repositories/property_repository.dart';
import '../cubit/property_detail_cubit.dart';
import '../cubit/property_detail_state.dart';
import '../../../favorites/data/repositories/favorite_repository.dart';
import '../../../favorites/presentation/widgets/favorite_button.dart';

// ─── Design System Colors ─────────────────────────────────────────────
const kPrimaryDark   = Color(0xFF2C1D11);
const kPrimaryAccent = Color(0xFFD85D15);
const kBackground    = Color(0xFFFAF8F5);
const kBorderColor   = Color(0xFFE8DED1);
const kSubText       = Color(0xFF64748B);
// ──────────────────────────────────────────────────────────────────────

class PropertyDetailPage extends StatelessWidget {
  final int propertyId;

  const PropertyDetailPage({super.key, required this.propertyId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PropertyDetailCubit(
        PropertyRepository(GetIt.I<ApiClient>()),
      )..fetchPropertyDetails(propertyId),
      child: PropertyDetailView(propertyId: propertyId),
    );
  }
}

class PropertyDetailView extends StatelessWidget {
  final int propertyId;
  const PropertyDetailView({super.key, required this.propertyId});

  String _propertyTypeLabel(String type) {
    switch (type) {
      case 'WHOLE_HOUSE':
        return 'Nhà nguyên căn';
      case 'BOARDING_HOUSE':
        return 'Khu trọ';
      default:
        return 'Căn hộ';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      body: BlocBuilder<PropertyDetailCubit, PropertyDetailState>(
        builder: (context, state) {
          if (state.status == PropertyDetailStatus.loading) {
            return const Center(child: CircularProgressIndicator(color: kPrimaryAccent));
          } else if (state.status == PropertyDetailStatus.error) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
                  const SizedBox(height: 16),
                  Text('Lỗi: ${state.errorMessage}', style: const TextStyle(color: kSubText)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: kPrimaryAccent, foregroundColor: Colors.white),
                    onPressed: () => context
                        .read<PropertyDetailCubit>()
                        .fetchPropertyDetails(propertyId),
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
                  expandedHeight: 320,
                  pinned: true,
                  backgroundColor: kPrimaryDark,
                  iconTheme: const IconThemeData(color: Colors.white),
                  actions: [
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                      child: FavoriteButton(
                        propertyId: property.id,
                        repository: FavoriteRepository(GetIt.I<ApiClient>()),
                        initialIsFavorite: false,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        property.imageUrls.isNotEmpty
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
                                child: const Icon(Icons.home_work_outlined, size: 100, color: Colors.grey),
                              ),
                        // Gradient overlay for better text/icon visibility
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.4),
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.4),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Photo count badge
                        if (property.imageUrls.length > 1)
                          Positioned(
                            bottom: 16,
                            right: 16,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.photo_library_outlined, color: Colors.white, size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    '1 / ${property.imageUrls.length}',
                                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                    ),
                    transform: Matrix4.translationValues(0, -20, 0),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 36, 20, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Type and ID
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: kPrimaryAccent.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: kPrimaryAccent.withValues(alpha: 0.3)),
                                ),
                                child: Text(
                                  _propertyTypeLabel(property.propertyType),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: kPrimaryAccent,
                                  ),
                                ),
                              ),
                              Text(
                                'Mã tin: #${property.id}',
                                style: const TextStyle(color: kSubText, fontSize: 13),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          
                          // Property Name
                          Text(
                            property.name,
                            style: const TextStyle(
                              color: kPrimaryDark,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 12),
                          
                          // Address
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.location_on_outlined, size: 18, color: kSubText),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  property.address,
                                  style: const TextStyle(color: kSubText, fontSize: 14, height: 1.4),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          
                          // Utility Prices
                          Row(
                            children: [
                              Expanded(
                                child: _buildInfoCard(
                                  icon: Icons.electric_bolt_outlined,
                                  title: 'Giá điện',
                                  value: '${property.electricityPrice}đ/kWh',
                                  color: Colors.amber.shade700,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildInfoCard(
                                  icon: Icons.water_drop_outlined,
                                  title: 'Giá nước',
                                  value: '${property.waterPrice}đ/khối',
                                  color: Colors.blue.shade600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          
                          // Landlord Info
                          const Text(
                            'Thông tin Chủ nhà',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kPrimaryDark),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: kBorderColor),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: kPrimaryAccent.withValues(alpha: 0.1),
                                  child: const Icon(Icons.person_outline, color: kPrimaryAccent, size: 24),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        property.landlordName ?? 'Đang cập nhật',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: kPrimaryDark,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      const Text('Chủ sở hữu', style: TextStyle(color: kSubText, fontSize: 13)),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.verified_user_outlined, color: Colors.green),
                                  onPressed: () {},
                                  tooltip: 'Đã xác thực',
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Description
                          const Text(
                            'Mô tả chi tiết',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kPrimaryDark),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            property.description,
                            style: const TextStyle(
                              color: kSubText,
                              fontSize: 14,
                              height: 1.6,
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          // Rooms Header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Danh sách phòng',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kPrimaryDark),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: kPrimaryDark,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${state.rooms.length} phòng',
                                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final room = state.rooms[index];
                        final isAvailable = room.status == 'AVAILABLE';
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: kBorderColor),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x05000000),
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        room.name,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: kPrimaryDark,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isAvailable ? Colors.green.shade50 : Colors.red.shade50,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: isAvailable ? Colors.green.shade200 : Colors.red.shade200,
                                        ),
                                      ),
                                      child: Text(
                                        isAvailable ? 'Còn trống' : 'Đã thuê',
                                        style: TextStyle(
                                          color: isAvailable ? Colors.green.shade700 : Colors.red.shade700,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  '${room.price} đ/tháng',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: kPrimaryAccent,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Divider(color: kBorderColor, height: 1),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    _buildRoomFeature(Icons.square_foot_outlined, '${room.area} m²'),
                                    const SizedBox(width: 20),
                                    _buildRoomFeature(Icons.people_outline, 'Tối đa ${room.maxCapacity} người'),
                                  ],
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
                const SliverToBoxAdapter(child: SizedBox(height: 100)), // Padding for bottom app bar
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
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24), // Extra bottom padding for SafeArea
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Color(0x0F000000), spreadRadius: 1, blurRadius: 10, offset: Offset(0, -4)),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: OutlinedButton(
                        onPressed: () async {
                          final phone = state.property?.landlordPhone ?? '';
                          if (phone.isNotEmpty) {
                            await Clipboard.setData(ClipboardData(text: phone));
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Đã sao chép: $phone'),
                                  backgroundColor: kPrimaryDark,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          } else {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Chủ nhà chưa cung cấp số điện thoại'),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            }
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          side: const BorderSide(color: kPrimaryDark),
                        ),
                        child: const Icon(Icons.phone_outlined, color: kPrimaryDark, size: 22),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: FilledButton.icon(
                        onPressed: () async {
                          final phone = state.property?.landlordPhone ?? '';
                          if (phone.isNotEmpty) {
                            final url = Uri.parse('https://zalo.me/$phone');
                            if (await canLaunchUrl(url)) {
                              await launchUrl(url, mode: LaunchMode.externalApplication);
                            } else {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Không thể mở Zalo'),
                                    backgroundColor: Colors.redAccent,
                                  ),
                                );
                              }
                            }
                          } else {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Chủ nhà chưa cung cấp Zalo'),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            }
                          }
                        },
                        icon: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.network(
                            'https://thumb.wikimedia.org/wikipedia/commons/thumb/9/91/Icon_of_Zalo.svg/3840px-Icon_of_Zalo.svg.png?utm_source=vi.wikipedia.org&utm_campaign=index&utm_content=thumbnail',
                            width: 24,
                            height: 24,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Text('Z', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                          ),
                        ),
                        label: const Text(
                          'Chat Zalo',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: kPrimaryAccent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
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

  Widget _buildInfoCard({required IconData icon, required String title, required String value, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: kSubText, fontSize: 12)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomFeature(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: kSubText),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(color: kSubText, fontSize: 13)),
      ],
    );
  }
}
