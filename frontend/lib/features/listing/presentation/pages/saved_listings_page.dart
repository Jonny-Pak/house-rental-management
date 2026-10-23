import '../../../../core/layout/app_layout.dart';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/network/api_client.dart';
import '../../../favorites/presentation/pages/saved_properties_page.dart';
import '../../data/models/listing_model.dart';
import '../../data/repositories/listing_repository.dart';
import 'listing_detail_page.dart';

class SavedListingsPage extends StatefulWidget {
  const SavedListingsPage({super.key, this.repository});
  final ListingRepository? repository;
  @override
  State<SavedListingsPage> createState() => _SavedListingsPageState();
}

class _SavedListingsPageState extends State<SavedListingsPage> {
  late final _repository = widget.repository ?? ListingRepository(ApiClient());
  List<Listing> _items = [];
  bool _loading = true;
  String? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await _repository.fetchSavedListings();
      if (mounted) setState(() => _items = items);
    } catch (e) {
      if (mounted) setState(() => _error = ListingRepository.errorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _remove(Listing listing) async {
    try {
      await _repository.setFavorite(listing.id, false);
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ListingRepository.errorMessage(e))),
        );
      }
    }
  }

  Future<void> _open(Listing listing) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ListingDetailPage(listingId: listing.id, repository: _repository),
      ),
    );
    if (mounted) await _load();
  }

  Widget _photo(Listing listing) {
    const placeholder = ColoredBox(
      color: Color(0xFFFFF0E1),
      child: Center(
        child: Icon(Symbols.home_work, size: 48, color: Color(0xFFC99D74)),
      ),
    );
    if (listing.imageUrl == null || listing.imageUrl!.isEmpty) {
      return placeholder;
    }
    return Image.network(
      listing.imageUrl!,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => placeholder,
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
      onTap: () => _open(listing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 170,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _photo(listing),
                Positioned(
                  top: 10,
                  right: 10,
                  child: IconButton(
                    tooltip: 'Bỏ lưu tin',
                    onPressed: () => _remove(listing),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFFC2695D),
                      minimumSize: const Size(44, 44),
                    ),
                    icon: const Icon(Symbols.favorite, fill: 1, size: 22),
                  ),
                ),
              ],
            ),
          ),
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
                  '${NumberFormat.decimalPattern('vi_VN').format(listing.rentPrice)} đ/${listingRentUnit(listing.listingType)}',
                  style: const TextStyle(
                    fontSize: 18,
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
                      size: 16,
                      color: Color(0xFFAD8A68),
                    ),
                    const SizedBox(width: 5),
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
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1, color: Color(0xFFF3ECE4)),
                ),
                Row(
                  children: [
                    const Icon(
                      Symbols.square_foot,
                      size: 17,
                      color: Color(0xFFAD8A68),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${NumberFormat.decimalPattern('vi_VN').format(listing.areaSqm)} m²',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF8A7464),
                        ),
                      ),
                    ),
                    const Icon(
                      Symbols.arrow_forward,
                      size: 18,
                      color: Color(0xFFC3976C),
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

  Widget _emptyState() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: const Color(0xFFEEDFD1)),
    ),
    child: const Column(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundColor: Color(0xFFFFF0E9),
          child: Icon(Symbols.favorite, size: 38, color: Color(0xFFC98C7E)),
        ),
        SizedBox(height: 20),
        Text(
          'Lưu lại nơi bạn muốn gọi là nhà',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            height: 1.4,
            fontWeight: FontWeight.w700,
            color: Color(0xFF38291F),
          ),
        ),
        SizedBox(height: 10),
        Text(
          'Chưa có tin yêu thích đang cho thuê. Hãy mở một tin và nhấn biểu tượng trái tim.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, height: 1.6, color: Color(0xFF8A7464)),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFFAF8F5),
    appBar: AppBar(
      backgroundColor: const Color(0xFFFAF8F5),
      surfaceTintColor: Colors.transparent,
      title: const Text(
        'Tin yêu thích',
        style: TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.w700,
          color: Color(0xFF38291F),
        ),
      ),
      actions: [
        IconButton(
          tooltip: 'Làm mới',
          onPressed: _loading ? null : _load,
          style: IconButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF8A7464),
            side: const BorderSide(color: Color(0xFFEEDFD1)),
          ),
          icon: const Icon(Symbols.refresh, size: 21),
        ),
      ],
    ),
    body: AppContent(
      maxWidth: AppLayout.contentWidth,
      child: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFD76B28)),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                children: [
                  if (_error == null) ...[
                    Text(
                      '${_items.length} tin đã lưu · Không gian bạn yêu thích',
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.5,
                        color: Color(0xFF8A7464),
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],
                  Material(
                    color: const Color(0xFFFFF0E1),
                    borderRadius: BorderRadius.circular(18),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SavedPropertiesPage(),
                        ),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(
                              Symbols.home_work,
                              size: 26,
                              color: Color(0xFFC08852),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Xem khu trọ đã lưu',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF573B28),
                                ),
                              ),
                            ),
                            Icon(
                              Symbols.chevron_right,
                              size: 20,
                              color: Color(0xFFAD8A68),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          const Icon(
                            Symbols.cloud_off,
                            size: 40,
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
                    )
                  else if (_items.isEmpty)
                    _emptyState()
                  else
                    ResponsiveCards(
                      children: [for (final listing in _items) _card(listing)],
                    ),
                ],
              ),
            ),
    ),
  );
}
