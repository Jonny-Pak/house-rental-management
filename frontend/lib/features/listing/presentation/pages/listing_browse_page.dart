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
      '${NumberFormat.decimalPattern('vi_VN').format(l.rentPrice)} đ/tháng';
  void _detail(Listing listing) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ListingDetailPage(listingId: listing.id, repository: _repository),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = _filter.apply(_items);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            tooltip: 'Xem trên bản đồ',
            icon: const Icon(Symbols.map),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ListingMapPage(initialFilter: _filter),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          ListingFilterBar(
            filter: _filter,
            autofocus: widget.autofocus,
            onChanged: (filter) => setState(() => _filter = filter),
          ),
          if (!_loading && _error == null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('${items.length} tin phù hợp'),
              ),
            ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!),
                        TextButton(
                          onPressed: _load,
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        if (items.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(24),
                            child: Text(
                              'Không có tin phù hợp. Hãy đổi từ khóa hoặc xóa bộ lọc.',
                            ),
                          ),
                        for (final l in items)
                          Card(
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              onTap: () => _detail(l),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: l.imageUrl == null
                                          ? const SizedBox(
                                              width: 80,
                                              height: 86,
                                              child: Icon(
                                                Symbols.home_work,
                                                size: 40,
                                              ),
                                            )
                                          : Image.network(
                                              l.imageUrl!,
                                              width: 80,
                                              height: 86,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, _, _) =>
                                                  const SizedBox(
                                                    width: 80,
                                                    height: 86,
                                                    child: Icon(
                                                      Symbols.broken_image,
                                                    ),
                                                  ),
                                            ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            l.title,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            _price(l),
                                            style: const TextStyle(
                                              color: Color(0xFFFF751B),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Text('${l.areaSqm} m²'),
                                          Text(
                                            l.address ?? '',
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
