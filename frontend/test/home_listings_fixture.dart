import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/listing/data/models/listing_model.dart';
import 'package:frontend/features/listing/data/repositories/listing_repository.dart';

class HomeListings extends ListingRepository {
  HomeListings() : super(ApiClient());
  bool fail = false, saveFails = false;
  int loads = 0;
  final Set<int> saved = {2};
  final items = [
    Listing(
      id: 1,
      title: 'Nhà sáng thoáng',
      rentPrice: 5000000,
      areaSqm: 40,
      approvalStatus: 'APPROVED',
      address: 'Phường Sài Gòn',
      listingType: 'WHOLE_HOUSE',
    ),
    Listing(
      id: 2,
      title: 'Phòng trọ yên tĩnh',
      rentPrice: 2500000,
      areaSqm: 22,
      approvalStatus: 'APPROVED',
      address: 'Phường Bến Thành',
      listingType: 'BOARDING_ROOM',
    ),
    Listing(id: 3, title: 'Tin chờ duyệt', rentPrice: 2000000, areaSqm: 20),
  ];
  @override
  Future<List<Listing>> fetchApprovedListings() async {
    loads++;
    if (fail) throw Exception('Lỗi tải tin');
    return items;
  }

  @override
  Future<List<Listing>> fetchSavedListings() async =>
      items.where((item) => saved.contains(item.id)).toList();
  @override
  Future<void> setFavorite(int id, bool value) async {
    if (saveFails) throw Exception('Chưa lưu được tin');
    if (value) {
      saved.add(id);
    } else {
      saved.remove(id);
    }
  }

  @override
  Future<Listing> fetchDetail(int id) async =>
      items.firstWhere((item) => item.id == id);
  @override
  Future<bool> isFavorite(int id) async => saved.contains(id);
}
