import 'package:dio/dio.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/amenity/data/amenity_model.dart';
import 'package:frontend/features/amenity/data/amenity_repository.dart';

class MemoryAmenities extends AmenityRepository {
  MemoryAmenities() : super(ApiClient());
  final rows = <int, Map<String, dynamic>>{
    1: {
      'id': 1,
      'name': 'Giường',
      'category': 'FURNITURE',
      'description': '',
      'active': true,
      'version': 0,
      'listingCount': 1,
    },
    2: {
      'id': 2,
      'name': 'Wi-Fi',
      'category': 'UTILITY',
      'description': 'Internet',
      'active': true,
      'version': 0,
      'listingCount': 0,
    },
  };
  bool failLoad = false, failSave = false;
  int saves = 0, statuses = 0, deletes = 0, lastPage = 0;
  String? lastCategory;
  Map<String, dynamic>? saved;
  void failure(String message) => throw DioException(
    requestOptions: RequestOptions(),
    response: Response(
      requestOptions: RequestOptions(),
      statusCode: 409,
      data: {'message': message},
    ),
  );
  @override
  Future<List<Amenity>> activeItems() async {
    if (failLoad) failure('Không tải được danh mục.');
    return [
      for (final row in rows.values)
        if (row['active'] == true) Amenity.fromJson(row),
    ];
  }

  @override
  Future<AmenityPageData> search({
    String query = '',
    String? category,
    bool? active,
    int page = 0,
  }) async {
    if (failLoad) failure('Không tải được danh mục.');
    lastPage = page;
    lastCategory = category;
    final found = rows.values
        .where(
          (row) =>
              row['name'].toString().contains(query) &&
              (category == null || row['category'] == category) &&
              (active == null || row['active'] == active),
        )
        .toList();
    return AmenityPageData({
      'items': found.skip(page * 20).take(20).toList(),
      'total': found.length,
      'page': page,
      'totalPages': (found.length / 20).ceil(),
    });
  }

  @override
  Future<void> save(int? id, Map<String, dynamic> data) async {
    if (failSave) {
      failure('Danh mục đã thay đổi. Hãy tải lại trước khi thao tác.');
    }
    saves++;
    saved = data;
    final target = id ?? rows.length + 1;
    rows[target] = {
      ...data,
      'id': target,
      'version': (data['version'] as int? ?? -1) + 1,
      'listingCount': rows[target]?['listingCount'] ?? 0,
    };
  }

  @override
  Future<void> changeStatus(Amenity item) async {
    statuses++;
    rows[item.id]!['active'] = !item.active;
    rows[item.id]!['version'] = item.version + 1;
  }

  @override
  Future<void> delete(Amenity item) async {
    deletes++;
    rows.remove(item.id);
  }
}
