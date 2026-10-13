import '../../../../core/network/api_client.dart';
import '../models/contract_model.dart';

class ContractRepository {
  final ApiClient _apiClient;

  ContractRepository(this._apiClient);

  Future<Map<String, dynamic>> findTenant(String email, int listingId) async {
    final response = await _apiClient.get(
      '/contracts/tenant',
      queryParams: {'email': email, 'listingId': listingId},
    );
    return Map<String, dynamic>.from(response.data);
  }

  Future<ContractModel> detail(int id) async {
    final response = await _apiClient.get('/contracts/$id');
    return ContractModel.fromJson(response.data);
  }

  Future<void> update(int id, CreateContractRequest request) async {
    await _apiClient.put('/contracts/$id', request.toJson());
  }

  Future<void> status(int id, String status, int version) async {
    await _apiClient.patch(
      '/contracts/$id/status',
      data: {'status': status, 'version': version},
    );
  }

  Future<List<ContractModel>> getMyContracts() async {
    final response = await _apiClient.get('/contracts/me');
    if (response.statusCode == 200) {
      final body = response.data;
      // Backend returns either a direct list or wrapped in ApiResponse
      List<dynamic> data;
      if (body is List) {
        data = body;
      } else if (body is Map && body['data'] != null) {
        data = body['data'] as List<dynamic>;
      } else {
        data = [];
      }
      return data.map((json) => ContractModel.fromJson(json)).toList();
    }
    throw Exception('Không thể tải danh sách hợp đồng');
  }

  Future<ContractModel> createContract(CreateContractRequest request) async {
    final response = await _apiClient.post('/contracts', request.toJson());
    if ((response.statusCode == 200 || response.statusCode == 201)) {
      final body = response.data;
      final data = (body is Map && body['data'] != null) ? body['data'] : body;
      return ContractModel.fromJson(data as Map<String, dynamic>);
    }
    final errorMsg = response.data?['message'] ?? 'Tạo hợp đồng thất bại';
    throw Exception(errorMsg);
  }
}
