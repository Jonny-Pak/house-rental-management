import '../../admin/presentation/pages/admin_dashboard_page.dart';

import 'package:flutter/material.dart';

import 'notification_card.dart';
import 'announcement_page.dart';

import '../../../core/network/api_client.dart';
import '../../../core/layout/app_layout.dart';
import '../../listing/data/repositories/listing_repository.dart';
import '../../listing/presentation/pages/my_listings_page.dart';
import '../../contract/data/repositories/contract_repository.dart';
import '../../contract/presentation/pages/my_contracts_page.dart';
import '../data/notification_repository.dart';
import 'notification_store.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key, this.store, this.admin = false});
  final NotificationStore? store;
  final bool admin;
  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late final store =
      widget.store ?? NotificationStore(NotificationRepository(ApiClient()));
  bool _busy = false;
  @override
  void initState() {
    super.initState();
    if (widget.store == null) {
      store.start();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) store.refresh();
      });
    }
  }

  @override
  void dispose() {
    if (widget.store == null) store.dispose();
    super.dispose();
  }

  void _error(Object error) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ListingRepository.errorMessage(error))),
      );
    }
  }

  Future<void> _readAll() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await store.markAllRead();
    } catch (error) {
      _error(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget? _destination(Notice notice) {
    if (notice.contractId != null) {
      return ContractDetailPage(
        id: notice.contractId!,
        repository: ContractRepository(ApiClient()),
      );
    }
    if (notice.listingId == null) return null;
    if (notice.type == 'LISTING_PENDING' && widget.admin) {
      return const AdminDashboardPage();
    }
    return const MyListingsPage();
  }

  Future<void> _open(Notice notice) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      if (!notice.read) {
        try {
          await store.markRead(notice.id);
        } catch (error) {
          _error(error);
        }
      }
      if (!mounted) return;
      final page = _destination(notice);
      final openPage = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(notice.title),
          content: SingleChildScrollView(child: Text(notice.content)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Đóng'),
            ),
            if (page != null)
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  notice.contractId != null ? 'Xem hợp đồng' : 'Xem tin đăng',
                ),
              ),
          ],
        ),
      );
      if (openPage == true && page != null && mounted) {
        await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
        await store.refresh();
      }
    } catch (error) {
      _error(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool> _confirmDelete(String title, String content) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(child: Text(content)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    return result == true;
  }

  Future<void> _action(Notice notice, String action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      if (action == 'delete') {
        final confirmed = await _confirmDelete('Xóa thông báo?', notice.title);
        if (!confirmed || !mounted) return;
        await store.delete(notice.id);
      } else if (action == 'unread') {
        await store.markUnread(notice.id);
      } else {
        await store.markRead(notice.id);
      }
    } catch (error) {
      _error(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deleteRead() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final confirmed = await _confirmDelete(
        'Xóa thông báo đã đọc?',
        'Chỉ xóa thông báo đã đọc của bạn. Các thông báo chưa đọc được giữ lại.',
      );
      if (!confirmed || !mounted) return;
      await store.deleteRead();
    } catch (error) {
      _error(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _compose() async {
    final sent = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AnnouncementPage(repository: store.repository),
      ),
    );
    if (sent == true) await store.refresh();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: store,
    builder: (context, _) => Scaffold(
      backgroundColor: const Color(0xFFFAF8F5),
      appBar: AppBar(
        title: const Text('Thông báo hệ thống'),
        actions: [
          if (widget.admin)
            IconButton(
              tooltip: 'Gửi thông báo chung',
              onPressed: _busy ? null : _compose,
              icon: const Icon(Icons.campaign_outlined),
            ),
          PopupMenuButton<String>(
            tooltip: 'Quản lý thông báo',
            enabled: !_busy,
            onSelected: (_) => _deleteRead(),
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'delete-read',
                child: Text('Xóa thông báo đã đọc'),
              ),
            ],
          ),
          IconButton(
            tooltip: 'Làm mới thông báo',
            onPressed: store.loading ? null : () => store.refresh(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: AppContent(
        maxWidth: AppLayout.formWidth,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 12,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ChoiceChip(
                    label: const Text('Tất cả'),
                    selected: !store.unreadOnly,
                    onSelected: (_) => store.filter(false),
                  ),
                  ChoiceChip(
                    label: Text('Chưa đọc (${store.unreadCount})'),
                    selected: store.unreadOnly,
                    onSelected: (_) => store.filter(true),
                  ),
                  TextButton.icon(
                    onPressed: _busy || store.unreadCount == 0
                        ? null
                        : _readAll,
                    icon: const Icon(Icons.done_all),
                    label: const Text('Đọc tất cả'),
                  ),
                ],
              ),
            ),
            if (store.loading) const LinearProgressIndicator(),
            if (store.error != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(store.error!),
                    TextButton(
                      onPressed: () => store.refresh(),
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => store.refresh(),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    if (!store.loading &&
                        store.error == null &&
                        store.items.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 70),
                        child: Column(
                          children: [
                            Icon(
                              Icons.notifications_none,
                              size: 56,
                              color: Color(0xFFAD8A68),
                            ),
                            SizedBox(height: 16),
                            Text('Chưa có thông báo nào.'),
                          ],
                        ),
                      ),
                    for (final notice in store.items)
                      NotificationCard(
                        notice: notice,
                        busy: _busy,
                        onOpen: () => _open(notice),
                        onAction: (action) => _action(notice, action),
                      ),
                    if (store.hasMore)
                      TextButton(
                        onPressed: store.loading
                            ? null
                            : () => store.refresh(more: true),
                        child: const Text('Xem thêm'),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
