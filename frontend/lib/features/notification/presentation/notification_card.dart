import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/notification_repository.dart';

class NotificationCard extends StatelessWidget {
  const NotificationCard({
    super.key,
    required this.notice,
    required this.busy,
    required this.onOpen,
    required this.onAction,
  });
  final Notice notice;
  final bool busy;
  final VoidCallback onOpen;
  final ValueChanged<String> onAction;

  IconData _icon() {
    if (notice.type.startsWith('INCIDENT')) return Icons.support_agent_outlined;
    if (notice.type.startsWith('CONTRACT')) return Icons.description_outlined;
    if (notice.type == 'SYSTEM') return Icons.campaign_outlined;
    return Icons.home_work_outlined;
  }

  @override
  Widget build(BuildContext context) => Card(
    key: ValueKey('notice-${notice.id}'),
    color: notice.read ? Colors.white : const Color(0xFFFFF0DD),
    elevation: 0,
    margin: const EdgeInsets.only(bottom: 12),
    child: ListTile(
      contentPadding: const EdgeInsets.all(16),
      onTap: busy ? null : onOpen,
      leading: Icon(_icon(), color: const Color(0xFFD76B28)),
      title: Text(
        notice.title,
        style: TextStyle(
          fontWeight: notice.read ? FontWeight.w500 : FontWeight.bold,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notice.content, maxLines: 3, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 8),
            Text(
              notice.createdAt == null
                  ? ''
                  : DateFormat('dd/MM/yyyy HH:mm').format(notice.createdAt!),
              style: const TextStyle(fontSize: 11),
            ),
            if (!notice.read)
              const Text(
                'Chưa đọc',
                style: TextStyle(fontSize: 11, color: Color(0xFFD76B28)),
              ),
          ],
        ),
      ),
      trailing: PopupMenuButton<String>(
        key: ValueKey('notice-actions-${notice.id}'),
        tooltip: 'Thao tác thông báo',
        enabled: !busy,
        onSelected: onAction,
        itemBuilder: (_) => [
          PopupMenuItem(
            value: notice.read ? 'unread' : 'read',
            child: Text(notice.read ? 'Đánh dấu chưa đọc' : 'Đánh dấu đã đọc'),
          ),
          const PopupMenuItem(value: 'delete', child: Text('Xóa thông báo')),
        ],
      ),
    ),
  );
}
