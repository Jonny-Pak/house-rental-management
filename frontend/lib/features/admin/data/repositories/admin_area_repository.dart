import '../../../../core/network/api_client.dart';
import '../models/admin_area.dart';

class AdminAreaRepository {
  AdminAreaRepository(this.api);
  final ApiClient api;

  Future<AdminAreaPage> search({
    String query = '',
    String? type,
    int? parentId,
    bool? active,
    int page = 0,
  }) async {
    final params = <String, dynamic>{'query': query.trim(), 'page': page};
    if (type != null) params['type'] = type;
    if (parentId != null) params['parentId'] = parentId;
    if (active != null) params['active'] = active;
    final response = await api.get('/admin/areas', queryParams: params);
    return AdminAreaPage.fromJson(
      Map<String, dynamic>.from(response.data['data']),
    );
  }

  Future<List<AdminArea>> parents() async {
    final response = await api.get('/admin/areas/parents');
    return (response.data['data'] as List)
        .map((row) => AdminArea.fromJson(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<AdminArea> detail(int id) async {
    final response = await api.get('/admin/areas/$id');
    return AdminArea.fromJson(Map<String, dynamic>.from(response.data['data']));
  }

  Future<void> save({
    int? id,
    required String name,
    required String code,
    required String type,
    int? parentId,
  }) async {
    final data = <String, dynamic>{
      'name': name.trim(),
      'code': code.trim().toUpperCase(),
      'type': type,
      'parentId': parentId,
    };
    if (id == null) {
      await api.post('/admin/areas', data);
    } else {
      await api.put('/admin/areas/$id', data);
    }
  }

  Future<void> changeStatus(int id, bool active) async {
    await api.patch('/admin/areas/$id/status', data: {'active': active});
  }

  Future<void> delete(int id) async {
    await api.delete('/admin/areas/$id');
  }
}
