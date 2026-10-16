import '../../../../core/layout/app_layout.dart';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/api_client.dart';
import '../../data/models/listing_model.dart';
import '../../data/repositories/listing_repository.dart';
import 'create_listing_page.dart';
import 'edit_listing_page.dart';

class MyListingsPage extends StatefulWidget {
  const MyListingsPage({super.key, this.repository});
  final ListingRepository? repository;
  @override
  State<MyListingsPage> createState() => _MyListingsPageState();
}

class _MyListingsPageState extends State<MyListingsPage> {
  late final ListingRepository _repository;
  List<Listing> _listings = [];
  bool _loading = true;
  bool _busy = false;
  String? _error;
  String _filter = 'ALL';

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? ListingRepository(ApiClient());
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final listings = await _repository.fetchMyListings();
      if (mounted) setState(() => _listings = listings);
    } catch (e) {
      if (mounted) setState(() => _error = ListingRepository.errorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _create() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const CreateListingPage()),
    );
    if (result == true && mounted) await _load();
  }

  Future<void> _action(Listing listing, String action) async {
    if (_busy) return;
    if (action == 'EDIT') {
      final saved = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) =>
              EditListingPage(listing: listing, repository: _repository),
        ),
      );
      if (saved == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã lưu tin và gửi Admin duyệt lại.')),
        );
        await _load();
      }
      return;
    }
    if (action == 'DELETE') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Xóa tin đăng?'),
          content: Text(
            'Tin “${listing.title}” sẽ được gỡ khỏi bản đồ và danh sách quản lý.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Xóa'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }
    setState(() => _busy = true);
    try {
      if (action == 'DELETE') {
        await _repository.deleteListing(listing.id);
      } else {
        await _repository.updateRentalStatus(listing.id, action);
      }
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ListingRepository.errorMessage(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _approval(String status) => switch (status) {
    'APPROVED' => 'Đã duyệt',
    'REJECTED' => 'Bị từ chối',
    _ => 'Chờ duyệt',
  };
  String _rental(String status) => switch (status) {
    'HIDDEN' => 'Đang ẩn',
    'RENTED' => 'Đã cho thuê',
    _ => 'Còn trống',
  };

  Widget _card(Listing l) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (l.imageUrl != null)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Image.network(
                    l.imageUrl!,
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const Icon(Icons.broken_image),
                  ),
                ),
              Expanded(
                child: Text(
                  l.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              PopupMenuButton<String>(
                enabled: !_busy,
                onSelected: (action) => _action(l, action),
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'EDIT',
                    child: Text('Sửa và gửi duyệt lại'),
                  ),
                  if (l.rentalStatus != 'HIDDEN')
                    const PopupMenuItem(value: 'HIDDEN', child: Text('Ẩn tin')),
                  if (l.rentalStatus != 'AVAILABLE')
                    const PopupMenuItem(
                      value: 'AVAILABLE',
                      child: Text('Đánh dấu còn trống / hiện tin'),
                    ),
                  if (l.rentalStatus != 'RENTED')
                    const PopupMenuItem(
                      value: 'RENTED',
                      child: Text('Đánh dấu đã cho thuê'),
                    ),
                  const PopupMenuItem(value: 'DELETE', child: Text('Xóa tin')),
                ],
              ),
            ],
          ),
          Text(l.address ?? ''),
          Text(
            '${NumberFormat.decimalPattern('vi_VN').format(l.rentPrice)} đ/tháng · ${l.areaSqm} m²',
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              Chip(label: Text(_approval(l.approvalStatus))),
              Chip(label: Text(_rental(l.rentalStatus))),
            ],
          ),
          if (l.approvalStatus == 'REJECTED')
            Text(
              'Lý do từ chối: ${l.rejectionReason ?? 'Chưa có lý do'}',
              style: const TextStyle(color: Colors.red),
            ),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final visible = _listings
        .where((l) => _filter == 'ALL' || l.approvalStatus == _filter)
        .toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý tin đăng'),
        actions: [
          IconButton(
            onPressed: _loading || _busy ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _busy ? null : _create,
        icon: const Icon(Icons.add),
        label: const Text('Đăng tin'),
      ),
      body: AppContent(
        maxWidth: AppLayout.contentWidth,
        child: Column(
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final status in [
                    'ALL',
                    'PENDING',
                    'APPROVED',
                    'REJECTED',
                  ])
                    Padding(
                      padding: const EdgeInsets.all(4),
                      child: ChoiceChip(
                        label: Text(
                          status == 'ALL' ? 'Tất cả' : _approval(status),
                        ),
                        selected: _filter == status,
                        onSelected: (_) => setState(() => _filter = status),
                      ),
                    ),
                ],
              ),
            ),
            if (_busy) const LinearProgressIndicator(),
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
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          if (visible.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(24),
                              child: Text(
                                'Chưa có tin đăng trong danh sách này.',
                              ),
                            ),
                          ResponsiveCards(
                            children: visible.map(_card).toList(),
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
