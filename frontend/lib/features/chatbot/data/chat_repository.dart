import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/network/api_client.dart';
import '../../listing/data/models/listing_model.dart';
import '../../listing/data/repositories/listing_repository.dart';
import '../../listing/presentation/pages/search_location_page.dart';

class ChatReply {
  const ChatReply({
    required this.message,
    required this.filters,
    required this.conditions,
    required this.listings,
    required this.total,
    required this.locationRequired,
    this.clearLocation = false,
  });
  final String message;
  final Map<String, dynamic> filters;
  final List<String> conditions;
  final List<Listing> listings;
  final int total;
  final bool locationRequired;
  final bool clearLocation;

  factory ChatReply.fromJson(Map<String, dynamic> data) => ChatReply(
    message: data['message'] as String,
    filters: Map<String, dynamic>.from(data['filters'] as Map),
    conditions: List<String>.from(data['conditions'] as List),
    listings: [
      for (final row in data['listings'] as List)
        Listing.fromJson(Map<String, dynamic>.from(row)),
    ],
    total: (data['total'] as num).toInt(),
    locationRequired: data['locationRequired'] == true,
    clearLocation: data['clearLocation'] == true,
  );
}

class ChatRepository {
  ChatRepository(this.api);
  final ApiClient api;

  Future<ChatHistoryPage> history({int? beforeId}) async {
    final query = <String, dynamic>{};
    if (beforeId != null) query['beforeId'] = beforeId;
    final response = await api.get('/chatbot/history', queryParams: query);
    final data = Map<String, dynamic>.from(response.data);
    return ChatHistoryPage([
      for (final row in data['items'] as List)
        ChatHistoryItem.fromJson(Map<String, dynamic>.from(row)),
    ], data['hasMore'] == true);
  }

  Future<void> clearHistory() async {
    await api.delete('/chatbot/history');
  }

  Future<ChatReply> send(
    String message,
    Map<String, dynamic> filters,
    SearchLocation? location,
  ) async {
    final response = await api.post('/chatbot/messages', {
      'message': message,
      'context': filters,
      'latitude': location?.point.latitude,
      'longitude': location?.point.longitude,
      'locationName': location?.name,
    }, options: Options(receiveTimeout: const Duration(seconds: 40)));
    return ChatReply.fromJson(Map<String, dynamic>.from(response.data));
  }

  static String errorMessage(Object error) {
    if (error is DioException) {
      if (error.response?.statusCode == 401 ||
          error.response?.statusCode == 403) {
        return 'Phiên đăng nhập không hợp lệ. Bạn hãy đăng nhập lại.';
      }
      final data = error.response?.data;
      if (data is Map && data['message'] is String) {
        return data['message'] as String;
      }
      return 'Chưa kết nối được chatbot. Kiểm tra mạng và thử lại.';
    }
    return 'Chưa nhận được câu trả lời. Vui lòng thử lại.';
  }
}

class ChatHistoryPage {
  const ChatHistoryPage(this.items, this.hasMore);
  final List<ChatHistoryItem> items;
  final bool hasMore;
}

class ChatHistoryItem {
  const ChatHistoryItem(
    this.id,
    this.message,
    this.reply,
    this.location,
    this.createdAt,
  );
  final int id;
  final String message;
  final ChatReply reply;
  final SearchLocation? location;
  final DateTime createdAt;

  factory ChatHistoryItem.fromJson(Map<String, dynamic> data) =>
      ChatHistoryItem(
        (data['id'] as num).toInt(),
        data['message'] as String,
        ChatReply.fromJson(Map<String, dynamic>.from(data['reply'])),
        data['latitude'] == null || data['longitude'] == null
            ? null
            : SearchLocation(
                LatLng(
                  (data['latitude'] as num).toDouble(),
                  (data['longitude'] as num).toDouble(),
                ),
                data['locationName'] as String? ?? 'Điểm đã chọn',
              ),
        DateTime.parse(data['createdAt'] as String).toLocal(),
      );
}

class ChatMapRepository extends ListingRepository {
  ChatMapRepository(super.apiClient, this.ids);
  final Set<int> ids;

  @override
  Future<List<Listing>> fetchApprovedListings() async =>
      (await super.fetchApprovedListings())
          .where((item) => ids.contains(item.id))
          .toList();

  @override
  Future<List<Listing>> fetchNearby(
    double latitude,
    double longitude,
    double radiusKm,
  ) async => (await super.fetchNearby(
    latitude,
    longitude,
    radiusKm,
  )).where((item) => ids.contains(item.id)).toList();
}
