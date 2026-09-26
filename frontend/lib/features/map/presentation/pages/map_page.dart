import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/network/api_client.dart';
import '../../data/models/map_listing_model.dart';
import '../../data/repositories/map_listing_repository.dart';
import '../cubit/map_cubit.dart';
import '../cubit/map_state.dart';

// ─────────────────────────────────────────────
// Design tokens (match the rest of the app)
// ─────────────────────────────────────────────
const _kAccent = Color(0xFFD85D15);
const _kDark = Color(0xFF2C1D11);
const _kBackground = Color(0xFFFAF8F5);

/// Entry-point: wraps the page in its own BlocProvider so it can be pushed
/// from any Navigator.push() without needing a parent BlocProvider.
class MapPage extends StatelessWidget {
  const MapPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Resolve dependencies locally – consistent with how HomeCubit is wired
    // in this project (no global BlocProvider for the map feature yet).
    final apiClient = context.read<ApiClient?>() ?? ApiClient();
    final repository = MapListingRepository(apiClient);

    return BlocProvider(
      create: (_) => MapCubit(repository),
      child: const _MapView(),
    );
  }
}

// ─────────────────────────────────────────────
// Internal stateful view
// ─────────────────────────────────────────────
class _MapView extends StatefulWidget {
  const _MapView();

  @override
  State<_MapView> createState() => _MapViewState();
}

class _MapViewState extends State<_MapView> {
  static const _daNang = LatLng(16.0544, 108.2022);
  static const _initialZoom = 13.0;

  final _mapController = MapController();

  // Track the currently selected listing for the bottom sheet
  MapListingModel? _selectedListing;

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  // ── helpers ──────────────────────────────────

  void _onMapMoved(MapCamera camera, bool hasGesture) {
    // Only fire after a real user gesture, not programmatic moves.
    if (!hasGesture) return;
    final bounds = camera.visibleBounds;
    context.read<MapCubit>().fetchListingsInArea(
          bounds.south,
          bounds.west,
          bounds.north,
          bounds.east,
        );
  }

  void _showListingSheet(MapListingModel listing) {
    setState(() => _selectedListing = listing);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ListingBottomSheet(listing: listing),
    ).whenComplete(() {
      if (mounted) setState(() => _selectedListing = null);
    });
  }

  // ── build ─────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(context),
      body: Stack(
        children: [
          // ── Map ────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _daNang,
              initialZoom: _initialZoom,
              onMapReady: () {
                // Fetch initial viewport on first load
                final bounds = _mapController.camera.visibleBounds;
                context.read<MapCubit>().fetchListingsInArea(
                      bounds.south,
                      bounds.west,
                      bounds.north,
                      bounds.east,
                    );
              },
              onPositionChanged: _onMapMoved,
            ),
            children: [
              // ── Tile Layer ─────────────────────
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                fallbackUrl: 'https://tile.openstreetmap.de/{z}/{x}/{y}.png', // Alternative OSM server if main is blocked
                userAgentPackageName: 'com.rental.management.app.v1', // Use a unique User-Agent to prevent OSM CDN blocking (Connection refused 111)
                maxNativeZoom: 19,
              ),

              // ── Marker Layer ───────────────────
              BlocBuilder<MapCubit, MapState>(
                builder: (context, state) {
                  if (state.listings.isEmpty) return const SizedBox.shrink();
                  return MarkerLayer(
                    markers: state.listings
                        .map((l) => _buildMarker(l))
                        .toList(),
                  );
                },
              ),
            ],
          ),

          // ── Loading indicator ──────────────────
          BlocBuilder<MapCubit, MapState>(
            buildWhen: (prev, curr) => prev.status != curr.status,
            builder: (context, state) {
              if (state.status != MapStatus.loading) {
                return const SizedBox.shrink();
              }
              return Positioned(
                top: kToolbarHeight + MediaQuery.of(context).padding.top + 16,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.10),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: _kAccent,
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Đang tải...',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _kDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          // ── Attribution chip ───────────────────
          Positioned(
            bottom: 8,
            right: 8,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                '© OpenStreetMap contributors',
                style: TextStyle(fontSize: 10, color: Colors.black54),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── AppBar ─────────────────────────────────────
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.arrow_back, color: _kDark),
          ),
        ),
      ),
      title: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.location_on, color: _kAccent, size: 16),
            SizedBox(width: 6),
            Text(
              'Bản đồ phòng trọ',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _kDark,
              ),
            ),
          ],
        ),
      ),
      centerTitle: true,
    );
  }

  // ── Price-tag marker ───────────────────────────
  Marker _buildMarker(MapListingModel listing) {
    final isSelected = _selectedListing?.id == listing.id;
    return Marker(
      width: 80,
      height: 44,
      point: LatLng(listing.latitude, listing.longitude),
      child: GestureDetector(
        onTap: () => _showListingSheet(listing),
        child: _PriceTagMarker(
          price: listing.formattedPrice,
          isSelected: isSelected,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Price-tag marker widget
// ─────────────────────────────────────────────
class _PriceTagMarker extends StatelessWidget {
  final String price;
  final bool isSelected;

  const _PriceTagMarker({
    required this.price,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isSelected ? _kDark : _kAccent;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Pill ──────────────────────────────
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          transform: isSelected
              ? Matrix4.diagonal3Values(1.12, 1.12, 1.0)
              : Matrix4.identity(),
          transformAlignment: Alignment.center,
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: bgColor.withValues(alpha: 0.45),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Text(
            price,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),
        ),
        // ── Downward triangle ─────────────────
        CustomPaint(
          size: const Size(12, 6),
          painter: _TrianglePainter(color: bgColor),
        ),
      ],
    );
  }
}

/// Draws the small downward-pointing triangle below the pill.
class _TrianglePainter extends CustomPainter {
  final Color color;
  const _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = ui.Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_TrianglePainter oldDelegate) =>
      oldDelegate.color != color;
}

// ─────────────────────────────────────────────
// Bottom sheet shown on marker tap
// ─────────────────────────────────────────────
class _ListingBottomSheet extends StatelessWidget {
  final MapListingModel listing;

  const _ListingBottomSheet({required this.listing});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Handle ─────────────────────────────
          const _SheetHandle(),

          // ── Image placeholder ───────────────────
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
            child: Container(
              height: 160,
              width: double.infinity,
              color: _kAccent.withValues(alpha: 0.08),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Generic hero image for demonstration
                  Image.network(
                    'https://images.unsplash.com/photo-1560518883-ce09059eeffa'
                    '?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const Center(
                      child: Icon(Icons.image_not_supported,
                          size: 48, color: Colors.black26),
                    ),
                  ),
                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.35),
                        ],
                      ),
                    ),
                  ),
                  // Price badge overlay
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _kAccent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${listing.formattedPrice}/tháng',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Content ─────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  listing.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _kDark,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on,
                        size: 14, color: _kAccent),
                    const SizedBox(width: 4),
                    Text(
                      '${listing.latitude.toStringAsFixed(4)}, '
                      '${listing.longitude.toStringAsFixed(4)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kAccent,
                      foregroundColor: Colors.white,
                      padding:
                          const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'Xem chi tiết',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
