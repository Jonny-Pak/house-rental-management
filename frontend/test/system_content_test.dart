import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/admin/presentation/pages/admin_content_page.dart';
import 'package:frontend/features/content/data/models/system_content.dart';
import 'package:frontend/features/content/data/repositories/system_content_repository.dart';
import 'package:frontend/features/content/presentation/content_article.dart';
import 'package:frontend/features/content/presentation/system_content_page.dart';
import 'package:frontend/features/home/presentation/pages/home_page.dart';
import 'package:frontend/app/admin/router/routes.dart';

DioException contentFailure(String message, {int code = 409}) => DioException(
  requestOptions: RequestOptions(path: '/content'),
  response: Response(
    requestOptions: RequestOptions(path: '/content'),
    statusCode: code,
    data: {'message': message},
  ),
);

class MemoryContent extends SystemContentRepository {
  MemoryContent() : super(ApiClient()) {
    for (final e in contentPages.entries) {
      drafts[e.key] = SystemContent(
        slug: e.key,
        title: 'Tiêu đề ${e.key}',
        body: 'Nội dung công khai ban đầu.',
        published: true,
        hasDraft: false,
        version: 0,
      );
      publicPages[e.key] = PublishedContent(
        slug: e.key,
        title: 'Tiêu đề ${e.key}',
        body: 'Nội dung công khai ban đầu.',
      );
    }
  }
  final drafts = <String, SystemContent>{};
  final publicPages = <String, PublishedContent>{};
  int saves = 0, publishes = 0, hides = 0, publicReads = 0;
  bool failLoad = false;

  @override
  Future<List<SystemContent>> list() async {
    if (failLoad) throw contentFailure('Không tải được nội dung.');
    return drafts.values.toList();
  }

  @override
  Future<SystemContent> detail(String slug) async => drafts[slug]!;

  SystemContent store(
    String slug,
    String title,
    String body,
    int version, {
    bool publish = false,
  }) {
    final old = drafts[slug]!;
    if (old.version != version) {
      throw contentFailure(
        'Nội dung đã được Admin khác thay đổi. Hãy tải lại trước khi lưu.',
      );
    }
    if (publish) {
      publicPages[slug] = PublishedContent(
        slug: slug,
        title: title.trim(),
        body: body.trim(),
      );
    }
    final visible = publicPages[slug];
    final saved = SystemContent(
      slug: slug,
      title: title.trim(),
      body: body.trim(),
      published: publish || old.published,
      hasDraft: visible?.title != title.trim() || visible?.body != body.trim(),
      version: version + 1,
    );
    drafts[slug] = saved;
    return saved;
  }

  @override
  Future<SystemContent> saveDraft(
    String slug,
    String title,
    String body,
    int version,
  ) async {
    saves++;
    return store(slug, title, body, version);
  }

  @override
  Future<SystemContent> publish(
    String slug,
    String title,
    String body,
    int version,
  ) async {
    publishes++;
    return store(slug, title, body, version, publish: true);
  }

  @override
  Future<SystemContent> unpublish(String slug, int version) async {
    hides++;
    final old = drafts[slug]!;
    if (old.version != version) throw contentFailure('Nội dung đã thay đổi.');
    final hidden = SystemContent(
      slug: slug,
      title: old.title,
      body: old.body,
      published: false,
      hasDraft: old.hasDraft,
      version: version + 1,
    );
    drafts[slug] = hidden;
    return hidden;
  }

  @override
  Future<PublishedContent> published(String slug) async {
    publicReads++;
    if (drafts[slug]?.published != true) {
      throw contentFailure(
        'Nội dung hiện chưa được công bố hoặc không tồn tại.',
        code: 404,
      );
    }
    return publicPages[slug]!;
  }
}

Future<void> openEditor(
  WidgetTester tester,
  MemoryContent repository, {
  double width = 1500,
  double scale = 1,
}) async {
  await tester.binding.setSurfaceSize(Size(width, 1100));
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
      home: Scaffold(body: AdminContentPage(repository: repository)),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> press(WidgetTester tester, String text) async {
  await tester.pump();
  final finder = find.text(text).last;
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Public preview preserves unsaved draft', (tester) async {
    final repository = MemoryContent();
    await openEditor(tester, repository);
    await tester.enterText(
      find.byKey(const ValueKey('content-body')),
      'Bản đang soạn chưa lưu',
    );
    await press(tester, 'Xem bản công khai');
    final article = tester.widget<ContentArticle>(find.byType(ContentArticle));
    expect(article.body, 'Nội dung công khai ban đầu.');
    await press(tester, 'Đóng');
    expect(find.text('Bản đang soạn chưa lưu'), findsOneWidget);
    expect(repository.saves, 0);
    expect(repository.publishes, 0);
    expect(repository.publicReads, 1);
  });

  testWidgets('Leaving the editor requires discarding unsaved changes', (
    tester,
  ) async {
    final key = GlobalKey<AdminContentPageState>();
    final repository = MemoryContent();
    final router = GoRouter(
      initialLocation: '/content',
      routes: [
        GoRoute(
          path: '/content',
          builder: (_, _) => Scaffold(
            body: AdminContentPage(key: key, repository: repository),
          ),
          onExit: (_, _) async =>
              await key.currentState?.confirmLeave() ?? true,
        ),
        GoRoute(
          path: '/other',
          builder: (_, _) => const Scaffold(body: Text('Trang khác')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.binding.setSurfaceSize(const Size(1500, 1100));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('content-title')),
      'Chưa lưu',
    );
    router.go('/other');
    await tester.pumpAndSettle();
    expect(find.text('Bỏ thay đổi chưa lưu?'), findsOneWidget);
    await press(tester, 'Hủy');
    expect(find.byType(AdminContentPage), findsOneWidget);
    expect(find.text('Chưa lưu'), findsWidgets);
    router.go('/other');
    await tester.pumpAndSettle();
    await press(tester, 'Bỏ thay đổi');
    expect(find.text('Trang khác'), findsOneWidget);
  });

  test('System content is reachable from the Admin menu', () {
    expect(kNav.any((n) => n.path == R.content), true);
  });

  testWidgets(
    'Draft, preview, publish and unpublish keep public content separate',
    (tester) async {
      final repository = MemoryContent();
      await openEditor(tester, repository);
      await tester.enterText(
        find.byKey(const ValueKey('content-title')),
        'Giới thiệu cập nhật',
      );
      await tester.enterText(
        find.byKey(const ValueKey('content-body')),
        'Nội dung tiếng Việt mới.\nDòng thứ hai.',
      );
      await press(tester, 'Lưu nháp');
      expect(repository.saves, 1);
      expect(
        (await repository.published('about')).body,
        'Nội dung công khai ban đầu.',
      );
      expect(find.text('Có thay đổi nháp'), findsWidgets);
      await press(tester, 'Xem trước');
      final preview = tester.widget<ContentArticle>(
        find.byType(ContentArticle),
      );
      expect(preview.title, 'Giới thiệu cập nhật');
      expect(preview.body, contains('Dòng thứ hai.'));
      expect(repository.publishes, 0);
      await press(tester, 'Đóng');
      await press(tester, 'Xuất bản');
      await press(tester, 'Xác nhận');
      expect(repository.publishes, 1);
      expect(
        (await repository.published('about')).title,
        'Giới thiệu cập nhật',
      );
      await press(tester, 'Gỡ xuất bản');
      await press(tester, 'Xác nhận');
      expect(repository.hides, 1);
      await expectLater(
        repository.published('about'),
        throwsA(isA<DioException>()),
      );
      expect(repository.drafts['about']!.body, contains('Dòng thứ hai.'));
      await press(tester, 'Xuất bản');
      await press(tester, 'Xác nhận');
      expect(repository.drafts['about']!.published, true);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Blank content is rejected and switching sections protects unsaved input',
    (tester) async {
      final repository = MemoryContent();
      await openEditor(tester, repository);
      await tester.enterText(find.byKey(const ValueKey('content-title')), '');
      await tester.enterText(find.byKey(const ValueKey('content-body')), '');
      await press(tester, 'Lưu nháp');
      expect(find.text('Vui lòng nhập tiêu đề.'), findsOneWidget);
      expect(find.text('Vui lòng nhập nội dung.'), findsOneWidget);
      expect(repository.saves, 0);
      await press(tester, 'Quy định');
      expect(find.text('Bỏ thay đổi chưa lưu?'), findsOneWidget);
      await press(tester, 'Hủy');
      expect(
        tester
            .widget<TextFormField>(find.byKey(const ValueKey('content-title')))
            .controller!
            .text,
        '',
      );
      await press(tester, 'Quy định');
      await press(tester, 'Bỏ thay đổi');
      expect(
        tester
            .widget<TextFormField>(find.byKey(const ValueKey('content-title')))
            .controller!
            .text,
        'Tiêu đề rules',
      );
    },
  );

  testWidgets('Version conflict keeps user edits until an explicit reload', (
    tester,
  ) async {
    final repository = MemoryContent();
    await openEditor(tester, repository);
    repository.store(
      'about',
      'Bản của Admin khác',
      'Thay đổi từ Admin khác.',
      0,
    );
    await tester.enterText(
      find.byKey(const ValueKey('content-body')),
      'Nội dung đang soạn',
    );
    await press(tester, 'Lưu nháp');
    expect(
      find.text(
        'Nội dung đã được Admin khác thay đổi. Hãy tải lại trước khi lưu.',
      ),
      findsOneWidget,
    );
    expect(
      tester
          .widget<TextFormField>(find.byKey(const ValueKey('content-body')))
          .controller!
          .text,
      'Nội dung đang soạn',
    );
    await press(tester, 'Tải lại nội dung');
    await press(tester, 'Hủy');
    expect(
      tester
          .widget<TextFormField>(find.byKey(const ValueKey('content-body')))
          .controller!
          .text,
      'Nội dung đang soạn',
    );
    await press(tester, 'Tải lại nội dung');
    await press(tester, 'Bỏ thay đổi');
    expect(
      tester
          .widget<TextFormField>(find.byKey(const ValueKey('content-body')))
          .controller!
          .text,
      'Thay đổi từ Admin khác.',
    );
  });

  testWidgets('Loading errors can be retried', (tester) async {
    final repository = MemoryContent()..failLoad = true;
    await openEditor(tester, repository);
    expect(find.text('Không tải được nội dung.'), findsOneWidget);
    repository.failLoad = false;
    await press(tester, 'Thử lại');
    expect(find.byKey(const ValueKey('content-body')), findsOneWidget);
  });

  testWidgets(
    'Public page reloads published changes and does not show hidden content',
    (tester) async {
      final repository = MemoryContent();
      await tester.pumpWidget(
        MaterialApp(
          home: SystemContentPage(slug: 'about', repository: repository),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Nội dung công khai ban đầu.'), findsOneWidget);
      await repository.saveDraft(
        'about',
        'Bản nháp',
        'Nội dung bí mật nháp.',
        0,
      );
      await tester.tap(find.byTooltip('Tải lại nội dung'));
      await tester.pumpAndSettle();
      expect(find.text('Nội dung bí mật nháp.'), findsNothing);
      await repository.unpublish('about', 1);
      await tester.tap(find.byTooltip('Tải lại nội dung'));
      await tester.pumpAndSettle();
      expect(
        find.text('Nội dung hiện chưa được công bố hoặc không tồn tại.'),
        findsOneWidget,
      );
      expect(find.byType(ContentArticle), findsNothing);
      await repository.publish(
        'about',
        'Bản mới',
        'Nội dung mới đã công bố.',
        2,
      );
      await press(tester, 'Thử lại');
      expect(find.text('Nội dung mới đã công bố.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Home information actions open content from the server', (
    tester,
  ) async {
    final repository = MemoryContent();
    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: HomePage(contentRepository: repository)),
      ),
    );
    await tester.pumpAndSettle();
    await press(tester, 'Giới Thiệu');
    expect(find.byType(SystemContentPage), findsOneWidget);
    expect(repository.publicReads, 1);
    expect(find.text('Nội dung công khai ban đầu.'), findsOneWidget);
  });

  testWidgets('Narrow dark editor and preview remain usable with large text', (
    tester,
  ) async {
    await openEditor(tester, MemoryContent(), width: 320, scale: 1.5);
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.byKey(const ValueKey('content-title')));
    await tester.enterText(
      find.byKey(const ValueKey('content-title')),
      'Tiêu đề di động',
    );
    await press(tester, 'Xem trước');
    expect(find.byType(ContentArticle), findsOneWidget);
    expect(tester.takeException(), isNull);
    await press(tester, 'Đóng');
    await press(tester, 'Lưu nháp');
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'Formatted content displays headings, lists and tables on narrow screens',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ContentArticle(
                slug: 'guide',
                title: 'Hướng dẫn',
                body: '<h2>Tiêu đề mục</h2><p style="color:#337788">Nội dung <strong>in đậm</strong></p><ul><li>Mục một</li></ul><figure><table><tbody><tr><td>Ô đầu</td><td>Ô cuối</td></tr></tbody></table></figure>',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Tiêu đề mục', findRichText: true),
        findsWidgets,
      );
      expect(find.textContaining('Ô đầu', findRichText: true), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );
}
