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
  });
  final String title;
  final String? listingType;
  final bool autofocus;
  final ListingRepository? repository;
  @override
  State<ListingBrowsePage> createState() => _ListingBrowsePageState();
}

class _ListingBrowsePageState extends State<ListingBrowsePage> {
  late final ListingRepository _repository;
  final _search = TextEditingController();
  List<Listing> _items = [];
  String? _error;
  bool _loading = true;
  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? ListingRepository(ApiClient());
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
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
  void _detail(Listing l) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (l.imageUrls.isNotEmpty)
                  SizedBox(
                    height: 180,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: l.imageUrls.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (_, i) => ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          l.imageUrls[i],
                          width: 260,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              const Icon(Symbols.broken_image),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                Text(
                  l.title,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _price(l),
                  style: const TextStyle(
                    fontSize: 18,
                    color: Color(0xFFFF751B),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text('${l.areaSqm} m² · ${l.address ?? ''}'),
                const SizedBox(height: 16),
                Text(
                  l.description ?? 'Chưa có mô tả.',
                  style: const TextStyle(height: 1.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = _search.text.trim().toLowerCase();
    final items = _items
        .where(
          (l) =>
              (widget.listingType == null ||
                  l.listingType == widget.listingType) &&
              '${l.title} ${l.address ?? ''}'.toLowerCase().contains(query),
        )
        .toList();
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _search,
              autofocus: widget.autofocus,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Tìm theo tiêu đề, địa chỉ…',
                prefixIcon: Icon(Symbols.search),
              ),
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
                              'Không có tin phù hợp. Hãy thử từ khóa khác.',
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
