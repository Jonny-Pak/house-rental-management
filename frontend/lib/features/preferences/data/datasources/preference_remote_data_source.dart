import '../../../../core/network/api_client.dart';
import '../models/user_preference.dart';

abstract class PreferenceRemoteDataSource {
  Future<UserPreference> getPreferences();
  Future<UserPreference> updatePreferences(UserPreference preference);
}

class PreferenceRemoteDataSourceImpl implements PreferenceRemoteDataSource {
  final ApiClient _apiClient;

  PreferenceRemoteDataSourceImpl(this._apiClient);

  @override
  Future<UserPreference> getPreferences() async {
    final response = await _apiClient.get('/users/me/preferences');
    return UserPreference.fromJson(response.data['data']);
  }

  @override
  Future<UserPreference> updatePreferences(UserPreference preference) async {
    final response = await _apiClient.put('/users/me/preferences', preference.toJson());
    return UserPreference.fromJson(response.data['data']);
  }
}
