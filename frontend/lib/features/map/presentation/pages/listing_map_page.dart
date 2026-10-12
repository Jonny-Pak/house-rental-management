import '../widgets/rental_map_tiles.dart';

import 'package:flutter/material.dart';

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/network/api_client.dart';
import '../../../listing/data/repositories/listing_repository.dart';
import '../../../listing/data/models/listing_model.dart';
import '../../../home/presentation/cubit/home_map_cubit.dart';

import 'package:material_symbols_icons/symbols.dart';

import '../../../listing/presentation/pages/my_listings_page.dart';

class ListingMapPage extends StatefulWidget {
  const ListingMapPage({super.key});

  @override
  State<ListingMapPage> createState() => _ListingMapPageState();
}

class _ListingMapPageState extends State<ListingMapPage>
    with WidgetsBindingObserver {
  late final HomeMapCubit _cubit;
  Timer? _refresh;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _cubit = HomeMapCubit(ListingRepository(ApiClient()))
      ..fetchApprovedListings();
    _startRefresh();
  }

  void _startRefresh() {
    _refresh?.cancel();
    _refresh = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _cubit.fetchApprovedListings(silent: true),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _cubit.fetchApprovedListings(silent: true);
      _startRefresh();
    } else {
      _refresh?.cancel();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refresh?.cancel();
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: const _ListingMapPageContent(),
    );
  }
}

class _ListingMapPageContent extends StatelessWidget {
  const _ListingMapPageContent();

  // Định dạng tiền tệ VND
  String _formatPrice(double price) {
    final format = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    );
    return format.format(price);
  }

  // Hiển thị Bottom Sheet chi tiết bài đăng
  void _showListingDetail(BuildContext context, Listing listing) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ảnh đầu tiên (nếu có) hoặc placeholder
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: listing.imageUrl != null && listing.imageUrl!.isNotEmpty
                    ? Image.network(
                        listing.imageUrl!,
                        height: 140,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildPlaceholder(),
                      )
                    : _buildPlaceholder(),
              ),
              const SizedBox(height: 12),

              // Tiêu đề
              Text(
                listing.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),

              // Giá thuê và Diện tích
              Row(
                children: [
                  Text(
                    _formatPrice(listing.rentPrice),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    '${listing.areaSqm} m²',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Nút xem chi tiết
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Xem chi tiết'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      height: 140,
      width: double.infinity,
      color: Colors.grey.shade200,
      child: const Center(
        child: Icon(Symbols.home, size: 50, color: Colors.grey),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bản đồ nhà cho thuê')),
      body: Stack(
        children: [
          // Bản đồ toàn màn hình
          BlocBuilder<HomeMapCubit, HomeMapState>(
            builder: (context, state) {
              List<Marker> markers = [];

              if (state is HomeMapLoaded) {
                markers = state.listings
                    .where(
                      (item) => item.latitude != null && item.longitude != null,
                    )
                    .map((item) {
                      return Marker(
                        point: LatLng(item.latitude!, item.longitude!),
                        width: 40,
                        height: 40,
                        child: GestureDetector(
                          onTap: () => _showListingDetail(context, item),
                          child: const Icon(
                            Symbols.location_on,
                            color: Colors.red,
                            size: 40,
                          ),
                        ),
                      );
                    })
                    .toList();
              }

              return FlutterMap(
                options: const MapOptions(
                  initialCenter: LatLng(
                    10.7769,
                    106.7009,
                  ), // Tọa độ mặc định TP.HCM
                  initialZoom: 13.0,
                ),
                children: [
                  const RentalMapTiles(),
                  MarkerLayer(markers: markers),
                ],
              );
            },
          ),

          Positioned(
            top: 48,
            right: 12,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'refresh-map',
                  onPressed: () =>
                      context.read<HomeMapCubit>().fetchApprovedListings(),
                  child: const Icon(Symbols.refresh),
                ),
                const SizedBox(height: 12),
                FloatingActionButton.small(
                  heroTag: 'manage-listings',
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MyListingsPage()),
                    );
                    if (context.mounted) {
                      context.read<HomeMapCubit>().fetchApprovedListings();
                    }
                  },
                  child: const Icon(Symbols.post_add),
                ),
              ],
            ),
          ),

          // Trạng thái đang tải (Loading)
          BlocBuilder<HomeMapCubit, HomeMapState>(
            builder: (context, state) {
              if (state is HomeMapLoading) {
                return const Center(
                  child: Card(
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                );
              }
              if (state is HomeMapError) {
                return Positioned(
                  top: 50,
                  left: 20,
                  right: 20,
                  child: Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.redAccent,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              state.message,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Symbols.refresh,
                              color: Colors.white,
                            ),
                            onPressed: () => context
                                .read<HomeMapCubit>()
                                .fetchApprovedListings(),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }
}
