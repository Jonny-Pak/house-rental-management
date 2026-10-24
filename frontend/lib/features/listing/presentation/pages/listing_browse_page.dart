import '../../../../core/layout/app_layout.dart';
import '../../../map/presentation/pages/listing_map_page.dart';
import '../../data/models/listing_filter.dart';
import '../widgets/listing_filter_bar.dart';
import 'listing_detail_page.dart';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/network/api_client.dart';
import '../../data/models/listing_model.dart';
import '../../data/repositories/listing_repository.dart';

class ListingBrowsePage extends StatefulWidget {
  const ListingBrowsePage({
    super.key,
    required this.title,
    this.listingType,
    this.autofocus = false,
    this.repository,
    this.initialFilter,
  });
  final String title;
  final String? listingType;
  final bool autofocus;
  final ListingRepository? repository;
  final ListingFilter? initialFilter;
  @override
  State<ListingBrowsePage> createState() => _ListingBrowsePageState();
}

class _ListingBrowsePageState extends State<ListingBrowsePage> {
  late final ListingRepository _repository;
  late ListingFilter _filter;
  List<Listing> _items = [];
  String? _error;
  bool _loading = true;
  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? ListingRepository(ApiClient());
    _filter =
        widget.initialFilter ?? ListingFilter(listingType: widget.listingType);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await _repository.fetchApprovedListings();
      if (mounted) setState(() => _items = items);
    } catch (e) {
      if (mounted) setState(() => _error = ListingRepository.errorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _price(Listing l) =>
      '${NumberFormat.decimalPattern('vi_VN').format(l.rentPrice)} đ/${listingRentUnit(l.listingType)}';
  void _detail(Listing listing) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ListingDetailPage(listingId: listing.id, repository: _repository),
      ),
    );
  }

  Widget _card(Listing listing) => Material(
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(24),
      side: const BorderSide(color: Color(0xFFEEDFD1)),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: () => _detail(listing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: 180, child: _photo(listing)),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  listing.title,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.4,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF38291F),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _price(listing),
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFD76B28),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Symbols.location_on,
                      size: 17,
                      color: Color(0xFFAA998A),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        listing.address ?? 'Chưa có địa chỉ',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          height: 1.5,
                          color: Color(0xFF8A7464),
                        ),
                      ),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Divider(height: 1, color: Color(0xFFF3ECE4)),
                ),
                Wrap(
                  spacing: 16,
                  runSpacing: 10,
                  children: [
                    _info(
                      Symbols.square_foot,
                      '${NumberFormat.decimalPattern('vi_VN').format(listing.areaSqm)} m²',
                    ),
                    if (listing.listingType != null)
                      _info(
                        Symbols.home_work,
                        listingTypeLabel(listing.listingType),
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

  Widget _photo(Listing listing) {
    const fallback = ColoredBox(
      color: Color(0xFFFFF0E1),
      child: Center(
        child: Icon(Symbols.home_work, size: 52, color: Color(0xFFC99D74)),
      ),
    );
    if (listing.imageUrl == null || listing.imageUrl!.isEmpty) {
      return fallback;
    }
    return Image.network(
      listing.imageUrl!,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => fallback,
    );
  }

  Widget _info(IconData icon, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 17, color: const Color(0xFFAD8A68)),
      const SizedBox(width: 5),
      Flexible(
        child: Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF8A7464)),
        ),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final items = _filter.apply(_items);
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAF8F5),
        surfaceTintColor: Colors.transparent,
        title: Text(
          widget.title,
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w700,
            color: Color(0xFF38291F),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              tooltip: 'Xem trên bản đồ',
              style: IconButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF8A7464),
                side: const BorderSide(color: Color(0xFFEEDFD1)),
              ),
              icon: const Icon(Symbols.map, size: 22),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ListingMapPage(initialFilter: _filter),
                ),
              ),
            ),
          ),
        ],
      ),
      body: AppContent(
        maxWidth: AppLayout.contentWidth,
        child: Column(
          children: [
            Theme(
              data: theme.copyWith(
                scaffoldBackgroundColor: const Color(0xFFFAF8F5),
                colorScheme: theme.colorScheme.copyWith(
                  primary: const Color(0xFFD76B28),
                  secondaryContainer: const Color(0xFFFFEBD9),
                  onSecondaryContainer: const Color(0xFFAF541E),
                ),
                inputDecorationTheme: InputDecorationTheme(
                  filled: true,
                  fillColor: Colors.white,
                  hintStyle: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFFAA998A),
                  ),
                  prefixIconColor: const Color(0xFF8A7464),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: const BorderSide(color: Color(0xFFEEDFD1)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: const BorderSide(color: Color(0xFFEEDFD1)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: const BorderSide(color: Color(0xFFD76B28)),
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
                autofocus: widget.autofocus,
                onChanged: (filter) => setState(() => _filter = filter),
              ),
            ),
            if (!_loading && _error == null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: Row(
                  children: [
                    const Icon(
                      Symbols.home_work,
                      size: 18,
                      color: Color(0xFFC88B53),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${items.length} tin phù hợp',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF573B28),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFD76B28),
                      ),
                    )
                  : _error != null
                  ? Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Symbols.cloud_off,
                              size: 38,
                              color: Color(0xFFAD8A68),
                            ),
                            const SizedBox(height: 12),
                            Text(_error!, textAlign: TextAlign.center),
                            TextButton(
                              onPressed: _load,
                              child: const Text('Thử lại'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          if (items.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 40,
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Symbols.search_off,
                                    size: 48,
                                    color: Color(0xFFC99D74),
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'Không có tin phù hợp. Hãy đổi từ khóa hoặc xóa bộ lọc.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                      height: 1.5,
                                      color: Color(0xFF8A7464),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ResponsiveCards(
                            children: [
                              for (final listing in items) _card(listing),
                            ],
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
