import '../../../listing/presentation/widgets/listing_vip_badge.dart';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../listing/data/models/listing_filter.dart';
import '../../../listing/data/models/listing_model.dart';
import '../../../listing/data/repositories/listing_repository.dart';
import '../../../listing/presentation/pages/listing_detail_page.dart';

class HomeRecentListings extends StatefulWidget {
  const HomeRecentListings({super.key, this.repository});
  final ListingRepository? repository;
  @override
  State<HomeRecentListings> createState() => _HomeRecentListingsState();
}

class _HomeRecentListingsState extends State<HomeRecentListings> {
  late final _repository = widget.repository ?? ListingRepository(ApiClient());
  List<Listing> _listings = [];
  final Set<int> _saved = {};
  bool _loading = true, _favoritesReady = false;
  String? _error;
  int? _saving;
  int _request = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final request = ++_request;
    setState(() {
      _loading = true;
      _error = null;
      _favoritesReady = false;
    });
    try {
      final items = await _repository.fetchApprovedListings();
      if (!mounted || request != _request) return;
      setState(
        () => _listings = const ListingFilter().apply(items).take(4).toList(),
      );
    } catch (error) {
      if (mounted && request == _request) {
        setState(() => _error = ListingRepository.errorMessage(error));
      }
      return;
    } finally {
      if (mounted && request == _request) setState(() => _loading = false);
    }
    try {
      final saved = await _repository.fetchSavedListings();
      if (!mounted || request != _request) return;
      setState(() {
        _saved.clear();
        for (final listing in saved) {
          _saved.add(listing.id);
        }
        _favoritesReady = true;
      });
    } catch (_) {
      if (mounted && request == _request) {
        setState(() => _favoritesReady = false);
      }
    }
  }

  Future<void> _favorite(Listing listing) async {
    if (_saving != null || !_favoritesReady) return;
    final saved = !_saved.contains(listing.id);
    setState(() => _saving = listing.id);
    try {
      await _repository.setFavorite(listing.id, saved);
      if (!mounted) return;
      setState(() {
        if (saved) {
          _saved.add(listing.id);
        } else {
          _saved.remove(listing.id);
        }
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ListingRepository.errorMessage(error))),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = null);
    }
  }

  Future<void> _detail(Listing listing) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ListingDetailPage(listingId: listing.id, repository: _repository),
      ),
    );
    if (mounted) _load();
  }

  Widget _photo(Listing listing) {
    final url =
        listing.imageUrl ??
        (listing.imageUrls.isEmpty ? null : listing.imageUrls.first);
    const fallback = ColoredBox(
      color: AppColors.primaryLight,
      child: Center(
        child: Icon(
          Icons.home_work_outlined,
          size: 36,
          color: AppColors.placeholder,
        ),
      ),
    );
    return Stack(
      fit: StackFit.expand,
      children: [
        if (url == null || url.isEmpty)
          fallback
        else
          Image.network(
            url,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => fallback,
          ),
        Positioned(
          top: 4,
          right: 4,
          child: IconButton(
            key: ValueKey('home-favorite-${listing.id}'),
            tooltip: _favoritesReady
                ? (_saved.contains(listing.id) ? 'Bỏ lưu tin' : 'Lưu tin')
                : 'Tải lại để xem tin đã lưu',
            onPressed: _favoritesReady && _saving == null
                ? () => _favorite(listing)
                : null,
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xEFFFFFFF),
              disabledBackgroundColor: const Color(0xEFFFFFFF),
              visualDensity: VisualDensity.compact,
            ),
            icon: _saving == listing.id
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    _saved.contains(listing.id)
                        ? Icons.favorite
                        : Icons.favorite_border,
                    size: 20,
                    color: _saved.contains(listing.id)
                        ? const Color(0xFFCD506E)
                        : AppColors.primaryDark,
                  ),
          ),
        ),
        if (listing.imageUrls.isNotEmpty)
          Positioned(
            bottom: 6,
            right: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0x99000000),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${listing.imageUrls.length} ảnh',
                style: const TextStyle(fontSize: 10, color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }

  Widget _details(Listing listing) => Padding(
    padding: const EdgeInsets.all(10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (listing.isVip) const ListingVipBadge(),
        Text(
          listing.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 14,
            height: 1.35,
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${NumberFormat.decimalPattern('vi_VN').format(listing.rentPrice)} đ/${listingRentUnit(listing.listingType)}',
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          listing.address ?? 'Chưa có địa chỉ',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.muted,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            Text(
              '${NumberFormat.decimalPattern('vi_VN').format(listing.areaSqm)} m²',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              listingTypeLabel(listing.listingType),
              style: const TextStyle(fontSize: 11, color: AppColors.muted),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _card(Listing listing, double width) {
    final stacked =
        width < 330 || MediaQuery.textScalerOf(context).scale(14) > 20;
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: ValueKey('home-listing-${listing.id}'),
        onTap: _saving == listing.id ? null : () => _detail(listing),
        child: stacked
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: 170, child: _photo(listing)),
                  _details(listing),
                ],
              )
            : Row(
                children: [
                  SizedBox(width: 118, height: 136, child: _photo(listing)),
                  Expanded(child: _details(listing)),
                ],
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Column(
        children: [
          const Text(
            'Chưa tải được tin cho thuê.',
            style: TextStyle(color: AppColors.muted),
          ),
          TextButton(onPressed: _load, child: const Text('Thử lại')),
        ],
      );
    }
    if (_listings.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.home_work_outlined,
              size: 36,
              color: AppColors.placeholder,
            ),
            const SizedBox(height: 10),
            const Text(
              'Chưa có tin cho thuê mới.',
              style: TextStyle(color: AppColors.muted),
            ),
            TextButton(onPressed: _load, child: const Text('Tải lại')),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 760 ? 2 : 1;
            final width = (constraints.maxWidth - (columns - 1) * 12) / columns;
            return Wrap(
              spacing: 12,
              runSpacing: 10,
              children: [
                for (final listing in _listings)
                  SizedBox(width: width, child: _card(listing, width)),
              ],
            );
          },
        ),
        if (!_favoritesReady)
          TextButton(
            onPressed: _load,
            child: const Text('Tải lại trạng thái yêu thích'),
          ),
      ],
    );
  }
}
