import '../../../../core/layout/app_layout.dart';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

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

  Widget _status(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .09),
      borderRadius: BorderRadius.circular(9),
    ),
    child: Text(
      label,
      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
    ),
  );

  Widget _cover(Listing listing) {
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

  Widget _card(Listing l) {
    final approvalColor = switch (l.approvalStatus) {
      'APPROVED' => const Color(0xFF387960),
      'REJECTED' => const Color(0xFFAE5141),
      _ => const Color(0xFFB77B25),
    };
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFEEDFD1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: 148, child: _cover(l)),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 10, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          l.title,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.4,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF38291F),
                          ),
                        ),
                      ),
                    ),
                    PopupMenuButton<String>(
                      enabled: !_busy,
                      tooltip: 'Thao tác tin ${l.id}',
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      icon: const Icon(
                        Symbols.more_horiz,
                        color: Color(0xFF8A7464),
                      ),
                      onSelected: (action) => _action(l, action),
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'EDIT',
                          child: Text('Sửa và gửi duyệt lại'),
                        ),
                        if (l.rentalStatus != 'HIDDEN')
                          const PopupMenuItem(
                            value: 'HIDDEN',
                            child: Text('Ẩn tin'),
                          ),
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
                        const PopupMenuItem(
                          value: 'DELETE',
                          child: Text('Xóa tin'),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      '${NumberFormat.decimalPattern('vi_VN').format(l.rentPrice)} đ/tháng',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFD76B28),
                      ),
                    ),
                    Text(
                      '· ${NumberFormat.decimalPattern('vi_VN').format(l.areaSqm)} m²',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF8A7464),
                      ),
                    ),
                  ],
                ),
                if (l.address != null && l.address!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Symbols.location_on,
                        size: 16,
                        color: Color(0xFFAA998A),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          l.address!,
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
                ],
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1, color: Color(0xFFF3ECE4)),
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _status(_approval(l.approvalStatus), approvalColor),
                    _status(
                      _rental(l.rentalStatus),
                      l.rentalStatus == 'AVAILABLE'
                          ? const Color(0xFF387960)
                          : const Color(0xFF8A7464),
                    ),
                  ],
                ),
                if (l.approvalStatus == 'REJECTED') ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF4F1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Lý do từ chối: ${l.rejectionReason ?? 'Chưa có lý do'}',
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.5,
                        color: Color(0xFFAE5141),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 44),
    child: Column(
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: const BoxDecoration(
            color: Color(0xFFFFEEDC),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Symbols.assignment,
            size: 38,
            color: Color(0xFFC88B53),
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Chưa có tin đăng trong danh sách này.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, height: 1.5, color: Color(0xFF8A7464)),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final visible = _listings
        .where((l) => _filter == 'ALL' || l.approvalStatus == _filter)
        .toList();
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAF8F5),
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Quản lý tin đăng',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w700,
            color: Color(0xFF38291F),
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loading || _busy ? null : _load,
            tooltip: 'Làm mới tin đăng',
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF8A7464),
              side: const BorderSide(color: Color(0xFFEEDFD1)),
            ),
            icon: const Icon(Symbols.refresh, size: 21),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFD76B28),
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        onPressed: _busy ? null : _create,
        icon: const Icon(Symbols.add, size: 22),
        label: const Text('Đăng tin'),
      ),
      body: AppContent(
        maxWidth: AppLayout.contentWidth,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Không gian của bạn · ${_listings.length} tin đăng',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8A7464),
                  ),
                ),
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Row(
                children: [
                  for (final status in [
                    'ALL',
                    'PENDING',
                    'APPROVED',
                    'REJECTED',
                  ])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(
                          status == 'ALL' ? 'Tất cả' : _approval(status),
                        ),
                        selected: _filter == status,
                        showCheckmark: false,
                        selectedColor: const Color(0xFF573B28),
                        backgroundColor: Colors.white,
                        side: BorderSide(
                          color: _filter == status
                              ? const Color(0xFF573B28)
                              : const Color(0xFFEEDFD1),
                        ),
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _filter == status
                              ? Colors.white
                              : const Color(0xFF8A7464),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13),
                        ),
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
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
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
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          if (visible.isEmpty) _emptyState(),
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
