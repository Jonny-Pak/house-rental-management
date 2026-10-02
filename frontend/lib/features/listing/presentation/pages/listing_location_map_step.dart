import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../cubit/create_listing_cubit.dart';
import '../cubit/create_listing_state.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Design tokens
// ─────────────────────────────────────────────────────────────────────────────
const _kAccent     = Color(0xFFD85D15);
const _kDark       = Color(0xFF2C1D11);
const _kBackground = Color(0xFFFAF8F5);
const _kBorder     = Color(0xFFE8DED1);
const _kSubText    = Color(0xFF64748B);

// ─────────────────────────────────────────────────────────────────────────────
// Entry point
// ─────────────────────────────────────────────────────────────────────────────

class ListingLocationMapStep extends StatefulWidget {
  final VoidCallback? onConfirm;
  final VoidCallback? onBack;

  const ListingLocationMapStep({super.key, this.onConfirm, this.onBack});

  @override
  State<ListingLocationMapStep> createState() => _ListingLocationMapStepState();
}

class _ListingLocationMapStepState extends State<ListingLocationMapStep> {
  final _mapController = MapController();
  final _addressController = TextEditingController();

  // Default center: Đà Nẵng
  static const _defaultCenter = LatLng(16.0544, 108.2022);
  static const _defaultZoom   = 14.0;

  /// Whether the user is in polygon drawing mode (after placing the pin).
  bool _isDrawingMode = false;

  @override
  void initState() {
    super.initState();
    // Sync text field with cubit state
    final state = context.read<CreateListingCubit>().state;
    _addressController.text = state.address;
  }

  @override
  void dispose() {
    _mapController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _onMapTap(LatLng point) {
    final cubit = context.read<CreateListingCubit>();
    if (_isDrawingMode) {
      // In drawing mode, taps add polygon points
      cubit.addPolygonPoint(point);
    } else if (cubit.state.pinnedLocation != null) {
      // If pin is already placed, tap moves the pin
      cubit.updatePinnedLocation(point);
    }
  }

  void _enterDrawingMode() {
    setState(() => _isDrawingMode = true);
  }

  void _exitDrawingMode() {
    setState(() => _isDrawingMode = false);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CreateListingCubit, CreateListingState>(
      listenWhen: (prev, curr) =>
          prev.pinnedLocation != curr.pinnedLocation ||
          prev.address != curr.address,
      listener: (context, state) {
        // When pin is placed/changed, animate map to it
        if (state.pinnedLocation != null &&
            state.pinnedLocation != context.read<CreateListingCubit>().state.pinnedLocation) {
          // This won't trigger because listener fires AFTER state update.
          // We handle map animation in the builder instead.
        }
        // Sync address field
        if (_addressController.text != state.address) {
          _addressController.text = state.address;
        }
      },
      builder: (context, state) {
        final cubit = context.read<CreateListingCubit>();
        return Scaffold(
          backgroundColor: _kBackground,
          appBar: _buildAppBar(context),
          body: Stack(
            children: [
              // ── Full-screen Map ──────────────────────────────────────────
              Positioned.fill(child: _buildMap(state, cubit)),

              // ── Top: Search bar ──────────────────────────────────────────
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _buildSearchBar(context, state, cubit),
              ),

              // ── Right: Floating controls ─────────────────────────────────
              Positioned(
                top: 80,
                right: 16,
                child: _buildFloatingControls(context, state, cubit),
              ),

              // ── Drawing mode badge (top-left) ──────────────────────────
              if (_isDrawingMode)
                Positioned(
                  top: 80,
                  left: 16,
                  child: _buildDrawingBadge(state),
                ),

              // ── Bottom panel ─────────────────────────────────────────────
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _buildBottomPanel(context, state, cubit),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── AppBar ──────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: _kDark),
        onPressed: widget.onBack ?? () => Navigator.of(context).maybePop(),
      ),
      title: const Text(
        'Xác định vị trí & diện tích',
        style: TextStyle(color: _kDark, fontSize: 16, fontWeight: FontWeight.w700),
      ),
      centerTitle: false,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: _kBorder),
      ),
    );
  }

  // ── Search bar ──────────────────────────────────────────────────────────────

  Widget _buildSearchBar(BuildContext context, CreateListingState state, CreateListingCubit cubit) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          const Icon(Icons.search, color: _kSubText, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _addressController,
              onChanged: cubit.updateAddress,
              onSubmitted: (_) => cubit.searchAddress().then((_) => _animateToPin(cubit.state)),
              style: const TextStyle(fontSize: 14, color: _kDark),
              decoration: const InputDecoration(
                hintText: 'Nhập địa chỉ cho thuê...',
                hintStyle: TextStyle(color: _kSubText, fontSize: 14),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          // Search button
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: state.isSearching
                  ? null
                  : () => cubit.searchAddress().then((_) => _animateToPin(cubit.state)),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: _kAccent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: state.isSearching
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Tìm',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  void _animateToPin(CreateListingState state) {
    if (state.pinnedLocation != null) {
      _mapController.move(state.pinnedLocation!, 17.0);
    }
  }

  // ── Map ─────────────────────────────────────────────────────────────────────

  Widget _buildMap(CreateListingState state, CreateListingCubit cubit) {
    final points = state.polygonPoints;

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: state.pinnedLocation ?? _defaultCenter,
        initialZoom: state.pinnedLocation != null ? 17.0 : _defaultZoom,
        onTap: (_, latLng) => _onMapTap(latLng),
      ),
      children: [
        // ── Tile layer ─────────────────────────────────────────────────────
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          fallbackUrl: 'https://tile.openstreetmap.de/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.rental.management.app.v1',
          maxNativeZoom: 19,
        ),

        // ── Polygon layer (visible only when >= 3 points) ──────────────────
        if (points.length >= 3)
          PolygonLayer(
            polygons: [
              Polygon(
                points: points,
                color: _kAccent.withValues(alpha: 0.25),
                borderColor: _kAccent,
                borderStrokeWidth: 2.5,
              ),
            ],
          ),

        // ── Connecting line between points (< 3 points) ────────────────────
        if (points.length >= 2 && points.length < 3)
          PolylineLayer(
            polylines: [
              Polyline(points: points, color: _kAccent, strokeWidth: 2.0),
            ],
          ),

        // ── Polygon vertex markers ─────────────────────────────────────────
        if (points.isNotEmpty)
          MarkerLayer(
            markers: points.asMap().entries.map((entry) {
              final index = entry.key;
              final point = entry.value;
              final isFirst = index == 0;
              return Marker(
                point: point,
                width: isFirst ? 24 : 18,
                height: isFirst ? 24 : 18,
                child: Container(
                  decoration: BoxDecoration(
                    color: isFirst ? _kDark : _kAccent,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

        // ── Pinned location marker (big red pin) ──────────────────────────
        if (state.pinnedLocation != null)
          MarkerLayer(
            markers: [
              Marker(
                point: state.pinnedLocation!,
                width: 40,
                height: 40,
                alignment: Alignment.topCenter,
                child: const Icon(
                  Icons.location_on,
                  color: Colors.red,
                  size: 40,
                  shadows: [
                    Shadow(color: Colors.black38, blurRadius: 8, offset: Offset(0, 3)),
                  ],
                ),
              ),
            ],
          ),

        // ── Attribution ────────────────────────────────────────────────────
        const SimpleAttributionWidget(
          source: Text('© OpenStreetMap contributors', style: TextStyle(fontSize: 10)),
        ),
      ],
    );
  }

  // ── Floating controls ───────────────────────────────────────────────────────

  Widget _buildFloatingControls(
      BuildContext context, CreateListingState state, CreateListingCubit cubit) {
    return Column(
      children: [
        // GPS button
        _FloatingMapButton(
          icon: Icons.my_location_rounded,
          label: 'Vị trí hiện tại',
          onTap: state.isSearching
              ? null
              : () => cubit.useCurrentLocation().then((_) => _animateToPin(cubit.state)),
          color: Colors.blueAccent,
        ),

        // Separator
        if (state.pinnedLocation != null) ...[
          const SizedBox(height: 10),

          // Toggle drawing mode
          _FloatingMapButton(
            icon: _isDrawingMode ? Icons.edit_off_rounded : Icons.edit_rounded,
            label: _isDrawingMode ? 'Tắt vẽ' : 'Vẽ diện tích',
            onTap: _isDrawingMode ? _exitDrawingMode : _enterDrawingMode,
            color: _isDrawingMode ? Colors.green : _kAccent,
          ),
        ],

        if (_isDrawingMode && state.polygonPoints.isNotEmpty) ...[
          const SizedBox(height: 10),
          // Undo button
          _FloatingMapButton(
            icon: Icons.undo_rounded,
            label: 'Hoàn tác',
            onTap: cubit.undoLastPoint,
            color: _kDark,
          ),
          const SizedBox(height: 10),
          // Clear button
          _FloatingMapButton(
            icon: Icons.delete_forever_rounded,
            label: 'Xóa nháp',
            onTap: () => _showClearConfirmDialog(context, cubit),
            color: Colors.redAccent,
          ),
        ],
      ],
    );
  }

  void _showClearConfirmDialog(BuildContext context, CreateListingCubit cubit) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa toàn bộ điểm?'),
        content: const Text('Hành động này sẽ xóa tất cả điểm đã vẽ trên bản đồ.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              cubit.clearPolygon();
              Navigator.pop(ctx, true);
            },
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  // ── Drawing mode badge ──────────────────────────────────────────────────────

  Widget _buildDrawingBadge(CreateListingState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            'Đang vẽ · ${state.polygonPoints.length} điểm',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _kDark),
          ),
          if (state.hasPolygon) ...[
            const SizedBox(width: 6),
            const Icon(Icons.check_circle, size: 14, color: Colors.green),
          ],
        ],
      ),
    );
  }

  // ── Bottom panel ────────────────────────────────────────────────────────────

  Widget _buildBottomPanel(
      BuildContext context, CreateListingState state, CreateListingCubit cubit) {
    final hasPin = state.pinnedLocation != null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Drag handle ──────────────────────────────────────────────
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // ── Status / hint ────────────────────────────────────────────
              if (!hasPin)
                _buildHintCard(
                  icon: Icons.search_rounded,
                  text: 'Nhập địa chỉ phía trên rồi ấn "Tìm" để ghim vị trí lên bản đồ.',
                  color: _kAccent,
                )
              else if (!_isDrawingMode)
                _buildHintCard(
                  icon: Icons.touch_app_rounded,
                  text: 'Nhấn vào bản đồ để đổi vị trí ghim, hoặc bấm bút vẽ  ✏️  để vẽ diện tích.',
                  color: Colors.blueAccent,
                )
              else if (!state.hasPolygon)
                _buildHintCard(
                  icon: Icons.edit_rounded,
                  text: 'Nhấn vào bản đồ để thêm điểm. Cần ≥ 3 điểm để vẽ vùng đất.',
                  color: Colors.green,
                ),

              // ── Area display (when polygon is drawn) ────────────────────
              if (state.hasPolygon) ...[
                Row(
                  children: [
                    Expanded(
                      child: _InfoChip(
                        icon: Icons.square_foot_rounded,
                        label: 'Diện tích',
                        value: '${state.calculatedArea.toStringAsFixed(1)} m²',
                        highlight: true,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _InfoChip(
                        icon: Icons.place_rounded,
                        label: 'Số điểm',
                        value: '${state.polygonPoints.length} điểm đã vẽ',
                        highlight: false,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],

              // ── Address display ─────────────────────────────────────────
              if (hasPin && state.address.isNotEmpty) ...[
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: _kAccent),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        state.address,
                        style: const TextStyle(fontSize: 13, color: _kDark),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],

              // ── Confirm button ─────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton.icon(
                  onPressed: _canConfirm(state) ? _onConfirm : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: _kAccent,
                    disabledBackgroundColor: Colors.grey.shade300,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                  icon: const Icon(Icons.check_circle_outline_rounded, size: 20),
                  label: const Text(
                    'Xác nhận vị trí',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHintCard({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 12, color: color),
            ),
          ),
        ],
      ),
    );
  }

  bool _canConfirm(CreateListingState state) =>
      state.pinnedLocation != null && state.address.trim().isNotEmpty;

  void _onConfirm() {
    FocusScope.of(context).unfocus();
    widget.onConfirm?.call();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper widgets
// ─────────────────────────────────────────────────────────────────────────────

class _FloatingMapButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color color;

  const _FloatingMapButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Tooltip(
      message: label,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedOpacity(
          opacity: enabled ? 1.0 : 0.4,
          duration: const Duration(milliseconds: 200),
          child: Container(
            width: 44,
            height: 44,
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
            child: Icon(icon, color: color, size: 20),
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool highlight;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.highlight,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = highlight ? _kAccent.withValues(alpha: 0.08) : Colors.grey.shade50;
    final borderColor = highlight ? _kAccent.withValues(alpha: 0.3) : _kBorder;
    final textColor = highlight ? _kAccent : _kDark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 10, color: _kSubText)),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
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
}
