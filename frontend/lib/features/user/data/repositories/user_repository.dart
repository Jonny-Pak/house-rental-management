import '../datasources/user_remote_data_source.dart';
import '../models/user_profile.dart';

abstract class UserRepository {
  Future<UserProfile> getProfile();
}

class UserRepositoryImpl implements UserRepository {
  final UserRemoteDataSource _remoteDataSource;

  UserRepositoryImpl(this._remoteDataSource);

  @override
  Future<UserProfile> getProfile() async {
    return _remoteDataSource.getProfile();
  }
}
