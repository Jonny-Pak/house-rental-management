import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../../../core/network/api_client.dart';
import '../../../property/data/models/property_model.dart';
import '../../../property/presentation/pages/property_detail_page.dart';
import '../../data/repositories/favorite_repository.dart';
import '../cubit/favorite_cubit.dart';
import '../cubit/favorite_state.dart';
import '../widgets/favorite_button.dart';

// ─── Design System Colors ─────────────────────────────────────────────
const kPrimaryDark   = Color(0xFF2C1D11);
const kPrimaryAccent = Color(0xFFD85D15);
const kBackground    = Color(0xFFFAF8F5);
const kBorderColor   = Color(0xFFE8DED1);
const kSubText       = Color(0xFF64748B);
// ──────────────────────────────────────────────────────────────────────

class SavedPropertiesPage extends StatelessWidget {
  const SavedPropertiesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => FavoriteCubit(
        FavoriteRepository(GetIt.I<ApiClient>()),
      )..fetchFavorites(),
      child: const _SavedPropertiesView(),
    );
  }
}

class _SavedPropertiesView extends StatelessWidget {
  const _SavedPropertiesView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        backgroundColor: kBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: kPrimaryDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Tin đã lưu',
          style: TextStyle(
            color: kPrimaryDark,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: BlocBuilder<FavoriteCubit, FavoriteState>(
        builder: (context, state) {
          if (state.status == FavoriteStatus.loading) {
            return const Center(child: CircularProgressIndicator(color: kPrimaryAccent));
          }

          if (state.status == FavoriteStatus.error) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
                  const SizedBox(height: 16),
                  Text('Lỗi: ${state.errorMessage}', style: const TextStyle(color: kSubText)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryAccent,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => context.read<FavoriteCubit>().fetchFavorites(),
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          if (state.status == FavoriteStatus.success && state.properties.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: kPrimaryAccent.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.favorite_border_rounded, size: 64, color: kPrimaryAccent),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Bạn chưa lưu tin nào',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: kPrimaryDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Nhấn vào biểu tượng trái tim\nđể lưu khu trọ yêu thích nhé',
                    style: TextStyle(color: kSubText, fontSize: 14, height: 1.5),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: kPrimaryAccent,
            onRefresh: () async {
              context.read<FavoriteCubit>().fetchFavorites();
            },
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              itemCount: state.properties.length,
              separatorBuilder: (_, _) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final property = state.properties[index];
                return _SavedPropertyCard(
                  property: property,
                  onUnfavorited: () {
                    // Refresh the list after un-favoriting
                    context.read<FavoriteCubit>().fetchFavorites();
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _SavedPropertyCard extends StatelessWidget {
  final PropertyModel property;
  final VoidCallback onUnfavorited;

  const _SavedPropertyCard({required this.property, required this.onUnfavorited});

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
    final favoriteRepo = FavoriteRepository(GetIt.I<ApiClient>());
    final hasImage = property.imageUrls.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorderColor),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PropertyDetailPage(propertyId: property.id)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section
            Stack(
              children: [
                SizedBox(
                  height: 180,
                  width: double.infinity,
                  child: hasImage
                      ? Image.network(
                          property.imageUrls.first,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              const Icon(Icons.broken_image_outlined, size: 48, color: Colors.grey),
                        )
                      : Container(
                          color: kBackground,
                          child: const Icon(Icons.home_work_outlined, size: 48, color: Colors.grey),
                        ),
                ),
                // Gradient for favorite button visibility
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 60,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.4),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    child: FavoriteButton(
                      propertyId: property.id,
                      repository: favoriteRepo,
                      initialIsFavorite: true,
                      onToggled: (isFav) {
                        if (!isFav) onUnfavorited();
                      },
                    ),
                  ),
                ),
                // Type Badge
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: kPrimaryAccent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _propertyTypeLabel(property.propertyType),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            // Content Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    property.name,
                    style: const TextStyle(
                      color: kPrimaryDark,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on_outlined, size: 16, color: kSubText),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          property.address,
                          style: const TextStyle(color: kSubText, fontSize: 13, height: 1.4),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
