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
    this.areaId,
    this.areaName,
    this.listingType,
    this.minPrice,
    this.maxPrice,
    this.minArea,
    this.maxArea,
    this.sort = 'newest',
  });
  final String query;
  final int? areaId;
  final String? areaName, listingType;
  final double? minPrice, maxPrice, minArea, maxArea;
  final String sort;
  ListingFilter withQuery(String value) => ListingFilter(
    query: value,
    areaId: areaId,
    areaName: areaName,
    listingType: listingType,
    minPrice: minPrice,
    maxPrice: maxPrice,
    minArea: minArea,
    maxArea: maxArea,
    sort: sort,
  );
  int get count => [
    areaId != null,
    listingType != null,
    minPrice != null || maxPrice != null,
    minArea != null || maxArea != null,
    sort != 'newest',
  ].where((v) => v).length;
  String? get validationError {
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
        '${l.title} ${l.address ?? ''} ${l.description ?? ''}',
      );
      return l.approvalStatus == 'APPROVED' &&
          l.rentalStatus == 'AVAILABLE' &&
          words.every(text.contains) &&
          (areaId == null || areaId == l.areaId) &&
          (listingType == null || listingType == l.listingType) &&
          (minPrice == null || l.rentPrice >= minPrice!) &&
          (maxPrice == null || l.rentPrice <= maxPrice!) &&
          (minArea == null || l.areaSqm >= minArea!) &&
          (maxArea == null || l.areaSqm <= maxArea!);
    }).toList();
    int newest(Listing a, Listing b) {
      final ad = DateTime.tryParse(a.details['createdAt']?.toString() ?? '');
      final bd = DateTime.tryParse(b.details['createdAt']?.toString() ?? '');
      final dateOrder = ad != null && bd != null ? bd.compareTo(ad) : 0;
      return dateOrder != 0 ? dateOrder : b.id.compareTo(a.id);
    }

    items.sort((a, b) {
      final result = switch (sort) {
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
