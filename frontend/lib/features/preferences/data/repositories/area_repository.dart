import '../datasources/area_remote_data_source.dart';
import '../models/area_models.dart';

abstract class AreaRepository {
  Future<List<Province>> getProvinces();
  Future<List<District>> getDistricts(int provinceId);
  Future<List<Ward>> getWards(int districtId);
  Future<List<Ward>> getWardsByProvince(int provinceId);
}

class AreaRepositoryImpl implements AreaRepository {
  final AreaRemoteDataSource _remoteDataSource;

  AreaRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<Province>> getProvinces() => _remoteDataSource.getProvinces();

  @override
  Future<List<District>> getDistricts(int provinceId) =>
      _remoteDataSource.getDistricts(provinceId);

  @override
  Future<List<Ward>> getWardsByProvince(int provinceId) =>
      _remoteDataSource.getWardsByProvince(provinceId);

  @override
  Future<List<Ward>> getWards(int districtId) =>
      _remoteDataSource.getWards(districtId);
}
