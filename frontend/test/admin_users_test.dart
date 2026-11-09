import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/admin/data/models/admin_user.dart';
import 'package:frontend/features/admin/data/repositories/admin_user_repository.dart';
import 'package:frontend/features/admin/presentation/pages/admin_users_page.dart';
import 'package:frontend/features/admin/presentation/widgets/admin_user_dialog.dart';
import 'package:frontend/features/admin/presentation/widgets/admin_create_user_dialog.dart';

AdminUser tenant({
  String name = 'Người thuê thử',
  String role = 'MEMBER',
  String status = 'ACTIVE',
}) => AdminUser(
  id: 7,
  fullName: name,
  email: 'tenant@example.com',
  phoneNumber: '0901234567',
  role: role,
  status: status,
  verified: true,
);

class MemoryUsers extends AdminUserRepository {
  MemoryUsers() : super(ApiClient());
  AdminUser user = tenant();
  bool fail = false;
  bool empty = false;
  int updates = 0;
  int creates = 0;
  bool failCreate = false;
  Completer<void>? pendingCreate;
  final statuses = <String>[];
  final searches = <Map<String, dynamic>>[];
  Completer<AdminUserPage>? slow;

  @override
  Future<AdminUserPage> search({
    String query = '',
    String? role,
    String? status,
    bool? verified,
    int page = 0,
  }) async {
    searches.add({
      'query': query,
      'role': role,
      'status': status,
      'verified': verified,
      'page': page,
    });
    if (slow != null) {
      final pending = slow!;
      slow = null;
      return pending.future;
    }
    if (fail) throw StateError('offline');
    return AdminUserPage(
      empty ? [] : [user],
      empty ? 0 : 21,
      page,
      empty ? 0 : 2,
    );
  }

  @override
  Future<AdminUser> create({
    required String fullName,
    required String email,
    String phone = '',
    required String password,
    required String role,
  }) async {
    creates++;
    if (pendingCreate != null) await pendingCreate!.future;
    if (failCreate) {
      throw DioException(
        requestOptions: RequestOptions(),
        response: Response(
          requestOptions: RequestOptions(),
          statusCode: 409,
          data: {'message': 'Email đã được sử dụng.'},
        ),
      );
    }
    user = AdminUser(
      id: 8,
      fullName: fullName.trim(),
      email: email.trim().toLowerCase(),
      phoneNumber: phone,
      role: role,
      status: 'ACTIVE',
      verified: false,
    );
    return user;
  }

  @override
  Future<AdminUser> detail(int id) async => user;

  @override
  Future<void> update(
    int id,
    String fullName,
    String phone,
    String role,
  ) async {
    if (fail) {
      throw DioException(
        requestOptions: RequestOptions(),
        response: Response(
          requestOptions: RequestOptions(),
          statusCode: 409,
          data: {'message': 'Số điện thoại đã được sử dụng.'},
        ),
      );
    }
    updates++;
    user = tenant(name: fullName.trim(), role: role, status: user.status);
  }

  @override
  Future<void> changeStatus(int id, String status) async {
    statuses.add(status);
    user = tenant(name: user.fullName, role: user.role, status: status);
  }
}

Future<void> openPage(
  WidgetTester tester,
  MemoryUsers repository, {
  double width = 1300,
  double scale = 1,
  Brightness brightness = Brightness.light,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 1100);
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(brightness: brightness),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: Scaffold(body: AdminUsersPage(repository: repository)),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> fillNewUser(WidgetTester tester) async {
  await tester.enterText(
    find.byKey(const ValueKey('new-user-name')),
    'Người dùng mới',
  );
  await tester.enterText(
    find.byKey(const ValueKey('new-user-email')),
    'new@example.com',
  );
  await tester.enterText(
    find.byKey(const ValueKey('new-user-phone')),
    '0901234568',
  );
  await tester.enterText(
    find.byKey(const ValueKey('new-user-password')),
    'Password123!',
  );
  await tester.enterText(
    find.byKey(const ValueKey('new-user-confirm')),
    'Password123!',
  );
}

void main() {
  testWidgets(
    'Create member reloads the first page and displays pending verification',
    (tester) async {
      final repository = MemoryUsers();
      await openPage(tester, repository);
      await tester.enterText(find.byType(TextField).first, 'old search');
      await tester.tap(find.byTooltip('Tìm kiếm'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Thêm người dùng'));
      await tester.pumpAndSettle();
      await fillNewUser(tester);
      expect(
        find.text('Vai trò: Member · Có thể thuê nhà và đăng tin cho thuê.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Tạo và gửi OTP'));
      await tester.pumpAndSettle();
      expect(repository.creates, 1);
      expect(repository.user.role, 'MEMBER');
      expect(repository.user.verified, isFalse);
      expect(repository.searches.last['query'], '');
      expect(repository.searches.last['page'], 0);
      expect(find.text('Người dùng mới'), findsOneWidget);
      expect(find.text('Chưa xác thực'), findsOneWidget);
    },
  );

  testWidgets(
    'Create validates fields and keeps input after a server failure',
    (tester) async {
      final repository = MemoryUsers();
      await openPage(tester, repository);
      await tester.tap(find.text('Thêm người dùng'));
      await tester.pumpAndSettle();
      await fillNewUser(tester);
      await tester.enterText(
        find.byKey(const ValueKey('new-user-email')),
        'invalid',
      );
      await tester.enterText(
        find.byKey(const ValueKey('new-user-confirm')),
        'different',
      );
      await tester.tap(find.text('Tạo và gửi OTP'));
      await tester.pumpAndSettle();
      expect(repository.creates, 0);
      expect(find.text('Email không hợp lệ.'), findsOneWidget);
      expect(find.text('Mật khẩu nhập lại chưa khớp.'), findsOneWidget);
      await fillNewUser(tester);
      repository.failCreate = true;
      await tester.tap(find.text('Tạo và gửi OTP'));
      await tester.pumpAndSettle();
      expect(find.text('Email đã được sử dụng.'), findsOneWidget);
      expect(
        tester
            .widget<TextFormField>(find.byKey(const ValueKey('new-user-email')))
            .controller!
            .text,
        'new@example.com',
      );
      repository.failCreate = false;
      await tester.tap(find.text('Tạo và gửi OTP'));
      await tester.pumpAndSettle();
      expect(repository.creates, 2);
      expect(find.byType(AdminCreateUserDialog), findsNothing);
    },
  );

  testWidgets('Pending creation disables repeat submission and cancellation', (
    tester,
  ) async {
    final repository = MemoryUsers()..pendingCreate = Completer<void>();
    await openPage(tester, repository);
    await tester.tap(find.text('Thêm người dùng'));
    await tester.pumpAndSettle();
    await fillNewUser(tester);
    await tester.tap(find.text('Tạo và gửi OTP'));
    await tester.pumpAndSettle();
    expect(repository.creates, 1);
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Đang tạo và gửi OTP...'),
          )
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<TextButton>(find.widgetWithText(TextButton, 'Hủy'))
          .onPressed,
      isNull,
    );
    repository.pendingCreate!.complete();
    await tester.pumpAndSettle();
    expect(repository.creates, 1);
    expect(find.byType(AdminCreateUserDialog), findsNothing);
  });

  testWidgets(
    'Cancel does not create an account and compact form does not overflow',
    (tester) async {
      final repository = MemoryUsers();
      await openPage(
        tester,
        repository,
        width: 320,
        scale: 1.5,
        brightness: Brightness.dark,
      );
      await tester.tap(find.text('Thêm người dùng'));
      await tester.pumpAndSettle();
      expect(find.byType(AdminCreateUserDialog), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Hủy'));
      await tester.pumpAndSettle();
      expect(repository.creates, 0);
    },
  );

  testWidgets('Search, filters and pagination send the current criteria', (
    tester,
  ) async {
    final repository = MemoryUsers();
    await openPage(tester, repository);
    expect(find.byType(DataTable), findsOneWidget);
    await tester.tap(find.byTooltip('Trang sau'));
    await tester.pumpAndSettle();
    expect(repository.searches.last['page'], 1);
    await tester.enterText(find.byType(TextField).first, '090123');
    await tester.tap(find.byTooltip('Tìm kiếm'));
    await tester.pumpAndSettle();
    expect(repository.searches.last['query'], '090123');
    expect(repository.searches.last['page'], 0);
    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Member').last);
    await tester.pumpAndSettle();
    expect(repository.searches.last['role'], 'MEMBER');
    await tester.tap(find.text('Xóa bộ lọc'));
    await tester.pumpAndSettle();
    expect(repository.searches.last['role'], isNull);
    expect(repository.searches.last['query'], '');
  });

  testWidgets('Lock and unlock need confirmation and refresh the status', (
    tester,
  ) async {
    final repository = MemoryUsers();
    await openPage(tester, repository);
    await tester.ensureVisible(find.byTooltip('Khóa tài khoản'));
    await tester.tap(find.byTooltip('Khóa tài khoản'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hủy'));
    await tester.pumpAndSettle();
    expect(repository.statuses, isEmpty);
    await tester.ensureVisible(find.byTooltip('Khóa tài khoản'));
    await tester.tap(find.byTooltip('Khóa tài khoản'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Khóa'));
    await tester.pumpAndSettle();
    expect(repository.statuses, ['LOCKED']);
    expect(find.text('Đã khóa'), findsOneWidget);
    await tester.ensureVisible(find.byTooltip('Mở khóa'));
    await tester.tap(find.byTooltip('Mở khóa'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Mở khóa'));
    await tester.pumpAndSettle();
    expect(repository.statuses, ['LOCKED', 'ACTIVE']);
    expect(find.text('Hoạt động'), findsOneWidget);
  });

  testWidgets(
    'Edit validates the name and shows server errors before a successful retry',
    (tester) async {
      final repository = MemoryUsers();
      await openPage(tester, repository);
      await tester.ensureVisible(find.byTooltip('Chỉnh sửa'));
      await tester.tap(find.byTooltip('Chỉnh sửa'));
      await tester.pumpAndSettle();
      final fields = find.descendant(
        of: find.byType(AdminUserDialog),
        matching: find.byType(TextFormField),
      );
      await tester.enterText(fields.first, '');
      await tester.tap(find.text('Lưu thay đổi'));
      await tester.pumpAndSettle();
      expect(repository.updates, 0);
      expect(find.text('Vui lòng nhập họ và tên.'), findsOneWidget);
      await tester.enterText(fields.first, 'Tên đã sửa');
      repository.fail = true;
      await tester.tap(find.text('Lưu thay đổi'));
      await tester.pumpAndSettle();
      expect(find.text('Số điện thoại đã được sử dụng.'), findsOneWidget);
      repository.fail = false;
      await tester.tap(find.text('Lưu thay đổi'));
      await tester.pumpAndSettle();
      expect(repository.updates, 1);
      expect(find.text('Tên đã sửa'), findsOneWidget);
      expect(find.byType(AdminUserDialog), findsNothing);
    },
  );

  testWidgets(
    'Admin accounts can be inspected but cannot be edited or locked',
    (tester) async {
      final repository = MemoryUsers()..user = tenant(role: 'ADMIN');
      await openPage(tester, repository);
      expect(
        tester
            .widget<IconButton>(
              find.widgetWithIcon(IconButton, Icons.edit_outlined),
            )
            .onPressed,
        isNull,
      );
      expect(
        tester
            .widget<IconButton>(
              find.widgetWithIcon(IconButton, Icons.lock_outline_rounded),
            )
            .onPressed,
        isNull,
      );
      await tester.ensureVisible(find.byTooltip('Xem chi tiết'));
      await tester.tap(find.byTooltip('Xem chi tiết'));
      await tester.pumpAndSettle();
      expect(
        find.text('Tài khoản Admin chỉ được xem tại trang này.'),
        findsOneWidget,
      );
      expect(find.text('Lưu thay đổi'), findsNothing);
    },
  );

  testWidgets('Load error supports retry and the empty state is clear', (
    tester,
  ) async {
    final repository = MemoryUsers()..fail = true;
    await openPage(tester, repository);
    expect(find.text('Thử lại'), findsOneWidget);
    repository.fail = false;
    repository.empty = true;
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(find.text('Không có người dùng phù hợp.'), findsOneWidget);
  });

  testWidgets('An older search cannot replace a newer result', (tester) async {
    final repository = MemoryUsers();
    await openPage(tester, repository);
    final pending = Completer<AdminUserPage>();
    repository.slow = pending;
    await tester.enterText(find.byType(TextField).first, 'old');
    await tester.tap(find.byTooltip('Tìm kiếm'));
    await tester.pump();
    repository.user = tenant(name: 'Kết quả mới');
    await tester.enterText(find.byType(TextField).first, 'new');
    await tester.tap(find.byTooltip('Tìm kiếm'));
    await tester.pumpAndSettle();
    pending.complete(AdminUserPage([tenant(name: 'Kết quả cũ')], 1, 0, 1));
    await tester.pumpAndSettle();
    expect(find.text('Kết quả mới'), findsOneWidget);
    expect(find.text('Kết quả cũ'), findsNothing);
  });

  testWidgets('Compact web and large text keep all actions accessible', (
    tester,
  ) async {
    final repository = MemoryUsers();
    await openPage(tester, repository, width: 390);
    expect(find.byType(DataTable), findsNothing);
    await tester.ensureVisible(find.byTooltip('Xem chi tiết'));
    await tester.ensureVisible(find.byTooltip('Xem chi tiết'));
    await tester.tap(find.byTooltip('Xem chi tiết'));
    await tester.pumpAndSettle();
    expect(find.byType(AdminUserDialog), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Narrow screen and large text work in dark mode', (tester) async {
    await openPage(
      tester,
      MemoryUsers(),
      width: 320,
      scale: 1.5,
      brightness: Brightness.dark,
    );
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.byTooltip('Chỉnh sửa'));
    await tester.tap(find.byTooltip('Chỉnh sửa'));
    await tester.pumpAndSettle();
    expect(find.byType(AdminUserDialog), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
