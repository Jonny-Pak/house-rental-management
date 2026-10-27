import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/incident/data/incident_repository.dart';
import 'package:frontend/features/incident/presentation/incidents_page.dart';
import 'package:frontend/features/incident/presentation/incident_detail_page.dart';
import 'package:frontend/features/home/presentation/pages/home_page.dart';
import 'package:frontend/features/notification/data/notification_repository.dart';
import 'package:frontend/features/notification/presentation/notification_store.dart';
import 'package:frontend/features/notification/presentation/notifications_page.dart';
import 'package:frontend/app/admin/router/routes.dart';

import 'notification_test.dart' show MemoryNotifications;

Map<String, dynamic> incidentRow(int id, {String status = 'OPEN'}) => {
  'id': id,
  'title': 'Không mở được bản đồ $id',
  'category': 'TECHNICAL',
  'description': 'Bấm bản đồ nhưng không tải được dữ liệu.',
  'status': status,
  'reporterId': 1,
  'reporterName': 'Người gửi thử',
  'reporterEmail': 'member@example.com',
  'createdAt': '2026-10-27T00:00:00',
  'updatedAt': '2026-10-27T00:00:00',
  'version': 0,
  'history': [
    {
      'id': 1,
      'actorName': 'Người gửi thử',
      'status': 'OPEN',
      'message': 'Đã gửi báo cáo sự cố.',
      'createdAt': '2026-10-27T00:00:00',
    },
  ],
};

class MemoryIncidents extends IncidentRepository {
  MemoryIncidents() : super(ApiClient());
  final rows = <int, Map<String, dynamic>>{};
  final keys = <String, int>{};
  bool failLoad = false, failCreate = false;
  int creates = 0, updates = 0;
  bool? lastAdmin;
  String? lastStatus, lastCategory, lastQuery;
  void failure(String message) => throw DioException(
    requestOptions: RequestOptions(),
    response: Response(
      requestOptions: RequestOptions(),
      statusCode: 409,
      data: {'message': message},
    ),
  );
  @override
  Future<IncidentPageData> fetch({
    bool admin = false,
    String query = '',
    String? status,
    String? category,
    int page = 0,
  }) async {
    lastAdmin = admin;
    lastStatus = status;
    lastCategory = category;
    lastQuery = query;
    if (failLoad) failure('Không tải được báo cáo.');
    final found = <Map<String, dynamic>>[];
    for (final row in rows.values) {
      if ((status == null || row['status'] == status) &&
          (category == null || row['category'] == category) &&
          row['title'].toString().contains(query)) {
        found.add(row);
      }
    }
    return IncidentPageData({
      'items': found.skip(page * 20).take(20).toList(),
      'total': found.length,
      'page': page,
      'totalPages': (found.length / 20).ceil(),
    });
  }

  @override
  Future<Incident> detail(int id, {bool admin = false}) async {
    lastAdmin = admin;
    if (failLoad || !rows.containsKey(id)) failure('Không tìm thấy báo cáo.');
    return Incident(rows[id]!);
  }

  @override
  Future<Incident> create(
    String requestKey,
    String title,
    String category,
    String description,
  ) async {
    creates++;
    if (failCreate) failure('Gửi báo cáo thất bại.');
    if (keys.containsKey(requestKey)) return Incident(rows[keys[requestKey]]!);
    final id = rows.length + 1;
    rows[id] = incidentRow(id)
      ..['title'] = title.trim()
      ..['description'] = description.trim()
      ..['category'] = category;
    keys[requestKey] = id;
    return Incident(rows[id]!);
  }

  @override
  Future<Incident> update(
    int id,
    int version,
    String status,
    String message,
  ) async {
    if (version != rows[id]!['version']) {
      failure('Báo cáo đã thay đổi. Hãy tải lại trước khi xử lý.');
    }
    updates++;
    rows[id]!['version'] = version + 1;
    rows[id]!['status'] = status;
    (rows[id]!['history'] as List).add({
      'id': version + 2,
      'actorName': 'Admin thử',
      'status': status,
      'message': message.trim(),
      'createdAt': '2026-10-27T01:00:00',
    });
    return Incident(rows[id]!);
  }
}

Future<void> open(
  WidgetTester tester,
  Widget page, {
  double width = 1200,
  double scale = 1,
}) async {
  await tester.binding.setSurfaceSize(Size(width, 1000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(
        brightness: width < 400 ? Brightness.dark : Brightness.light,
      ),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: page,
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> press(WidgetTester tester, String label) async {
  final finder = find.text(label).last;
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> fill(WidgetTester tester, String key, String value) async {
  final finder = find.byKey(ValueKey(key));
  await tester.ensureVisible(finder);
  await tester.enterText(finder, value);
  await tester.pump();
}

Future<void> selectStatus(WidgetTester tester, String label) async {
  final dropdown = find.byType(DropdownButtonFormField<String>).last;
  await tester.ensureVisible(dropdown);
  await tester.tap(dropdown);
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

void main() {
  test(
    'Admin menu includes incident processing',
    () => expect(kNav.any((item) => item.path == R.incidents), true),
  );

  testWidgets(
    'Member sends report, retries failed request and sees Admin response',
    (tester) async {
      final repo = MemoryIncidents();
      await open(tester, IncidentsPage(repository: repo));
      await press(tester, 'Gửi báo cáo mới');
      await press(tester, 'Gửi báo cáo');
      expect(repo.creates, 0);
      await fill(tester, 'incident-title', 'Lỗi bản đồ');
      await fill(tester, 'incident-description', 'Mô tả các bước gặp lỗi.');
      repo.failCreate = true;
      await press(tester, 'Gửi báo cáo');
      expect(find.text('Gửi báo cáo thất bại.'), findsOneWidget);
      expect(find.text('Mô tả các bước gặp lỗi.'), findsOneWidget);
      repo.failCreate = false;
      await press(tester, 'Gửi báo cáo');
      expect(find.byType(IncidentDetailPage), findsOneWidget);
      expect(find.text('Lịch sử xử lý'), findsOneWidget);
      expect(find.text('Gửi phản hồi'), findsNothing);
      await repo.update(1, 0, 'RESOLVED', 'Đã khắc phục, bạn thử lại nhé.');
      await tester.tap(find.byTooltip('Tải lại báo cáo'));
      await tester.pumpAndSettle();
      expect(find.text('Đã khắc phục, bạn thử lại nhé.'), findsOneWidget);
      expect(repo.rows.length, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Admin confirms reply, handles conflict, resolves and reopens report',
    (tester) async {
      final repo = MemoryIncidents()..rows[1] = incidentRow(1);
      await open(tester, IncidentsPage(admin: true, repository: repo));
      await press(tester, 'Xem và xử lý');
      await press(tester, 'Gửi phản hồi');
      expect(repo.updates, 0);
      await fill(tester, 'incident-reply', 'Đang kiểm tra lỗi.');
      await press(tester, 'Gửi phản hồi');
      await press(tester, 'Hủy');
      expect(repo.updates, 0);
      await press(tester, 'Gửi phản hồi');
      await press(tester, 'Xác nhận');
      expect(repo.updates, 1);
      await fill(tester, 'incident-reply', 'Đã giải quyết lỗi.');
      await selectStatus(tester, 'Đã giải quyết');
      repo.rows[1]!['version'] = 2;
      await press(tester, 'Gửi phản hồi');
      await press(tester, 'Xác nhận');
      expect(
        find.text('Báo cáo đã thay đổi. Hãy tải lại trước khi xử lý.'),
        findsOneWidget,
      );
      expect(find.text('Đã giải quyết lỗi.'), findsOneWidget);
      await press(tester, 'Thử tải lại');
      await selectStatus(tester, 'Đã giải quyết');
      await press(tester, 'Gửi phản hồi');
      await press(tester, 'Xác nhận');
      expect(repo.rows[1]!['status'], 'RESOLVED');
      expect(repo.updates, 2);
      await selectStatus(tester, 'Đang xử lý');
      await fill(tester, 'incident-reply', 'Mở lại để kiểm tra thêm.');
      await press(tester, 'Gửi phản hồi');
      await press(tester, 'Xác nhận');
      expect(repo.rows[1]!['status'], 'IN_PROGRESS');
      expect(repo.updates, 3);
      expect(find.text('Đang kiểm tra lỗi.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Filter, pagination and load retry use repository parameters', (
    tester,
  ) async {
    final repo = MemoryIncidents();
    for (int i = 1; i <= 22; i++) {
      repo.rows[i] = incidentRow(i);
    }
    await open(tester, IncidentsPage(admin: true, repository: repo));
    await tester.ensureVisible(find.byTooltip('Trang sau'));
    await tester.tap(find.byTooltip('Trang sau'));
    await tester.pumpAndSettle();
    expect(find.text('Trang 2/2'), findsOneWidget);
    await tester.ensureVisible(
      find.byType(DropdownButtonFormField<String>).first,
    );
    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Đã giải quyết').last);
    await tester.pumpAndSettle();
    expect(repo.lastStatus, 'RESOLVED');
    expect(find.text('Chưa có báo cáo phù hợp.'), findsOneWidget);
    repo.failLoad = true;
    await press(tester, 'Làm mới');
    expect(find.text('Không tải được báo cáo.'), findsOneWidget);
    repo.failLoad = false;
    await press(tester, 'Thử lại');
    expect(repo.lastAdmin, true);
    await press(tester, 'Xóa bộ lọc');
    expect(repo.lastStatus, isNull);
    await fill(tester, 'incident-search', 'bản đồ 22');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.text('1 báo cáo phù hợp'), findsOneWidget);
  });

  testWidgets(
    'Home opens incident reports and narrow enlarged form does not overflow',
    (tester) async {
      final repo = MemoryIncidents();
      await open(
        tester,
        Scaffold(body: HomePage(incidentRepository: repo)),
        width: 320,
        scale: 1.5,
      );
      await press(tester, 'Báo Cáo\nSự Cố');
      expect(find.byType(IncidentsPage), findsOneWidget);
      await press(tester, 'Gửi báo cáo mới');
      await fill(tester, 'incident-title', 'Lỗi');
      await fill(
        tester,
        'incident-description',
        'Mô tả sự cố trên điện thoại.',
      );
      await press(tester, 'Gửi báo cáo');
      expect(find.byType(IncidentDetailPage), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Incident notice keeps target after marking read and opens matching detail',
    (tester) async {
      final repo = MemoryIncidents()..rows[7] = incidentRow(7);
      final notices = MemoryNotifications()
        ..messages = [
          Notice(
            id: 9,
            type: 'INCIDENT_UPDATED',
            title: 'Phản hồi báo cáo',
            content: 'Đã xử lý.',
            read: false,
            createdAt: DateTime(2026, 10, 27),
            incidentId: 7,
          ),
        ];
      final store = NotificationStore(notices);
      addTearDown(store.dispose);
      await open(
        tester,
        NotificationsPage(store: store, incidentRepository: repo),
      );
      await press(tester, 'Phản hồi báo cáo');
      expect(find.text('Xem báo cáo'), findsOneWidget);
      await press(tester, 'Xem báo cáo');
      expect(
        tester.widget<IncidentDetailPage>(find.byType(IncidentDetailPage)).id,
        7,
      );
      expect(notices.messages.single.read, true);
      expect(notices.messages.single.incidentId, 7);
      expect(repo.lastAdmin, false);
    },
  );
}
