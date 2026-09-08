import '../../../../core/network/api_client.dart';
import '../models/user_profile.dart';

abstract class UserRemoteDataSource {
  Future<UserProfile> getProfile();
}

class UserRemoteDataSourceImpl implements UserRemoteDataSource {
  final ApiClient _apiClient;

  UserRemoteDataSourceImpl(this._apiClient);

  @override
  Future<UserProfile> getProfile() async {
    final response = await _apiClient.get('/users/me');
    final data = response.data['data'] as Map<String, dynamic>;
    return UserProfile.fromJson(data);
  }
}
