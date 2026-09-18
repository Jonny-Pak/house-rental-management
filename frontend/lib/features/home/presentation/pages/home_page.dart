import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../../../core/network/api_client.dart';
import '../../../property/data/repositories/property_repository.dart';
import '../../../property/data/models/property_model.dart';
import '../../../property/presentation/pages/property_detail_page.dart';
import '../../../favorites/data/repositories/favorite_repository.dart';
import '../../../favorites/presentation/widgets/favorite_button.dart';
import '../widgets/property_filter_bottom_sheet.dart';
import '../cubit/home_cubit.dart';
import '../cubit/home_state.dart';

// ─── Design System Colors ─────────────────────────────────────────────
const kPrimaryDark   = Color(0xFF2C1D11); // Brown
const kPrimaryAccent = Color(0xFFD85D15); // Orange
const kBackground    = Color(0xFFFAF8F5); // Off-white
const kBorderColor   = Color(0xFFE8DED1); // Border
const kSubText       = Color(0xFF64748B); // Slate subtitle text
// ──────────────────────────────────────────────────────────────────────

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HomeCubit(PropertyRepository(GetIt.I<ApiClient>())),
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatefulWidget {
  const _HomeView();

  @override
  State<_HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<_HomeView> {
  @override
  void initState() {
    super.initState();
    // Ensure initial load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cubit = context.read<HomeCubit>();
      if (cubit.state.status == HomeStatus.initial) {
        cubit.fetchProperties();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      body: SafeArea(
        child: RefreshIndicator(
          color: kPrimaryAccent,
          onRefresh: () => context.read<HomeCubit>().fetchProperties(),
          child: CustomScrollView(
            slivers: [
              // 0. Top App Bar Header Section
              const _TopAppBarSliver(),

              // 1. Hero Header Section
              const _HeroHeaderSliver(),

              // 2. Section Title: Tin nổi bật + Filter Chips
              const _FeaturedHeaderSliver(),

              // 3. Featured Properties List/Grid
              const _PropertyListSliver(),

              // 4. Tools & Utilities Section
              const _ToolsAndUtilitiesSliver(),

              // Bottom padding sliver
              const SliverToBoxAdapter(
                child: SizedBox(height: 32),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────
// 0. Top App Bar Header Section
// ──────────────────────────────────────────────────────────────────────
class _TopAppBarSliver extends StatelessWidget {
  const _TopAppBarSliver();

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Container(
        color: const Color(0xFF2A1B0E),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Row(
          children: [
            // Brand Logo & Location Indicator
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: kPrimaryAccent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.home_work_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Thuê nhà Thành phố Hồ Chí Minh',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Row(
                      children: const [
                        Icon(Icons.location_on, color: kPrimaryAccent, size: 12),
                        SizedBox(width: 2),
                        Text(
                          'Thành phố Hồ Chí Minh, Việt Nam',
                          style: TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const Spacer(),
            // Notification Bell Button
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 20),
                onPressed: () {},
              ),
            ),
            const SizedBox(width: 8),
            // Profile / User Avatar
            const CircleAvatar(
              radius: 18,
              backgroundColor: kPrimaryAccent,
              child: Icon(Icons.person, color: Colors.white, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────
// 1. Hero Header Section
// ──────────────────────────────────────────────────────────────────────
class _HeroHeaderSliver extends StatelessWidget {
  const _HeroHeaderSliver();

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2A1B0E), Color(0xFF442A15)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            const Text(
              'Tìm kiếm nhà cho thuê giá rẻ',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 6),

            // Subtitle
            const Text(
              'Hàng ngàn tin đăng phòng trọ, nhà nguyên căn được cập nhật mỗi ngày',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),

            // Search Bar & Filter trigger
            BlocBuilder<HomeCubit, HomeState>(
              builder: (context, state) {
                final hasFilter = state.filters != null && state.filters!.isNotEmpty;

                return Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1F000000),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 12),
                      const Icon(Icons.search, color: kSubText, size: 20),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: TextField(
                          readOnly: true,
                          decoration: InputDecoration(
                            hintText: 'Tìm theo tên đường, quận/huyện...',
                            hintStyle: TextStyle(color: kSubText, fontSize: 13),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                      ),
                      // Search button
                      GestureDetector(
                        onTap: () async {
                          final filters = await showModalBottomSheet<Map<String, dynamic>?>(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.white,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                            ),
                            builder: (_) => FractionallySizedBox(
                              heightFactor: 0.85,
                              child: PropertyFilterBottomSheet(initialFilters: state.filters),
                            ),
                          );
                          if (filters != null && context.mounted) {
                            context
                                .read<HomeCubit>()
                                .fetchProperties(filters.isEmpty ? null : filters);
                          }
                        },
                        child: Container(
                          margin: const EdgeInsets.all(4),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: hasFilter ? kPrimaryDark : kPrimaryAccent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            children: [
                              Icon(
                                hasFilter ? Icons.tune : Icons.search,
                                color: Colors.white,
                                size: 18,
                              ),
                              if (hasFilter) ...[
                                const SizedBox(width: 4),
                                const Text(
                                  'Đã lọc',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 14),

            // Horizontal Scrollable Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: const [
                  _HeroQuickChip(label: 'Phòng trọ hôm nay', icon: Icons.bolt),
                  SizedBox(width: 8),
                  _HeroQuickChip(label: 'Nhà cho thuê hôm nay', icon: Icons.home),
                  SizedBox(width: 8),
                  _HeroQuickChip(label: 'Ở ghép hôm nay', icon: Icons.group),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroQuickChip extends StatelessWidget {
  final String label;
  final IconData icon;

  const _HeroQuickChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.amberAccent, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────
// 2. Section Title: Tin nổi bật + Filter Chips
// ──────────────────────────────────────────────────────────────────────
class _FeaturedHeaderSliver extends StatelessWidget {
  const _FeaturedHeaderSliver();

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title with Orange Accent Border
            Row(
              children: [
                Container(
                  width: 4,
                  height: 22,
                  decoration: BoxDecoration(
                    color: kPrimaryAccent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Tin nổi bật',
                  style: TextStyle(
                    color: kPrimaryDark,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Filter Chips Horizontal List
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: const [
                  _CategoryChip(label: 'Hôm nay', icon: Icons.today, selected: true),
                  SizedBox(width: 8),
                  _CategoryChip(label: 'Khu vực', icon: Icons.location_on_outlined, hasDropdown: true),
                  SizedBox(width: 8),
                  _CategoryChip(label: 'Sắp xếp', icon: Icons.swap_vert_rounded, hasDropdown: true),
                  SizedBox(width: 8),
                  _CategoryChip(label: 'Mới nhất', icon: Icons.fiber_new_outlined),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final bool hasDropdown;

  const _CategoryChip({
    required this.label,
    required this.icon,
    this.selected = false,
    this.hasDropdown = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: selected ? kPrimaryAccent.withValues(alpha: 0.12) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: selected ? kPrimaryAccent : kBorderColor,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: selected ? kPrimaryAccent : kSubText,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.bold : FontWeight.w500,
              color: selected ? kPrimaryAccent : kPrimaryDark,
            ),
          ),
          if (hasDropdown) ...[
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, size: 16, color: kSubText),
          ],
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────
// 3. Featured Properties List/Grid
// ──────────────────────────────────────────────────────────────────────
class _PropertyListSliver extends StatelessWidget {
  const _PropertyListSliver();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        if (state.status == HomeStatus.loading) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Center(
                child: CircularProgressIndicator(color: kPrimaryAccent),
              ),
            ),
          );
        }

        if (state.status == HomeStatus.error) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                  const SizedBox(height: 8),
                  Text(
                    'Lỗi: ${state.errorMessage}',
                    style: const TextStyle(color: kSubText),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryAccent,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => context.read<HomeCubit>().fetchProperties(),
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            ),
          );
        }

        if (state.status == HomeStatus.success) {
          if (state.properties.isEmpty) {
            return const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Center(
                  child: Text(
                    'Chưa có phòng trọ nào được đăng.',
                    style: TextStyle(color: kSubText),
                  ),
                ),
              ),
            );
          }

          return SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final property = state.properties[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: PropertyCard(property: property),
                  );
                },
                childCount: state.properties.length,
              ),
            ),
          );
        }

        return const SliverToBoxAdapter(child: SizedBox.shrink());
      },
    );
  }
}

// ─── Property Card Widget ─────────────────────────────────────────────
class PropertyCard extends StatelessWidget {
  final PropertyModel property;

  const PropertyCard({super.key, required this.property});

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
    final hasImage = property.imageUrls.isNotEmpty;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PropertyDetailPage(propertyId: property.id),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kBorderColor),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Stack (Image, Heart icon top-right, Price tag bottom-left)
            Stack(
              children: [
                SizedBox(
                  height: 190,
                  width: double.infinity,
                  child: hasImage
                      ? Image.network(
                          property.imageUrls.first,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: Colors.grey[200],
                            child: const Icon(Icons.broken_image, size: 40, color: Colors.grey),
                          ),
                        )
                      : Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.home_work_outlined, size: 50, color: Colors.grey),
                        ),
                ),

                // Price Tag (Bottom Left)
                Positioned(
                  bottom: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: kPrimaryDark,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Liên hệ giá',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),

                // Favorite Heart Button (Top Right)
                Positioned(
                  top: 8,
                  right: 8,
                  child: FavoriteButton(
                    propertyId: property.id,
                    repository: FavoriteRepository(GetIt.I<ApiClient>()),
                    initialIsFavorite: false,
                  ),
                ),
              ],
            ),

            // Property Details
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    property.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: kPrimaryDark,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Location & Type Chip
                  Row(
                    children: [
                      // Property Type Chip
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: kPrimaryAccent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: kPrimaryAccent.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          _propertyTypeLabel(property.propertyType),
                          style: const TextStyle(
                            color: kPrimaryAccent,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Location
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 14, color: kSubText),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                property.address,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: kSubText,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────
// 4. Tools & Utilities Section
// ──────────────────────────────────────────────────────────────────────
class _ToolsAndUtilitiesSliver extends StatelessWidget {
  const _ToolsAndUtilitiesSliver();

  @override
  Widget build(BuildContext context) {
    final tools = [
      {
        'title': 'Đăng tin mới',
        'subtitle': 'Đăng tin cho thuê nhanh',
        'icon': Icons.add_home_work_outlined,
        'color': kPrimaryAccent,
      },
      {
        'title': 'Tìm ở ghép',
        'subtitle': 'Kết nối người ở ghép',
        'icon': Icons.people_outline,
        'color': Colors.blue,
      },
      {
        'title': 'Tính chi phí thuê',
        'subtitle': 'Ước tính điện nước phòng',
        'icon': Icons.calculate_outlined,
        'color': Colors.green,
      },
      {
        'title': 'Hợp đồng mẫu',
        'subtitle': 'Mẫu hợp đồng pháp lý',
        'icon': Icons.description_outlined,
        'color': Colors.purple,
      },
    ];

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Title
            Row(
              children: [
                Container(
                  width: 4,
                  height: 22,
                  decoration: BoxDecoration(
                    color: kPrimaryAccent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Công cụ và tiện ích nổi bật',
                  style: TextStyle(
                    color: kPrimaryDark,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 2x2 Grid of Tools
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: tools.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2.3,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
              ),
              itemBuilder: (context, index) {
                final tool = tools[index];
                final iconColor = tool['color'] as Color;

                return Container(
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
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: iconColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          tool['icon'] as IconData,
                          color: iconColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tool['title'] as String,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: kPrimaryDark,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              tool['subtitle'] as String,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: kSubText,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
