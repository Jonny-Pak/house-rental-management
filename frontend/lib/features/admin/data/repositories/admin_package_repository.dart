import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../membership/data/models/membership_package_model.dart';

class AdminPackagePageData {
  AdminPackagePageData(Map<String, dynamic> json)
    : total = (json['total'] as num).toInt(),
      page = (json['page'] as num).toInt(),
      totalPages = (json['totalPages'] as num).toInt() {
    for (final row in json['items']) {
      items.add(MembershipPackage.fromJson(Map<String, dynamic>.from(row)));
    }
  }
  final int total, page, totalPages;
  final items = <MembershipPackage>[];
}

class AdminPackageRepository {
  AdminPackageRepository(this.api);
  final ApiClient api;
  Future<AdminPackagePageData> fetch({
    String query = '',
    bool? active,
    int page = 0,
  }) async {
    final filters = <String, dynamic>{'query': query.trim(), 'page': page};
    if (active != null) filters['active'] = active;
    final response = await api.get('/admin/memberships', queryParams: filters);
    return AdminPackagePageData(
      Map<String, dynamic>.from(response.data['data']),
    );
  }

  Future<void> save(int? id, Map<String, dynamic> data) async {
    if (id == null) {
      await api.post('/admin/memberships', data);
    } else {
      await api.put('/admin/memberships/$id', data);
    }
  }

  Future<void> status(MembershipPackage item) async {
    await api.patch(
      '/admin/memberships/${item.id}/status',
      data: {'active': !item.active, 'version': item.version},
    );
  }

  Future<void> delete(MembershipPackage item) async {
    await api.delete('/admin/memberships/${item.id}?version=${item.version}');
  }
}

String packageError(Object error) {
  if (error is DioException && error.response?.data is Map) {
    final data = error.response!.data;
    if (data['data'] is Map) return (data['data'] as Map).values.join('\n');
    if (data['message'] is String) return data['message'];
  }
  return 'Không kết nối được máy chủ. Vui lòng thử lại.';
}
