import '../../../../core/network/api_client.dart';
import '../../../contract/data/models/contract_model.dart';

class AdminContractPageData {
  AdminContractPageData(Map<String, dynamic> json)
    : total = (json['total'] as num).toInt(),
      page = (json['page'] as num).toInt(),
      totalPages = (json['totalPages'] as num).toInt() {
    for (final row in json['items']) {
      items.add(ContractModel.fromJson(Map<String, dynamic>.from(row)));
    }
  }
  final int total, page, totalPages;
  final items = <ContractModel>[];
}

class AdminContractRepository {
  AdminContractRepository(this.api);
  final ApiClient api;
  Future<AdminContractPageData> fetch({
    String query = '',
    String status = '',
    String type = '',
    int page = 0,
  }) async {
    final response = await api.get(
      '/admin/contracts',
      queryParams: {
        'query': query.trim(),
        'status': status,
        'type': type,
        'page': page,
      },
    );
    return AdminContractPageData(
      Map<String, dynamic>.from(response.data['data']),
    );
  }

  Future<ContractModel> detail(int id) async {
    final response = await api.get('/admin/contracts/$id');
    return ContractModel.fromJson(
      Map<String, dynamic>.from(response.data['data']),
    );
  }
}
