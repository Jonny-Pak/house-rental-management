import 'package:image_picker/image_picker.dart';
import '../datasources/user_remote_data_source.dart';
import '../models/user_profile.dart';

abstract class UserRepository {
  Future<UserProfile> getProfile();
  Future<UserProfile> updateAvatar(String avatarUrl);
  Future<String> uploadImage(XFile file);
}

class UserRepositoryImpl implements UserRepository {
  final UserRemoteDataSource _remoteDataSource;

  UserRepositoryImpl(this._remoteDataSource);

  @override
  Future<UserProfile> getProfile() async {
    return _remoteDataSource.getProfile();
  }

  @override
  Future<UserProfile> updateAvatar(String avatarUrl) async {
    return _remoteDataSource.updateAvatar(avatarUrl);
  }

  @override
  Future<String> uploadImage(XFile file) async {
    return _remoteDataSource.uploadImage(file);
  }
}
