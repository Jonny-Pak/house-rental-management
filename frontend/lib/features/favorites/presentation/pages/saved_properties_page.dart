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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Tin đã lưu', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: BlocBuilder<FavoriteCubit, FavoriteState>(
        builder: (context, state) {
          if (state.status == FavoriteStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.status == FavoriteStatus.error) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Lỗi: ${state.errorMessage}', style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 16),
                  ElevatedButton(
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
                  Icon(Icons.favorite_border, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Bạn chưa lưu tin nào',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Nhấn vào biểu tượng ♥ để lưu khu trọ yêu thích',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => context.read<FavoriteCubit>().fetchFavorites(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: state.properties.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
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

  @override
  Widget build(BuildContext context) {
    final favoriteRepo = FavoriteRepository(GetIt.I<ApiClient>());
    final hasImage = property.imageUrls.isNotEmpty;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PropertyDetailPage(propertyId: property.id)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                SizedBox(
                  height: 200,
                  width: double.infinity,
                  child: hasImage
                      ? Image.network(
                          property.imageUrls.first,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                        )
                      : Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.home, size: 50, color: Colors.grey),
                        ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: FavoriteButton(
                    propertyId: property.id,
                    repository: favoriteRepo,
                    initialIsFavorite: true,
                    onToggled: (isFav) {
                      if (!isFav) onUnfavorited();
                    },
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          property.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (property.propertyType.isNotEmpty)
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
                      const Icon(Icons.location_on, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          property.address,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
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
