import '../widgets/map_radius_controls.dart';
import '../../../listing/presentation/pages/search_location_page.dart';

import 'package:frontend/core/theme/app_colors.dart';

import '../../../listing/data/models/listing_filter.dart';
import '../../../listing/presentation/widgets/listing_filter_bar.dart';
import '../../../listing/presentation/pages/listing_browse_page.dart';
import '../../../listing/presentation/pages/listing_detail_page.dart';
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
  const ListingMapPage({
    super.key,
    this.initialFilter = const ListingFilter(),
    this.repository,
    this.locationService,
  });
  final ListingRepository? repository;
  final SearchLocationService? locationService;
  final ListingFilter initialFilter;

  @override
  State<ListingMapPage> createState() => _ListingMapPageState();
}

class _ListingMapPageState extends State<ListingMapPage>
    with WidgetsBindingObserver {
  late final HomeMapCubit _cubit;
  late final ListingRepository _repository;
  Timer? _refresh;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _repository = widget.repository ?? ListingRepository(ApiClient());
    _cubit = HomeMapCubit(_repository);
    _cubit.filter = widget.initialFilter;
    _cubit.fetchApprovedListings();
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
      child: _ListingMapPageContent(
        initialFilter: widget.initialFilter,
        repository: _repository,
        locationService: widget.locationService,
      ),
    );
  }
}

class _ListingMapPageContent extends StatefulWidget {
  const _ListingMapPageContent({
    required this.initialFilter,
    required this.repository,
    this.locationService,
  });
  final ListingRepository repository;
  final SearchLocationService? locationService;
  final ListingFilter initialFilter;
  @override
  State<_ListingMapPageContent> createState() => _ListingMapPageContentState();
}

class _ListingMapPageContentState extends State<_ListingMapPageContent> {
  late ListingFilter _filter = widget.initialFilter;
  final _mapController = MapController();
  bool _mapReady = false, _needsFit = true;
  bool _findingLocation = false;
  String? _locationError;
  late final _locations = widget.locationService ?? SearchLocationService();
  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _fit(List<Listing> listings) {
    if (!_mapReady) return;
    final points = _filter
        .apply(listings)
        .where(
          (l) =>
              l.latitude != null &&
              l.longitude != null &&
              l.latitude!.isFinite &&
              l.longitude!.isFinite &&
              l.latitude!.abs() <= 90 &&
              l.longitude!.abs() <= 180,
        )
        .map((l) => LatLng(l.latitude!, l.longitude!))
        .toList();
    if (_filter.hasRadius) {
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds.fromPoints([
            for (final bearing in [0.0, 90.0, 180.0, 270.0])
              const Distance().offset(
                _filter.center!,
                _filter.radiusKm! * 1000,
                bearing,
              ),
          ]),
          padding: const EdgeInsets.all(48),
          maxZoom: 16,
        ),
      );
      _needsFit = false;
      return;
    }
    if (points.isEmpty) return;
    _mapController.fitCamera(
      CameraFit.coordinates(
        coordinates: points,
        padding: const EdgeInsets.all(48),
        maxZoom: 16,
      ),
    );
    _needsFit = false;
  }

  void _changeFilter(ListingFilter filter) {
    final changed =
        _filter.center != filter.center || _filter.radiusKm != filter.radiusKm;
    setState(() {
      _filter = filter;
      _needsFit = true;
    });
    final cubit = context.read<HomeMapCubit>();
    cubit.filter = filter;
    if (changed) cubit.fetchApprovedListings();
    final state = cubit.state;
    if (state is HomeMapLoaded) _fit(state.listings);
  }

  void _toggleRadius() {
    if (_filter.hasRadius) {
      setState(() => _locationError = null);
      _changeFilter(_filter.withRadius());
      return;
    }
    if (!_mapReady) return;
    _setSearchCenter(_mapController.camera.center, 'Tâm bản đồ hiện tại');
  }

  void _setSearchCenter(LatLng point, String name) {
    if (!point.latitude.isFinite ||
        !point.longitude.isFinite ||
        point.latitude.abs() > 90 ||
        point.longitude.abs() > 180) {
      setState(
        () => _locationError = 'Vị trí không hợp lệ. Hãy chọn lại trên bản đồ.',
      );
      return;
    }
    setState(() => _locationError = null);
    _changeFilter(
      _filter.withRadius(
        center: point,
        centerName: name,
        radiusKm: _filter.radiusKm ?? 3,
      ),
    );
  }

  Future<void> _findCenter({String? address}) async {
    if (_findingLocation) return;
    final previousCenter = _filter.center;
    FocusScope.of(context).unfocus();
    setState(() {
      _findingLocation = true;
      _locationError = null;
    });
    try {
      final point = address == null
          ? await _locations.current()
          : await _locations.search(address);
      if (!mounted || !_filter.hasRadius || _filter.center != previousCenter) {
        return;
      }
      _setSearchCenter(point, address ?? 'Vị trí hiện tại');
    } catch (_) {
      if (mounted) {
        setState(
          () => _locationError = 'Không lấy được vị trí. Kiểm tra địa chỉ hoặc quyền GPS; bạn vẫn có thể chạm bản đồ để chọn tâm.',
        );
      }
    } finally {
      if (mounted) setState(() => _findingLocation = false);
    }
  }

  String _formatPrice(double price) {
    final format = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    );
    return format.format(price);
  }

  void _showListingDetail(BuildContext context, Listing listing) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      constraints: BoxConstraints(
        maxWidth: 560,
        maxHeight: MediaQuery.sizeOf(context).height * .85,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: listing.imageUrl?.isNotEmpty == true
                    ? Image.network(
                        listing.imageUrl!,
                        height: 170,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _buildPlaceholder(),
                      )
                    : _buildPlaceholder(),
              ),
              const SizedBox(height: 18),
              Text(
                listing.title,
                style: const TextStyle(
                  fontSize: 20,
                  height: 1.4,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 14,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    '${_formatPrice(listing.rentPrice)}/${listingRentUnit(listing.listingType)}',
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    '${NumberFormat.decimalPattern('vi_VN').format(listing.areaSqm)} m²',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Symbols.location_on,
                    size: 18,
                    color: AppColors.placeholder,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      listing.address ?? 'Chưa có địa chỉ',
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: AppColors.muted,
                      ),
                    ),
                  ),
                ],
              ),
              if (_filter.distanceKm(listing) != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(_filter.distanceLabel(listing)),
                ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ListingDetailPage(
                          listingId: listing.id,
                          repository: widget.repository,
                        ),
                      ),
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Xem chi tiết',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() => Container(
    height: 170,
    width: double.infinity,
    color: AppColors.primaryLight,
    child: const Center(
      child: Icon(Symbols.home_work, size: 50, color: AppColors.placeholder),
    ),
  );

  Widget _marker(Listing listing) => Tooltip(
    message: listing.title,
    child: Material(
      color: AppColors.primaryDark,
      shape: const CircleBorder(
        side: BorderSide(color: Colors.white, width: 2),
      ),
      elevation: 3,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: ValueKey('map-listing-${listing.id}'),
        onTap: () => _showListingDetail(context, listing),
        child: const Center(
          child: Icon(Symbols.home, size: 24, color: AppColors.primaryLight),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Bản đồ nhà cho thuê',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Xem danh sách',
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.muted,
              side: const BorderSide(color: AppColors.border),
            ),
            icon: const Icon(Symbols.list),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ListingBrowsePage(
                  title: 'Tin cho thuê',
                  initialFilter: _filter,
                  repository: widget.repository,
                ),
              ),
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Theme(
              data: Theme.of(context).copyWith(
                scaffoldBackgroundColor: AppColors.background,
                colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.primary,
                  secondaryContainer: AppColors.primaryLight,
                  onSecondaryContainer: AppColors.primaryDark,
                ),
                inputDecorationTheme: InputDecorationTheme(
                  filled: true,
                  fillColor: Colors.white,
                  hintStyle: const TextStyle(
                    fontSize: 13,
                    color: AppColors.muted,
                  ),
                  prefixIconColor: AppColors.muted,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                ),
                iconButtonTheme: IconButtonThemeData(
                  style: IconButton.styleFrom(
                    minimumSize: const Size(48, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              child: ListingFilterBar(
                filter: _filter,
                onChanged: _changeFilter,
              ),
            ),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: constraints.maxHeight * .45,
              ),
              child: SingleChildScrollView(
                primary: false,
                child: MapRadiusControls(
                  enabled: _filter.hasRadius,
                  centerName: _filter.centerName,
                  radiusKm: _filter.radiusKm ?? 3,
                  busy: _findingLocation,
                  error: _locationError,
                  onToggle: _toggleRadius,
                  onSearch: (address) => _findCenter(address: address),
                  onCurrentLocation: () => _findCenter(),
                  onRadiusChanged: (radius) => _changeFilter(
                    _filter.withRadius(
                      center: _filter.center,
                      centerName: _filter.centerName,
                      radiusKm: radius,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  BlocConsumer<HomeMapCubit, HomeMapState>(
                    listener: (_, state) {
                      if (_needsFit && state is HomeMapLoaded) {
                        _fit(state.listings);
                      }
                    },
                    builder: (context, state) {
                      List<Marker> markers = [];

                      if (state is HomeMapLoaded) {
                        markers = _filter
                            .apply(state.listings)
                            .where(
                              (item) =>
                                  item.latitude != null &&
                                  item.longitude != null &&
                                  item.latitude!.isFinite &&
                                  item.longitude!.isFinite &&
                                  item.latitude!.abs() <= 90 &&
                                  item.longitude!.abs() <= 180,
                            )
                            .map((item) {
                              return Marker(
                                point: LatLng(item.latitude!, item.longitude!),
                                width: 44,
                                height: 44,
                                child: _marker(item),
                              );
                            })
                            .toList();
                      }

                      return FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          onMapReady: () {
                            _mapReady = true;
                            final state = context.read<HomeMapCubit>().state;
                            if (state is HomeMapLoaded) _fit(state.listings);
                          },
                          initialCenter: LatLng(10.7769, 106.7009),
                          initialZoom: 13.0,
                          onTap: _filter.hasRadius && !_findingLocation
                              ? (_, point) => _setSearchCenter(
                                  point,
                                  'Điểm đã chọn trên bản đồ',
                                )
                              : null,
                        ),
                        children: [
                          const RentalMapTiles(),
                          if (_filter.hasRadius)
                            CircleLayer(
                              circles: [
                                CircleMarker(
                                  point: _filter.center!,
                                  radius: _filter.radiusKm! * 1000,
                                  useRadiusInMeter: true,
                                  color: const Color(0x2215803D),
                                  borderColor: AppColors.primary,
                                  borderStrokeWidth: 2,
                                ),
                              ],
                            ),
                          if (_filter.center != null)
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: _filter.center!,
                                  width: 36,
                                  height: 36,
                                  child: const Icon(
                                    Icons.my_location,
                                    color: AppColors.primary,
                                    size: 28,
                                  ),
                                ),
                              ],
                            ),
                          MarkerLayer(markers: markers),
                        ],
                      );
                    },
                  ),

                  Positioned(
                    top: 16,
                    right: 16,
                    bottom: 16,
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          FloatingActionButton.small(
                            heroTag: 'refresh-map',
                            tooltip: 'Làm mới bản đồ',
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.muted,
                            elevation: 2,
                            shape: const CircleBorder(),
                            onPressed: () => context
                                .read<HomeMapCubit>()
                                .fetchApprovedListings(),
                            child: const Icon(Symbols.refresh),
                          ),
                          const SizedBox(height: 12),
                          FloatingActionButton.small(
                            heroTag: 'manage-listings',
                            tooltip: 'Quản lý tin đăng',
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 2,
                            shape: const CircleBorder(),
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const MyListingsPage(),
                                ),
                              );
                              if (context.mounted) {
                                context
                                    .read<HomeMapCubit>()
                                    .fetchApprovedListings();
                              }
                            },
                            child: const Icon(Symbols.post_add),
                          ),
                        ],
                      ),
                    ),
                  ),

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
                            borderRadius: BorderRadius.circular(18),
                            color: const Color(0xFFAE5141),
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
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
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
            ),
            SafeArea(
              top: false,
              child: BlocBuilder<HomeMapCubit, HomeMapState>(
                builder: (_, state) {
                  if (state is! HomeMapLoaded) {
                    return const SizedBox.shrink();
                  }
                  final matches = _filter.apply(state.listings);
                  final count = matches
                      .where(
                        (l) =>
                            l.latitude != null &&
                            l.longitude != null &&
                            l.latitude!.isFinite &&
                            l.longitude!.isFinite &&
                            l.latitude!.abs() <= 90 &&
                            l.longitude!.abs() <= 180,
                      )
                      .length;
                  return Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(top: BorderSide(color: AppColors.border)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      child: Text(
                        count == 0
                            ? (matches.isEmpty
                                  ? 'Không có tin phù hợp. Hãy đổi từ khóa hoặc xóa bộ lọc.'
                                  : 'Tin phù hợp chưa có tọa độ. Xem trong danh sách.')
                            : '$count tin phù hợp trên bản đồ',
                        style: const TextStyle(
                          fontSize: 12,
                          height: 1.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
