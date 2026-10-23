import 'package:frontend/features/notification/presentation/announcement_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/home/presentation/pages/main_page.dart';

import 'profile_membership_test.dart' show ProfileRepository, member;

import 'package:frontend/features/notification/data/notification_repository.dart';
import 'package:frontend/features/notification/presentation/notification_store.dart';
import 'package:frontend/features/notification/presentation/notifications_page.dart';

class MemoryNotifications extends NotificationRepository {
  MemoryNotifications() : super(ApiClient());
  List<Notice> messages = [notice(1), notice(2)];
  bool fail = false, failRead = false, failAfterRead = false;
  int broadcasts = 0, fetches = 0;
  static Notice notice(int id, {bool read = false}) => Notice(
    id: id,
    type: 'SYSTEM',
    title: 'Thông báo $id',
    content: 'Nội dung thông báo tiếng Việt.',
    read: read,
    createdAt: DateTime(2026, 10, 22, 12),
  );
  @override
  Future<NotificationInbox> fetch(int page, bool unreadOnly) async {
    fetches++;
    if (fail) throw Exception('Không tải được thông báo');
    final selected = messages.where((n) => !unreadOnly || !n.read).toList();
    return NotificationInbox(
      selected.skip(page).take(1).toList(),
      await count(),
      page + 1 < selected.length,
    );
  }

  @override
  Future<int> count() async => messages.where((n) => !n.read).length;
  @override
  Future<void> read(int id) async {
    if (failRead) throw Exception('Chưa đánh dấu được');
    messages = messages.map((n) => n.id == id ? n.withRead(true) : n).toList();
    if (failAfterRead) fail = true;
  }

  @override
  Future<void> readAll() async {
    messages = messages.map((n) => n.withRead(true)).toList();
  }

  @override
  Future<void> unread(int id) async {
    if (failRead) throw Exception('Chưa đánh dấu được');
    messages = messages.map((n) => n.id == id ? n.withRead(false) : n).toList();
  }

  @override
  Future<void> delete(int id) async {
    if (failRead) throw Exception('Không xóa được thông báo');
    messages.removeWhere((n) => n.id == id);
  }

  @override
  Future<void> deleteRead() async {
    messages.removeWhere((n) => n.read);
  }

  @override
  Future<int> broadcast(String title, String content) async {
    broadcasts++;
    return 12;
  }
}

Widget inbox(NotificationStore store, {bool admin = false, double scale = 1}) =>
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: NotificationScope(
        store: store,
        child: NotificationsPage(store: store, admin: admin),
      ),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Failed unread filter does not display old read notices', () async {
    final repository = MemoryNotifications()
      ..messages = [MemoryNotifications.notice(1, read: true)];
    final store = NotificationStore(repository);
    await store.refresh();
    repository.fail = true;
    await store.filter(true);
    expect(store.items, isEmpty);
    expect(store.error, isNotNull);
    store.dispose();
  });

  test(
    'Read acknowledgement remains visible if the following reload fails',
    () async {
      final repository = MemoryNotifications()..failAfterRead = true;
      final store = NotificationStore(repository);
      await store.refresh();
      await store.markRead(1);
      expect(store.items.single.read, isTrue);
      expect(store.unreadCount, 1);
      expect(store.error, isNotNull);
      store.dispose();
    },
  );

  testWidgets('User can mark a read notice unread from the action menu', (
    tester,
  ) async {
    final repository = MemoryNotifications()
      ..messages = [MemoryNotifications.notice(1, read: true)];
    final store = NotificationStore(repository);
    addTearDown(store.dispose);
    await tester.pumpWidget(inbox(store));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('notice-actions-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Đánh dấu chưa đọc'));
    await tester.pumpAndSettle();
    expect(store.unreadCount, 1);
    expect(store.items.single.read, isFalse);
  });

  testWidgets(
    'Delete asks for confirmation and only removes the selected notice',
    (tester) async {
      final repository = MemoryNotifications();
      final store = NotificationStore(repository);
      addTearDown(store.dispose);
      await tester.pumpWidget(inbox(store));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('notice-actions-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Xóa thông báo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hủy'));
      await tester.pumpAndSettle();
      expect(repository.messages.length, 2);
      await tester.tap(find.byKey(const ValueKey('notice-actions-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Xóa thông báo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Xóa'));
      await tester.pumpAndSettle();
      expect(repository.messages.single.id, 2);
      expect(store.unreadCount, 1);
      expect(find.text('Thông báo 2'), findsOneWidget);
    },
  );

  testWidgets('Clear read notices keeps unread notices', (tester) async {
    final repository = MemoryNotifications()
      ..messages = [
        MemoryNotifications.notice(1, read: true),
        MemoryNotifications.notice(2),
      ];
    final store = NotificationStore(repository);
    addTearDown(store.dispose);
    await tester.pumpWidget(inbox(store));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Quản lý thông báo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xóa thông báo đã đọc'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xóa'));
    await tester.pumpAndSettle();
    expect(repository.messages.single.id, 2);
    expect(store.unreadCount, 1);
  });

  testWidgets('Contract notice displays full content before navigating', (
    tester,
  ) async {
    final repository = MemoryNotifications()
      ..messages = [
        Notice(
          id: 3,
          type: 'CONTRACT_CREATED',
          title: 'Hợp đồng mới',
          content: 'Kiểm tra toàn bộ nội dung trước khi xác nhận.',
          read: false,
          createdAt: DateTime(2026, 10, 23),
          contractId: 7,
        ),
      ];
    final store = NotificationStore(repository);
    addTearDown(store.dispose);
    await tester.pumpWidget(inbox(store));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hợp đồng mới'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('Xem hợp đồng'), findsOneWidget);
    expect(store.unreadCount, 0);
    await tester.tap(find.text('Đóng'));
    await tester.pumpAndSettle();
    expect(find.byType(NotificationsPage), findsOneWidget);
  });

  testWidgets('Home bell opens shared inbox and reading updates global count', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 950));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: MainPage(
          userRepository: ProfileRepository(member()),
          notificationRepository: MemoryNotifications(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Thông báo').first);
    await tester.pumpAndSettle();
    expect(find.byType(NotificationsPage), findsOneWidget);
    expect(find.text('Chưa đọc (2)'), findsOneWidget);
    await tester.tap(find.text('Đọc tất cả'));
    await tester.pumpAndSettle();
    expect(find.text('Chưa đọc (0)'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('Read flag from backend and navigation references parse correctly', () {
    final notice = Notice.fromJson({
      'id': 4,
      'type': 'CONTRACT_CREATED',
      'title': 'Hợp đồng',
      'content': 'Xác nhận',
      'read': true,
      'createdAt': '2026-10-22T12:00:00',
      'contractId': 7,
    });
    expect(notice.read, isTrue);
    expect(notice.contractId, 7);
    expect(notice.createdAt!.year, 2026);
  });

  test(
    'Store paginates filters and refreshes unread count after read',
    () async {
      final store = NotificationStore(MemoryNotifications());
      await store.refresh();
      expect(store.items.length, 1);
      expect(store.unreadCount, 2);
      await store.refresh(more: true);
      expect(store.items.map((n) => n.id), [1, 2]);
      await store.markRead(1);
      expect(store.unreadCount, 1);
      await store.filter(true);
      expect(store.items.single.id, 2);
      await store.markAllRead();
      expect(store.items, isEmpty);
      expect(store.unreadCount, 0);
      store.dispose();
    },
  );

  testWidgets('Open notice marks read and shows its full content', (
    tester,
  ) async {
    final store = NotificationStore(MemoryNotifications());
    addTearDown(store.dispose);
    await tester.pumpWidget(inbox(store));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Thông báo 1'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(store.unreadCount, 1);
    await tester.tap(find.text('Đóng'));
    await tester.pumpAndSettle();
    expect(find.text('Chưa đọc (1)'), findsOneWidget);
  });

  testWidgets('Read all and unread filter produce empty inbox', (tester) async {
    final store = NotificationStore(MemoryNotifications());
    addTearDown(store.dispose);
    await tester.pumpWidget(inbox(store));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Đọc tất cả'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chưa đọc (0)'));
    await tester.pumpAndSettle();
    expect(find.text('Chưa có thông báo nào.'), findsOneWidget);
  });

  testWidgets('Read failure preserves unread state and displays error', (
    tester,
  ) async {
    final repository = MemoryNotifications()..failRead = true;
    final store = NotificationStore(repository);
    addTearDown(store.dispose);
    await tester.pumpWidget(inbox(store));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Thông báo 1'));
    await tester.pumpAndSettle();
    expect(store.unreadCount, 2);
    expect(find.textContaining('Chưa đánh dấu được'), findsOneWidget);
    expect(find.byType(AlertDialog), findsOneWidget);
  });

  testWidgets('Loading error retries successfully', (tester) async {
    final repository = MemoryNotifications()..fail = true;
    final store = NotificationStore(repository);
    addTearDown(store.dispose);
    await tester.pumpWidget(inbox(store));
    await tester.pumpAndSettle();
    expect(find.text('Thử lại'), findsOneWidget);
    repository.fail = false;
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(find.text('Thông báo 1'), findsOneWidget);
  });

  testWidgets('Shared badge updates and polling stops on dispose', (
    tester,
  ) async {
    final repository = MemoryNotifications();
    final store = NotificationStore(repository)..start();
    await tester.pumpWidget(
      MaterialApp(
        home: NotificationScope(
          store: store,
          child: const NotificationBadge(child: Icon(Icons.notifications)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('2'), findsOneWidget);
    await store.markAllRead();
    await tester.pump();
    expect(find.text('2'), findsNothing);
    repository.messages = [MemoryNotifications.notice(3)];
    await tester.pump(const Duration(seconds: 31));
    await tester.pumpAndSettle();
    expect(store.unreadCount, 1);
    await tester.pumpWidget(const SizedBox.shrink());
    store.dispose();
  });

  testWidgets('Admin broadcast validates and requires confirmation', (
    tester,
  ) async {
    final repository = MemoryNotifications();
    await tester.pumpWidget(
      MaterialApp(home: AnnouncementPage(repository: repository)),
    );
    await tester.tap(find.text('Gửi thông báo'));
    await tester.pumpAndSettle();
    expect(repository.broadcasts, 0);
    expect(find.text('Nhập tiêu đề.'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(0), 'Bảo trì');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'Thông báo bảo trì cuối tuần',
    );
    await tester.ensureVisible(find.text('Gửi thông báo'));
    await tester.tap(find.text('Gửi thông báo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hủy'));
    await tester.pumpAndSettle();
    expect(repository.broadcasts, 0);
    await tester.tap(find.text('Gửi thông báo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xác nhận gửi'));
    await tester.pumpAndSettle();
    expect(repository.broadcasts, 1);
  });

  testWidgets('Inbox adapts to large text on phone tablet and desktop', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final store = NotificationStore(MemoryNotifications());
    addTearDown(store.dispose);
    for (final width in [320.0, 800.0, 1440.0]) {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.binding.setSurfaceSize(Size(width, 850));
      await tester.pumpWidget(inbox(store, admin: true, scale: 2));
      await tester.pumpAndSettle();
      expect(find.text('Thông báo 1'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });
}
