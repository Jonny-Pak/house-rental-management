import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../../../core/network/api_client.dart';
import '../../../property/data/repositories/property_repository.dart';
import '../../../property/data/models/property_model.dart';
import '../../../property/presentation/pages/property_detail_page.dart';
import '../../../favorites/data/repositories/favorite_repository.dart';
import '../../../favorites/presentation/widgets/favorite_button.dart';

import '../../../property/presentation/cubit/property_browse_cubit.dart';


// ─── Design System Colors ─────────────────────────────────────────────
const kPrimaryDark   = Color(0xFF2C1D11); // Brown
const kPrimaryAccent = Color(0xFFD85D15); // Orange
const kBackground    = Color(0xFFFAF8F5); // Off-white
const kBorderColor   = Color(0xFFE8DED1); // Border
const kSubText       = Color(0xFF64748B); // Slate subtitle text
// ──────────────────────────────────────────────────────────────────────

class PropertyBrowsePage extends StatelessWidget {
  final String propertyType;
  final String title;

  const PropertyBrowsePage({super.key, required this.propertyType, required this.title});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PropertyBrowseCubit(PropertyRepository(GetIt.I<ApiClient>())),
      child: _HomeView(propertyType: propertyType, title: title),
    );
  }
}

class _HomeView extends StatefulWidget {
  final String propertyType;
  final String title;
  const _HomeView({required this.propertyType, required this.title});

  @override
  State<_HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<_HomeView> {
  @override
  void initState() {
    super.initState();
    // Ensure initial load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cubit = context.read<PropertyBrowseCubit>();
      if (cubit.state is PropertyBrowseInitial) {
        cubit.loadProperties(widget.propertyType);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: kPrimaryDark,
        elevation: 0,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: kPrimaryAccent,
          onRefresh: () => context.read<PropertyBrowseCubit>().loadProperties(widget.propertyType),
          child: CustomScrollView(
            slivers: [
              // 0. Top App Bar Header Section
              

              // 1. Hero Header Section
              

              // 2. Section Title: Tin nổi bật + Filter Chips
              

              // 3. Featured Properties List/Grid
              _PropertyListSliver(propertyType: widget.propertyType),

              // 4. Tools & Utilities Section
              

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
class _PropertyListSliver extends StatelessWidget {
  final String propertyType;
  const _PropertyListSliver({required this.propertyType});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PropertyBrowseCubit, PropertyBrowseState>(
      builder: (context, state) {
        if (state is PropertyBrowseLoading) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Center(
                child: CircularProgressIndicator(color: kPrimaryAccent),
              ),
            ),
          );
        }

        if (state is PropertyBrowseError) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                  const SizedBox(height: 8),
                  Text(
                    'Lỗi: ${state.message}',
                    style: const TextStyle(color: kSubText),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryAccent,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => context.read<PropertyBrowseCubit>().loadProperties(propertyType),
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            ),
          );
        }

        if (state is PropertyBrowseLoaded) {
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
