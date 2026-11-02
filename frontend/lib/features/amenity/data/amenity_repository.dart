import '../../../core/network/api_client.dart';
import 'amenity_model.dart';

class AmenityRepository {
  AmenityRepository(this.api);
  final ApiClient api;
  Future<List<Amenity>> activeItems() async {
    final response = await api.get('/amenities');
    return [
      for (final item in response.data['data'] as List)
        Amenity.fromJson(Map<String, dynamic>.from(item)),
    ];
  }

  Future<AmenityPageData> search({
    String query = '',
    String? category,
    bool? active,
    int page = 0,
  }) async {
    final params = <String, dynamic>{'query': query, 'page': page};
    if (category != null) {
      params['category'] = category;
    }
    if (active != null) {
      params['active'] = active;
    }
    final response = await api.get('/admin/amenities', queryParams: params);
    return AmenityPageData(Map<String, dynamic>.from(response.data['data']));
  }

  Future<void> save(int? id, Map<String, dynamic> data) async {
    if (id == null) {
      await api.post('/admin/amenities', data);
    } else {
      await api.put('/admin/amenities/$id', data);
    }
  }

  Future<void> changeStatus(Amenity item) async {
    await api.patch(
      '/admin/amenities/${item.id}/status',
      data: {'active': !item.active, 'version': item.version},
    );
  }

  Future<void> delete(Amenity item) async {
    await api.delete('/admin/amenities/${item.id}?version=${item.version}');
  }
}
