import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/network/api_client.dart';
import '../../../map/presentation/widgets/rental_map_tiles.dart';
import '../../data/models/listing_model.dart';
import '../../data/repositories/listing_repository.dart';

const _accent = Color(0xFFD85D15);

class ListingDetailPage extends StatefulWidget {
  const ListingDetailPage({
    super.key,
    required this.listingId,
    this.repository,
    this.mapBuilder,
  });
  final int listingId;
  final ListingRepository? repository;
  final Widget Function(LatLng)? mapBuilder;
  @override
  State<ListingDetailPage> createState() => _ListingDetailPageState();
}

class _ListingDetailPageState extends State<ListingDetailPage> {
  late final _repository = widget.repository ?? ListingRepository(ApiClient());
  Listing? _listing;
  bool _loading = true, _saved = false, _saving = false, _favoriteReady = false;
  bool _checkingFavorite = false;
  String? _error;
  int _image = 0;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _favoriteReady = false;
    });
    try {
      final listing = await _repository.fetchDetail(widget.listingId);
      if (!mounted) return;
      setState(() {
        _listing = listing;
        _image = 0;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _listing = null;
          _error = e is DioException && e.response?.statusCode == 404
              ? 'Tin đăng đã ngừng hiển thị hoặc không còn cho thuê.'
              : ListingRepository.errorMessage(e);
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
    if (_listing == null || !mounted) return;
    setState(() => _checkingFavorite = true);
    try {
      final saved = await _repository.isFavorite(widget.listingId);
      if (mounted) {
        setState(() {
          _saved = saved;
          _favoriteReady = true;
        });
      }
    } catch (_) {
      // Public details remain usable even when the visitor is not logged in.
    } finally {
      if (mounted) setState(() => _checkingFavorite = false);
    }
  }

  void _message(String text) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
  }

  Future<void> _favorite() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      // Re-read if initial status failed, preventing an accidental remove/save.
      final saved = _favoriteReady
          ? _saved
          : await _repository.isFavorite(widget.listingId);
      await _repository.setFavorite(widget.listingId, !saved);
      if (mounted) {
        setState(() {
          _saved = !saved;
          _favoriteReady = true;
        });
      }
      _message(!saved ? 'Đã lưu tin yêu thích.' : 'Đã bỏ lưu tin.');
    } catch (e) {
      _message(
        e is DioException &&
                (e.response?.statusCode == 401 || e.response?.statusCode == 403)
            ? 'Vui lòng đăng nhập để lưu tin yêu thích.'
            : ListingRepository.errorMessage(e),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _open(Uri uri) async {
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        _message('Không mở được ứng dụng. Vui lòng thử lại.');
      }
    } catch (_) {
      _message('Thiết bị chưa hỗ trợ thao tác này.');
    }
  }

  String _money(num n) => '${NumberFormat.decimalPattern('vi_VN').format(n)} đ';
  String _label(dynamic value) =>
      const {
        'WHOLE_HOUSE': 'Nhà nguyên căn',
        'BOARDING_ROOM': 'Phòng trọ',
        'APARTMENT': 'Căn hộ',
        'MAT_PHO': 'Nhà mặt phố',
        'NGO_HEM': 'Nhà ngõ hẻm',
        'BIET_THU': 'Biệt thự',
        'LIEN_KE': 'Nhà liền kề',
        'RED_BOOK': 'Sổ đỏ',
        'PINK_BOOK': 'Sổ hồng',
        'SALE_CONTRACT': 'Hợp đồng mua bán',
        'NONE': 'Không có',
        'FULL': 'Đầy đủ nội thất',
        'BASIC': 'Nội thất cơ bản',
        'EMPTY': 'Không có nội thất',
        'NORTH': 'Bắc',
        'SOUTH': 'Nam',
        'EAST': 'Đông',
        'WEST': 'Tây',
        'NORTH_EAST': 'Đông Bắc',
        'NORTH_WEST': 'Tây Bắc',
        'NORTHWEST': 'Tây Bắc',
        'NORTHEAST': 'Đông Bắc',
        'SOUTHWEST': 'Tây Nam',
        'SOUTHEAST': 'Đông Nam',
        'SOUTH_EAST': 'Đông Nam',
        'SOUTH_WEST': 'Tây Nam',
      }[value] ??
      value?.toString() ??
      'Chưa cập nhật';
  Widget _section(String title, Widget child) => Padding(
    padding: const EdgeInsets.only(bottom: 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        child,
      ],
    ),
  );
  Widget _row(String label, dynamic value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Text(label)),
        Expanded(
          child: Text(
            _label(value),
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );

  Widget _photo(String url, {BoxFit fit = BoxFit.cover}) => Image.network(
    url,
    fit: fit,
    width: double.infinity,
    loadingBuilder: (_, child, progress) => progress == null
        ? child
        : const Center(child: CircularProgressIndicator()),
    errorBuilder: (_, _, _) =>
        const Center(child: Icon(Symbols.broken_image, size: 48)),
  );
  Future<void> _gallery(List<String> images) async {
    final controller = PageController(initialPage: _image);
    try {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              title: const Text('Hình ảnh'),
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
            ),
            body: PageView.builder(
              controller: controller,
              itemCount: images.length,
              itemBuilder: (_, i) => InteractiveViewer(
                child: Center(child: _photo(images[i], fit: BoxFit.contain)),
              ),
            ),
          ),
        ),
      );
    } finally {
      controller.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final listing = _listing;
    final phone = listing?.details['ownerPhone']?.toString().trim() ?? '';
    final dial = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F5),
      appBar: AppBar(
        title: const Text('Chi tiết tin cho thuê'),
        actions: [
          if (listing != null && !_loading)
            IconButton(
              tooltip: _saved ? 'Bỏ lưu tin' : 'Lưu tin yêu thích',
              onPressed: _saving || _checkingFavorite ? null : _favorite,
              icon: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      Symbols.favorite,
                      fill: _saved ? 1 : 0,
                      color: _saved ? Colors.red : null,
                    ),
            ),
        ],
      ),
      bottomNavigationBar: listing == null || _loading
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: dial.isEmpty
                            ? null
                            : () => _open(Uri(scheme: 'sms', path: dial)),
                        icon: const Icon(Symbols.sms),
                        label: const Text('Nhắn SMS'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(backgroundColor: _accent),
                        onPressed: dial.isEmpty
                            ? null
                            : () => _open(Uri(scheme: 'tel', path: dial)),
                        icon: const Icon(Symbols.call),
                        label: const Text('Gọi chủ nhà'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : listing == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Symbols.info, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      _error ?? 'Không tải được tin đăng.',
                      textAlign: TextAlign.center,
                    ),
                    TextButton(onPressed: _load, child: const Text('Thử lại')),
                  ],
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: _content(listing, phone),
              ),
            ),
    );
  }

  List<Widget> _content(Listing listing, String phone) {
    final images = listing.imageUrls.isNotEmpty
        ? listing.imageUrls
        : [if (listing.imageUrl?.isNotEmpty == true) listing.imageUrl!];
    final lat = listing.latitude, lng = listing.longitude;
    final point =
        lat != null &&
            lng != null &&
            lat.isFinite &&
            lng.isFinite &&
            lat.abs() <= 90 &&
            lng.abs() <= 180
        ? LatLng(lat, lng)
        : null;
    final details = listing.details;
    return [
      SizedBox(
        height: 240,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: images.isEmpty
              ? const ColoredBox(
                  color: Color(0xFFECE7E2),
                  child: Center(child: Icon(Symbols.image, size: 56)),
                )
              : Stack(
                  children: [
                    PageView.builder(
                      itemCount: images.length,
                      onPageChanged: (i) => setState(() => _image = i),
                      itemBuilder: (_, i) => GestureDetector(
                        onTap: () => _gallery(images),
                        child: _photo(images[i]),
                      ),
                    ),
                    Positioned(
                      right: 12,
                      bottom: 12,
                      child: Chip(
                        label: Text('${_image + 1}/${images.length}'),
                      ),
                    ),
                  ],
                ),
        ),
      ),
      const SizedBox(height: 20),
      Text(
        listing.title,
        style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 10),
      Text(
        '${_money(listing.rentPrice)}/tháng',
        style: const TextStyle(
          fontSize: 21,
          color: _accent,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 10),
      Text(
        listing.address ?? 'Chưa cập nhật địa chỉ',
        style: const TextStyle(height: 1.5),
      ),
      const SizedBox(height: 12),
      Wrap(
        spacing: 8,
        children: [
          Chip(label: Text(_label(listing.listingType))),
          Chip(label: Text('${listing.areaSqm} m²')),
        ],
      ),
      const SizedBox(height: 16),
      _section(
        'Thông tin nhà',
        Column(
          children: [
            if (listing.houseType != null) _row('Loại nhà', listing.houseType),
            _row('Phòng ngủ', details['bedrooms']),
            _row('Phòng tắm', details['bathrooms']),
            if (details['totalFloors'] != null)
              _row('Số tầng', details['totalFloors']),
            if (details['doorDirection'] != null)
              _row('Hướng cửa', details['doorDirection']),
            _row('Nội thất', details['furnitureStatus']),
            if (details['legalDocuments'] != null)
              _row('Giấy tờ pháp lý', details['legalDocuments']),
            _row(
              'Tiền đặt cọc',
              details['depositAmount'] is num
                  ? _money(details['depositAmount'] as num)
                  : null,
            ),
          ],
        ),
      ),
      _section(
        'Mô tả',
        SelectableText(
          listing.description?.trim().isNotEmpty == true
              ? listing.description!
              : 'Chủ nhà chưa bổ sung mô tả.',
          style: const TextStyle(height: 1.6),
        ),
      ),
      _section(
        'Vị trí',
        point == null
            ? const Text('Tin chưa có tọa độ trên bản đồ.')
            : Column(
                children: [
                  SizedBox(
                    height: 220,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child:
                          widget.mapBuilder?.call(point) ??
                          FlutterMap(
                            options: MapOptions(
                              initialCenter: point,
                              initialZoom: 16,
                            ),
                            children: [
                              const RentalMapTiles(),
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: point,
                                    width: 48,
                                    height: 48,
                                    child: const Icon(
                                      Symbols.location_on,
                                      fill: 1,
                                      color: _accent,
                                      size: 42,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _open(
                      Uri.https('www.google.com', '/maps/dir/', {
                        'api': '1',
                        'destination': '${point.latitude},${point.longitude}',
                      }),
                    ),
                    icon: const Icon(Symbols.directions),
                    label: const Text('Chỉ đường'),
                  ),
                ],
              ),
      ),
      _section(
        'Liên hệ chủ nhà',
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const CircleAvatar(child: Icon(Symbols.person)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        details['ownerName']?.toString() ?? 'Chủ nhà',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      SelectableText(
                        phone.isEmpty
                            ? 'Chủ nhà chưa cung cấp số điện thoại.'
                            : phone,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ];
  }
}
