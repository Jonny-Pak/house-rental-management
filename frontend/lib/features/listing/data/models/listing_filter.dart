import 'package:latlong2/latlong.dart';

import 'listing_model.dart';

String rentalSearchKey(String text) {
  const groups = [
    'aàáạảãâầấậẩẫăằắặẳẵ',
    'eèéẹẻẽêềếệểễ',
    'iìíịỉĩ',
    'oòóọỏõôồốộổỗơờớợởỡ',
    'uùúụủũưừứựửữ',
    'yỳýỵỷỹ',
    'dđ',
  ];
  var result = text.toLowerCase().trim();
  for (final group in groups) {
    for (final rune in group.runes) {
      result = result.replaceAll(String.fromCharCode(rune), group[0]);
    }
  }
  return result.replaceAll(RegExp(r'\s+'), ' ');
}

class ListingFilter {
  const ListingFilter({
    this.query = '',
    this.center,
    this.centerName,
    this.radiusKm,
    this.genderPreference,
    this.areaId,
    this.areaName,
    this.listingType,
    this.minPrice,
    this.maxPrice,
    this.minArea,
    this.maxArea,
    this.sort = 'newest',
  });
  final LatLng? center;
  final String? centerName;
  final double? radiusKm;
  bool get hasRadius => center != null && radiusKm != null;

  double? distanceKm(Listing listing) {
    final lat = listing.latitude;
    final lng = listing.longitude;
    if (center == null ||
        lat == null ||
        lng == null ||
        !lat.isFinite ||
        !lng.isFinite ||
        lat.abs() > 90 ||
        lng.abs() > 180) {
      return null;
    }
    final distance = Distance.withRadius(
      6371008.7714,
      roundResult: false,
      calculator: const Haversine(),
    );
    return distance(center!, LatLng(lat, lng)) / 1000;
  }

  String distanceLabel(Listing listing) {
    final km = distanceKm(listing);
    if (km == null) return '';
    return '${km.toStringAsFixed(2)} km • đường chim bay';
  }

  final String query;
  final String? genderPreference;
  final int? areaId;
  final String? areaName, listingType;
  final double? minPrice, maxPrice, minArea, maxArea;
  final String sort;
  ListingFilter withQuery(String value) => ListingFilter(
    query: value,
    center: center,
    centerName: centerName,
    radiusKm: radiusKm,
    genderPreference: genderPreference,
    areaId: areaId,
    areaName: areaName,
    listingType: listingType,
    minPrice: minPrice,
    maxPrice: maxPrice,
    minArea: minArea,
    maxArea: maxArea,
    sort: sort,
  );
  ListingFilter withRadius({
    LatLng? center,
    String? centerName,
    double? radiusKm,
  }) => ListingFilter(
    query: query,
    center: center,
    centerName: centerName,
    radiusKm: radiusKm,
    genderPreference: genderPreference,
    areaId: areaId,
    areaName: areaName,
    listingType: listingType,
    minPrice: minPrice,
    maxPrice: maxPrice,
    minArea: minArea,
    maxArea: maxArea,
    sort: center != null
        ? 'nearest'
        : sort == 'nearest'
        ? 'newest'
        : sort,
  );

  int get count => [
    hasRadius,
    areaId != null,
    listingType != null,
    genderPreference != null,
    minPrice != null || maxPrice != null,
    minArea != null || maxArea != null,
    sort != 'newest',
  ].where((v) => v).length;
  String? get validationError {
    if ((center == null) != (radiusKm == null)) {
      return 'Chọn vị trí và bán kính tìm kiếm.';
    }
    if (center != null &&
        (!center!.latitude.isFinite ||
            !center!.longitude.isFinite ||
            center!.latitude.abs() > 90 ||
            center!.longitude.abs() > 180)) {
      return 'Vị trí không hợp lệ.';
    }
    if (radiusKm != null &&
        (!radiusKm!.isFinite || radiusKm! < 0.1 || radiusKm! > 50)) {
      return 'Bán kính phải từ 0,1 đến 50 km.';
    }
    if (sort == 'nearest' && center == null) {
      return 'Chọn vị trí để sắp xếp gần nhất.';
    }
    if ([
      minPrice,
      maxPrice,
      minArea,
      maxArea,
    ].any((v) => v != null && (!v.isFinite || v < 0))) {
      return 'Giá thuê và diện tích phải là số không âm.';
    }
    if (minPrice != null && maxPrice != null && minPrice! > maxPrice!) {
      return 'Giá tối thiểu không được lớn hơn giá tối đa.';
    }
    if (minArea != null && maxArea != null && minArea! > maxArea!) {
      return 'Diện tích tối thiểu không được lớn hơn diện tích tối đa.';
    }
    return null;
  }

  List<Listing> apply(Iterable<Listing> source) {
    final words = rentalSearchKey(query).split(' ').where((w) => w.isNotEmpty);
    final items = source.where((l) {
      final text = rentalSearchKey(
        '${l.title} ${l.address ?? ''} ${l.description ?? ''} ${l.details['roommateRequirements'] ?? ''}',
      );
      return l.approvalStatus == 'APPROVED' &&
          l.rentalStatus == 'AVAILABLE' &&
          words.every(text.contains) &&
          (!hasRadius ||
              distanceKm(l) != null && distanceKm(l)! <= radiusKm!) &&
          (areaId == null || areaId == l.areaId) &&
          (listingType == null || listingType == l.listingType) &&
          (genderPreference == null ||
              l.listingType == 'SHARED_ROOM' &&
                  (l.roommateInfo.genderPreference == 'ANY' ||
                      l.roommateInfo.genderPreference == genderPreference)) &&
          (minPrice == null || l.rentPrice >= minPrice!) &&
          (maxPrice == null || l.rentPrice <= maxPrice!) &&
          (minArea == null || l.areaSqm >= minArea!) &&
          (maxArea == null || l.areaSqm <= maxArea!);
    }).toList();
    int newest(Listing a, Listing b) {
      final ad = a.displayTime;
      final bd = b.displayTime;
      final dateOrder = ad != null && bd != null ? bd.compareTo(ad) : 0;
      return dateOrder != 0 ? dateOrder : b.id.compareTo(a.id);
    }

    items.sort((a, b) {
      if (sort == 'newest' && a.isVip != b.isVip) return a.isVip ? -1 : 1;
      final result = switch (sort) {
        'nearest' => (distanceKm(a) ?? double.infinity).compareTo(
          distanceKm(b) ?? double.infinity,
        ),
        'priceAsc' => a.rentPrice.compareTo(b.rentPrice),
        'priceDesc' => b.rentPrice.compareTo(a.rentPrice),
        'areaDesc' => b.areaSqm.compareTo(a.areaSqm),
        _ => newest(a, b),
      };
      return result == 0 ? newest(a, b) : result;
    });
    return items;
  }
}
