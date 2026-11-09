import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kite_ui/shadcn.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/app/admin/auth/session.dart';
import 'package:frontend/app/admin/router/routes.dart';
import 'package:frontend/app/admin/theme/app_theme.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/core/storage/token_storage.dart';
import 'package:frontend/features/admin/presentation/screens/auth/auth_screens.dart';
import 'package:frontend/features/auth/data/models/auth_models.dart';
import 'package:frontend/features/auth/data/qr_login_repository.dart';
import 'package:frontend/features/auth/presentation/widgets/qr_login_panel.dart';
import 'package:frontend/features/auth/presentation/pages/qr_login_confirmation_page.dart';
import 'package:frontend/features/auth/presentation/pages/qr_login_scanner_page.dart';
import 'package:frontend/features/home/presentation/widgets/user_navigation_drawer.dart';
import 'package:frontend/features/user/data/models/user_profile.dart';

import 'profile_membership_test.dart' as profiles;

const qrId = '11111111-1111-4111-8111-111111111111';
final scanToken = 's' * 43;
final browserSecret = 'b' * 43;
final qrData = 'houserental://admin-login/$qrId?token=$scanToken';
const adminAuth = AuthResponse(
  accessToken: 'web-access',
  refreshToken: 'web-refresh',
  userId: 2,
  role: 'ADMIN',
);

class QrRepository extends QrLoginRepository {
  QrRepository() : super(ApiClient());
  int starts = 0, polls = 0, consumes = 0, cancels = 0, previews = 0;
  bool failStart = false,
      failStatus = false,
      failPreview = false,
      failDecision = false;
  String current = 'PENDING';
  final decisions = <bool>[];
  Completer<void>? decisionGate;
  @override
  Future<QrLoginSession> start() async {
    starts++;
    if (failStart) throw Exception('Chưa tạo được QR');
    return QrLoginSession(
      id: qrId,
      browserSecret: browserSecret,
      qrData: qrData,
      verificationCode: '123456',
      expiresAt: DateTime.now().add(const Duration(minutes: 2)),
    );
  }

  @override
  Future<String> status(QrLoginSession session) async {
    expect(session.browserSecret, browserSecret);
    polls++;
    if (failStatus) throw Exception('Mất kết nối');
    return current;
  }

  @override
  Future<AuthResponse> consume(QrLoginSession session) async {
    consumes++;
    return adminAuth;
  }

  @override
  Future<void> cancel(QrLoginSession session) async {
    cancels++;
  }

  @override
  Future<QrLoginPreview> preview(QrLoginCode code) async {
    previews++;
    if (failPreview) throw Exception('Chỉ Admin mới được xác nhận QR');
    return QrLoginPreview(
      website: 'http://localhost:8081',
      browserName: 'Chrome trên Windows',
      verificationCode: '123456',
      expiresAt: DateTime.now().add(const Duration(minutes: 2)),
    );
  }

  @override
  Future<void> decide(QrLoginCode code, bool approve) async {
    decisions.add(approve);
    if (decisionGate != null) await decisionGate!.future;
    if (failDecision) throw Exception('Phiên QR đã hết hạn');
    current = approve ? 'APPROVED' : 'REJECTED';
  }
}

class QrSession extends SessionController {
  AuthResponse? received;
  @override
  SessionUser? build() => null;
  @override
  Future<void> signInWithQr(AuthResponse auth, {ApiClient? client}) async {
    received = auth;
    state = const SessionUser(name: 'Admin', email: 'admin@example.com');
  }
}

class QrProfileApi extends ApiClient {
  String role = 'ADMIN';
  @override
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParams,
  }) async => Response(
    requestOptions: RequestOptions(path: path),
    statusCode: 200,
    data: {
      'data': {
        'id': 2,
        'fullName': 'Admin',
        'email': 'admin@example.com',
        'role': role,
      },
    },
  );
}

Future<void> openConfirmation(
  WidgetTester tester,
  QrRepository repository,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => QrLoginConfirmationPage(
                  code: QrLoginCode(qrId, scanToken),
                  repository: repository,
                ),
              ),
            ),
            child: const Text('Mở xác nhận'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Mở xác nhận'));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'Only QR data for this application is accepted, with one valid scan token',
    () {
      expect(QrLoginCode.parse(qrData).id, qrId);
      expect(QrLoginCode.parse(qrData).scanToken, scanToken);
      for (final text in [
        'https://attacker.example',
        'houserental://admin-login/$qrId',
        '$qrData&token=$scanToken',
        qrData.replaceFirst(qrId, 'bad-id'),
        'x' * 513,
      ]) {
        expect(() => QrLoginCode.parse(text), throwsFormatException);
      }
    },
  );

  testWidgets(
    'Browser waits for approval, consumes once and cancels nothing after success',
    (tester) async {
      final repository = QrRepository();
      final done = Completer<void>();
      AuthResponse? received;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QrLoginPanel(
              repository: repository,
              onCancel: () {},
              onAuthenticated: (auth) {
                received = auth;
                return done.future;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Mã đối chiếu: 123456'), findsOneWidget);
      repository.current = 'SCANNED';
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(find.text('Đã quét mã. Hãy xác nhận trên app.'), findsOneWidget);
      expect(repository.consumes, 0);
      repository.current = 'APPROVED';
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();
      expect(repository.consumes, 1);
      expect(received?.role, 'ADMIN');
      await tester.pump(const Duration(seconds: 6));
      expect(repository.consumes, 1);
      done.complete();
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      expect(repository.cancels, 0);
    },
  );

  testWidgets(
    'Expired and rejected QR sessions never exchange tokens and can create a new code',
    (tester) async {
      final repository = QrRepository()..current = 'EXPIRED';
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QrLoginPanel(
              repository: repository,
              onCancel: () {},
              onAuthenticated: (_) async {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(find.text('Mã đã hết hạn. Hãy tạo mã mới.'), findsOneWidget);
      expect(repository.consumes, 0);
      repository.current = 'REJECTED';
      await tester.tap(find.text('Tạo mã QR mới'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(find.text('Bạn đã từ chối đăng nhập trên app.'), findsOneWidget);
      expect(repository.starts, 2);
      expect(repository.cancels, 1);
      expect(repository.consumes, 0);
    },
  );

  testWidgets(
    'Browser errors support retry and disposal cancels the pending session',
    (tester) async {
      final repository = QrRepository()..failStart = true;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QrLoginPanel(
              repository: repository,
              onCancel: () {},
              onAuthenticated: (_) async {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Chưa tạo được QR'), findsOneWidget);
      repository.failStart = false;
      await tester.tap(find.text('Tạo mã QR mới'));
      await tester.pumpAndSettle();
      repository.failStatus = true;
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(find.text('Mất kết nối'), findsOneWidget);
      final polls = repository.polls;
      await tester.pump(const Duration(seconds: 6));
      expect(repository.polls, polls);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      expect(repository.cancels, 1);
    },
  );

  testWidgets(
    'Phone displays origin, browser and comparison code before confirming or rejecting',
    (tester) async {
      final repository = QrRepository();
      await openConfirmation(tester, repository);
      expect(find.text('http://localhost:8081'), findsOneWidget);
      expect(find.text('Chrome trên Windows'), findsOneWidget);
      expect(find.text('123456'), findsOneWidget);
      expect(repository.decisions, isEmpty);
      await tester.scrollUntilVisible(
        find.text('Từ chối'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Từ chối'));
      await tester.pumpAndSettle();
      expect(repository.decisions, [false]);
      expect(find.text('Mở xác nhận'), findsOneWidget);
    },
  );

  testWidgets(
    'Phone blocks repeated approval while saving and preserves errors for retry',
    (tester) async {
      final repository = QrRepository()..decisionGate = Completer<void>();
      await openConfirmation(tester, repository);
      await tester.ensureVisible(find.text('Xác nhận đăng nhập'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Xác nhận đăng nhập'));
      await tester.pump();
      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Đang xử lý…'),
      );
      expect(button.onPressed, isNull);
      expect(repository.decisions, [true]);
      repository.failDecision = true;
      repository.decisionGate!.complete();
      await tester.pumpAndSettle();
      expect(find.text('Phiên QR đã hết hạn'), findsOneWidget);
      expect(find.text('Xác nhận đăng nhập'), findsOneWidget);
    },
  );

  testWidgets(
    'A denied preview has no approval button and can retry after reauthentication',
    (tester) async {
      final repository = QrRepository()..failPreview = true;
      await openConfirmation(tester, repository);
      expect(find.text('Chỉ Admin mới được xác nhận QR'), findsOneWidget);
      expect(find.text('Xác nhận đăng nhập'), findsNothing);
      repository.failPreview = false;
      await tester.tap(find.text('Thử lại'));
      await tester.pumpAndSettle();
      expect(find.text('Xác nhận đăng nhập'), findsOneWidget);
    },
  );

  testWidgets(
    'Manual scanner rejects unrelated QR content before contacting the server',
    (tester) async {
      final repository = QrRepository();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QrLoginScannerPage(
              repository: repository,
              enableCamera: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Nhập nội dung mã QR'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextField),
        'https://attacker.example',
      );
      await tester.tap(find.text('Kiểm tra mã'));
      await tester.pumpAndSettle();
      expect(
        find.text('Đây không phải mã đăng nhập Rental Admin.'),
        findsOneWidget,
      );
      expect(repository.previews, 0);
    },
  );

  testWidgets('QR controls fit a narrow display with enlarged text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 850);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: QrLoginPanel(
              repository: QrRepository(),
              onCancel: () {},
              onAuthenticated: (_) async {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Only Admin sees scanner actions in profile and drawer', (
    tester,
  ) async {
    for (final role in ['MEMBER', 'ADMIN']) {
      final profile = UserProfile(
        id: 2,
        fullName: 'Tài khoản',
        email: 'admin@example.com',
        role: role,
      );
      await tester.pumpWidget(profiles.page(profile));
      await tester.pumpAndSettle();
      expect(
        find.text('Quét QR đăng nhập Admin'),
        role == 'ADMIN' ? findsOneWidget : findsNothing,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: UserNavigationDrawer(
            selectedAction: 'home',
            profile: profile,
            onAction: (_) {},
            onClose: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      if (role == 'ADMIN') {
        await tester.scrollUntilVisible(
          find.byKey(const ValueKey('drawer-qr-login')),
          250,
        );
        await tester.pumpAndSettle();
      } else {
        await tester.drag(find.byType(ListView), const Offset(0, -1400));
        await tester.pumpAndSettle();
      }
      expect(
        find.byKey(const ValueKey('drawer-qr-login')),
        role == 'ADMIN' ? findsOneWidget : findsNothing,
      );
    }
  });

  testWidgets(
    'Admin sign-in switches between email and QR and passes the exchanged session',
    (tester) async {
      final session = QrSession();
      final repository = QrRepository();
      final router = GoRouter(
        initialLocation: R.signIn,
        routes: [
          GoRoute(
            path: R.signIn,
            builder: (_, _) => SignInScreen(qrRepository: repository),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [sessionProvider.overrideWith(() => session)],
          child: ShadApp.router(
            theme: const ThemeState().data(Brightness.light),
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Đăng nhập bằng QR'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Đăng nhập bằng QR'));
      await tester.pumpAndSettle();
      expect(find.text('Mã đối chiếu: 123456'), findsOneWidget);
      await tester.ensureVisible(find.text('Dùng email và mật khẩu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dùng email và mật khẩu'));
      await tester.pumpAndSettle();
      expect(repository.cancels, 1);
      await tester.ensureVisible(find.text('Đăng nhập bằng QR'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Đăng nhập bằng QR'));
      await tester.pumpAndSettle();
      repository.current = 'APPROVED';
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(session.received?.userId, 2);
      expect(session.received?.role, 'ADMIN');
    },
  );

  test(
    'Browser stores only an Admin session and validates the returned account',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(sessionProvider);
      await Future<void>.delayed(Duration.zero);
      final session = container.read(sessionProvider.notifier);
      final api = QrProfileApi();
      await session.signInWithQr(adminAuth, client: api);
      expect(await TokenStorage.getToken(), 'web-access');
      expect(container.read(sessionProvider)?.role, 'ADMIN');
      api.role = 'MEMBER';
      await expectLater(
        session.signInWithQr(adminAuth, client: api),
        throwsException,
      );
      expect(await TokenStorage.getToken(), isNull);
      await expectLater(
        session.signInWithQr(
          const AuthResponse(
            accessToken: 'member',
            refreshToken: '',
            userId: 2,
            role: 'MEMBER',
          ),
          client: api,
        ),
        throwsException,
      );
      expect(await TokenStorage.getToken(), isNull);
    },
  );
}
