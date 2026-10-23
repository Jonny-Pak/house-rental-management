import '../../../core/network/api_client.dart';

class Notice {
  const Notice({
    required this.id,
    required this.type,
    required this.title,
    required this.content,
    required this.read,
    required this.createdAt,
    this.listingId,
    this.contractId,
  });
  final int id;
  final String type, title, content;
  final bool read;
  final DateTime? createdAt;
  final int? listingId, contractId;
  Notice withRead(bool value) => Notice(
    id: id,
    type: type,
    title: title,
    content: content,
    read: value,
    createdAt: createdAt,
    listingId: listingId,
    contractId: contractId,
  );
  factory Notice.fromJson(Map<String, dynamic> json) => Notice(
    id: json['id'] as int,
    type: json['type'] as String,
    title: json['title'] as String? ?? 'Thông báo',
    content: json['content'] as String? ?? '',
    read: json['read'] == true,
    createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
    listingId: json['listingId'] as int?,
    contractId: json['contractId'] as int?,
  );
}

class NotificationInbox {
  const NotificationInbox(this.items, this.unreadCount, this.hasMore);
  final List<Notice> items;
  final int unreadCount;
  final bool hasMore;
}

class NotificationRepository {
  NotificationRepository(this.api);
  final ApiClient api;
  Future<NotificationInbox> fetch(int page, bool unreadOnly) async {
    final response = await api.get(
      '/notifications',
      queryParams: {'page': page, 'unreadOnly': unreadOnly},
    );
    final data = response.data as Map;
    return NotificationInbox(
      (data['items'] as List)
          .map((row) => Notice.fromJson(Map<String, dynamic>.from(row)))
          .toList(),
      (data['unreadCount'] as num).toInt(),
      data['hasMore'] == true,
    );
  }

  Future<int> count() async {
    final response = await api.get('/notifications/unread-count');
    return (response.data['count'] as num).toInt();
  }

  Future<void> read(int id) async {
    await api.patch('/notifications/$id/read');
  }

  Future<void> readAll() async {
    await api.patch('/notifications/read-all');
  }

  Future<void> unread(int id) async {
    await api.patch('/notifications/$id/unread');
  }

  Future<void> delete(int id) async {
    await api.delete('/notifications/$id');
  }

  Future<void> deleteRead() async {
    await api.delete('/notifications/read');
  }

  Future<int> broadcast(String title, String content) async {
    final response = await api.post('/admin/notifications/broadcast', {
      'title': title,
      'content': content,
    });
    return (response.data['recipients'] as num).toInt();
  }
}
