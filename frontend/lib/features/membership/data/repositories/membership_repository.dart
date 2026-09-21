import '../../../../core/network/api_client.dart';
import '../models/membership_package_model.dart';

class MembershipRepository {
  final ApiClient apiClient;

  MembershipRepository(this.apiClient);

  Future<List<MembershipPackage>> getPackages() async {
    final response = await apiClient.get('/memberships'); // The baseUrl in ApiClient already includes /api/v1
    if (response.statusCode == 200 && response.data != null && response.data is List) {
      return (response.data as List).map((json) => MembershipPackage.fromJson(json)).toList();
    }
    return [];
  }
}