import '../datasources/preference_remote_data_source.dart';
import '../models/user_preference.dart';

abstract class PreferenceRepository {
  Future<UserPreference> getPreferences();
  Future<UserPreference> updatePreferences(UserPreference preference);
}

class PreferenceRepositoryImpl implements PreferenceRepository {
  final PreferenceRemoteDataSource _remoteDataSource;

  PreferenceRepositoryImpl(this._remoteDataSource);

  @override
  Future<UserPreference> getPreferences() => _remoteDataSource.getPreferences();

  @override
  Future<UserPreference> updatePreferences(UserPreference preference) => _remoteDataSource.updatePreferences(preference);
}
