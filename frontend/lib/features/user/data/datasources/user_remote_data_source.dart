import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/network/api_client.dart';
import '../models/user_profile.dart';

abstract class UserRemoteDataSource {
  Future<UserProfile> getProfile();
  Future<UserProfile> updateAvatar(String avatarUrl);
  Future<String> uploadImage(XFile file);
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

  @override
  Future<UserProfile> updateAvatar(String avatarUrl) async {
    final response = await _apiClient.patch(
      '/users/me/avatar',
      data: {'avatarUrl': avatarUrl},
    );
    final data = response.data['data'] as Map<String, dynamic>;
    return UserProfile.fromJson(data);
  }

  @override
  Future<String> uploadImage(XFile file) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(await file.readAsBytes(), filename: file.name),
    });

    final response = await _apiClient.post('/images/upload', formData);
    if (response.statusCode == 200 && response.data['success'] == true) {
      return response.data['data'] as String;
    } else {
      throw Exception(response.data['message'] ?? 'Upload failed');
    }
  }
}
