import 'dart:async';

import 'package:flutter/material.dart';

import '../../listing/data/repositories/listing_repository.dart';
import '../data/notification_repository.dart';

class NotificationStore extends ChangeNotifier with WidgetsBindingObserver {
  NotificationStore(this.repository);
  final NotificationRepository repository;
  List<Notice> items = [];
  int unreadCount = 0, _page = 0, _request = 0;
  bool loading = false, hasMore = false, unreadOnly = false, _disposed = false;
  String? error;
  Timer? _timer;

  void start() {
    WidgetsBinding.instance.addObserver(this);
    refresh();
    _poll();
  }

  void _poll() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => refreshCount());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      refresh();
      _poll();
    } else {
      _timer?.cancel();
    }
  }

  Future<void> refreshCount() async {
    try {
      final count = await repository.count();
      if (_disposed) return;
      if (count != unreadCount) await refresh();
    } catch (_) {}
  }

  Future<void> refresh({bool more = false}) async {
    if (_disposed || (more && loading)) return;
    final request = ++_request;
    final page = more ? _page + 1 : 0;
    loading = true;
    error = null;
    notifyListeners();
    try {
      final inbox = await repository.fetch(page, unreadOnly);
      if (_disposed || request != _request) return;
      items = more ? [...items, ...inbox.items] : inbox.items;
      unreadCount = inbox.unreadCount;
      hasMore = inbox.hasMore;
      _page = page;
    } catch (failure) {
      if (!_disposed && request == _request) {
        error = ListingRepository.errorMessage(failure);
      }
    } finally {
      if (!_disposed && request == _request) {
        loading = false;
        notifyListeners();
      }
    }
  }

  Future<void> filter(bool value) async {
    if (unreadOnly == value) return;
    unreadOnly = value;
    items = [];
    _page = 0;
    hasMore = false;
    await refresh();
  }

  Future<void> markRead(int id) async {
    await repository.read(id);
    _setRead(id, true);
    await refresh();
  }

  Future<void> markAllRead() async {
    await repository.readAll();
    if (_disposed) return;
    _request++;
    items = unreadOnly
        ? []
        : items.map((notice) => notice.withRead(true)).toList();
    unreadCount = 0;
    notifyListeners();
    await refresh();
  }

  Future<void> markUnread(int id) async {
    await repository.unread(id);
    _setRead(id, false);
    await refresh();
  }

  void _setRead(int id, bool read) {
    if (_disposed) return;
    _request++;
    final updated = <Notice>[];
    for (final notice in items) {
      if (notice.id != id) {
        updated.add(notice);
        continue;
      }
      if (notice.read != read) unreadCount += read ? -1 : 1;
      if (!unreadOnly || !read) updated.add(notice.withRead(read));
    }
    items = updated;
    if (unreadCount < 0) unreadCount = 0;
    notifyListeners();
  }

  Future<void> delete(int id) async {
    await repository.delete(id);
    if (_disposed) return;
    _request++;
    final remaining = <Notice>[];
    for (final notice in items) {
      if (notice.id == id) {
        if (!notice.read && unreadCount > 0) unreadCount--;
      } else {
        remaining.add(notice);
      }
    }
    items = remaining;
    notifyListeners();
    await refresh();
  }

  Future<void> deleteRead() async {
    await repository.deleteRead();
    if (_disposed) return;
    _request++;
    items = items.where((notice) => !notice.read).toList();
    notifyListeners();
    await refresh();
  }

  @override
  void dispose() {
    _disposed = true;
    _request++;
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}

class NotificationScope extends InheritedNotifier<NotificationStore> {
  const NotificationScope({
    super.key,
    required NotificationStore store,
    required super.child,
  }) : super(notifier: store);
  static NotificationStore? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<NotificationScope>()?.notifier;
}

class NotificationBadge extends StatelessWidget {
  const NotificationBadge({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final count = NotificationScope.of(context)?.unreadCount ?? 0;
    return Badge(
      label: Text(count > 99 ? '99+' : '$count'),
      isLabelVisible: count > 0,
      child: child,
    );
  }
}
