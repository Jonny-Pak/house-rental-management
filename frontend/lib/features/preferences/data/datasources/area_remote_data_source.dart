import '../../../../core/network/api_client.dart';
import '../models/area_models.dart';

abstract class AreaRemoteDataSource {
  Future<List<Province>> getProvinces();
  Future<List<District>> getDistricts(int provinceId);
  Future<List<Ward>> getWards(int districtId);
}

class AreaRemoteDataSourceImpl implements AreaRemoteDataSource {
  final ApiClient _apiClient;

  AreaRemoteDataSourceImpl(this._apiClient);

  @override
  Future<List<Province>> getProvinces() async {
    final response = await _apiClient.get('/areas/provinces');
    final data = response.data['data'] as List;
    return data.map((json) => Province.fromJson(json)).toList();
  }

  @override
  Future<List<District>> getDistricts(int provinceId) async {
    final response = await _apiClient.get('/areas/provinces/$provinceId/districts');
    final data = response.data['data'] as List;
    return data.map((json) => District.fromJson(json)).toList();
  }

  @override
  Future<List<Ward>> getWards(int districtId) async {
    final response = await _apiClient.get('/areas/districts/$districtId/wards');
    final data = response.data['data'] as List;
    return data.map((json) => Ward.fromJson(json)).toList();
  }
}
