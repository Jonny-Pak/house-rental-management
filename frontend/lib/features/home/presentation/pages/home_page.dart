import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../../../core/network/api_client.dart';
import '../../../property/data/repositories/property_repository.dart';
import '../../../property/data/models/property_model.dart';
import '../../../property/presentation/pages/property_detail_page.dart';
import '../cubit/home_cubit.dart';
import '../cubit/home_state.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => HomeCubit(
        PropertyRepository(GetIt.I<ApiClient>()),
      ),
      child: const HomeView(),
    );
  }
}

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Tìm trọ nhanh chóng', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60.0),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              readOnly: true,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm khu vực, tên đường...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onTap: () {
                // TODO: Navigate to Search Page
              },
            ),
          ),
        ),
      ),
      body: BlocBuilder<HomeCubit, HomeState>(
        builder: (context, state) {
          if (state.status == HomeStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state.status == HomeStatus.error) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Lỗi: ${state.errorMessage}', style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<HomeCubit>().fetchProperties(),
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          } else if (state.status == HomeStatus.success) {
            if (state.properties.isEmpty) {
              return const Center(child: Text('Chưa có khu trọ nào được đăng.'));
            }

            return RefreshIndicator(
              onRefresh: () => context.read<HomeCubit>().fetchProperties(),
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: state.properties.length,
                separatorBuilder: (context, index) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  return PropertyCard(property: state.properties[index]);
                },
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class PropertyCard extends StatelessWidget {
  final PropertyModel property;

  const PropertyCard({super.key, required this.property});

  @override
  Widget build(BuildContext context) {
    final hasImage = property.imageUrls.isNotEmpty;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PropertyDetailPage(propertyId: property.id),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            SizedBox(
              height: 200,
              width: double.infinity,
              child: hasImage
                  ? Image.network(
                      property.imageUrls.first,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                    )
                  : Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.home, size: 50, color: Colors.grey),
                    ),
            ),
            
            // Details
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
