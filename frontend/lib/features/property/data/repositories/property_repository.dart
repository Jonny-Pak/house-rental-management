import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/network/api_client.dart';
import '../../../preferences/data/models/area_models.dart';
import '../models/property_model.dart';
import '../models/room_model.dart';

class PropertyRepository {
  final ApiClient _apiClient;

  PropertyRepository(this._apiClient);

  Future<PropertyModel> fetchPropertyDetails(int id) async {
    final response = await _apiClient.get('/properties/$id');
    if (response.statusCode == 200 && response.data['success'] == true) {
      return PropertyModel.fromJson(response.data['data']);
    }
    throw Exception('Failed to load property details');
  }

  Future<List<RoomModel>> fetchRooms(int propertyId) async {
    final response = await _apiClient.get('/properties/$propertyId/rooms');
    if (response.statusCode == 200 && response.data['success'] == true) {
      return (response.data['data'] as List)
          .map((json) => RoomModel.fromJson(json))
          .toList();
    }
    throw Exception('Failed to load rooms');
  }

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

  Future<List<PropertyModel>> fetchProperties() async {
    final response = await _apiClient.get('/properties');
    if (response.statusCode == 200 && response.data['success'] == true) {
      return (response.data['data'] as List)
          .map((json) => PropertyModel.fromJson(json))
          .toList();
    }
    throw Exception('Failed to load properties');
  }

  Future<void> createProperty(Map<String, dynamic> data) async {
    final response = await _apiClient.post('/properties', data);
    if (response.statusCode != 200 || response.data['success'] != true) {
      throw Exception(response.data['message'] ?? 'Failed to create property');
    }
  }

  Future<List<Province>> getProvinces() async {
    final response = await _apiClient.get('/areas/provinces');
    if (response.statusCode == 200 && response.data['success'] == true) {
      return (response.data['data'] as List)
          .map((json) => Province.fromJson(json))
          .toList();
    }
    throw Exception('Failed to load provinces');
  }

  Future<List<District>> getDistricts(int provinceId) async {
    final response = await _apiClient.get('/areas/provinces/$provinceId/districts');
    if (response.statusCode == 200 && response.data['success'] == true) {
      return (response.data['data'] as List)
          .map((json) => District.fromJson(json))
          .toList();
    }
    throw Exception('Failed to load districts');
  }

  Future<List<Ward>> getWards(int districtId) async {
    final response = await _apiClient.get('/areas/districts/$districtId/wards');
    if (response.statusCode == 200 && response.data['success'] == true) {
      return (response.data['data'] as List)
          .map((json) => Ward.fromJson(json))
          .toList();
    }
    throw Exception('Failed to load wards');
  }
}
