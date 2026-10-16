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

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Tin yêu thích'),
      actions: [
        IconButton(
          tooltip: 'Làm mới',
          onPressed: _loading ? null : _load,
          icon: const Icon(Symbols.refresh),
        ),
      ],
    ),
    body: AppContent(
      maxWidth: AppLayout.contentWidth,
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  TextButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SavedPropertiesPage(),
                      ),
                    ),
                    icon: const Icon(Symbols.home),
                    label: const Text('Xem khu trọ đã lưu'),
                  ),
                  if (_error != null) ...[
                    Text(_error!),
                    TextButton(onPressed: _load, child: const Text('Thử lại')),
                  ] else if (_items.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: Text(
                        'Chưa có tin yêu thích đang cho thuê. Hãy mở một tin và nhấn biểu tượng trái tim.',
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    ResponsiveCards(
                      children: _items
                          .map(
                            (listing) => Card(
                              child: ListTile(
                                title: Text(listing.title),
                                subtitle: Text(
                                  '${NumberFormat.decimalPattern('vi_VN').format(listing.rentPrice)} đ/tháng\n${listing.address ?? ''}',
                                ),
                                isThreeLine: true,
                                trailing: IconButton(
                                  tooltip: 'Bỏ lưu tin',
                                  onPressed: () => _remove(listing),
                                  icon: const Icon(
                                    Symbols.favorite,
                                    fill: 1,
                                    color: Colors.red,
                                  ),
                                ),
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ListingDetailPage(
                                        listingId: listing.id,
                                        repository: _repository,
                                      ),
                                    ),
                                  );
                                  if (mounted) await _load();
                                },
                              ),
                            ),
                          )
                          .toList(),
                    ),
                ],
              ),
            ),
    ),
  );
}
