import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/features/content/data/models/system_content.dart';
import 'package:frontend/features/content/presentation/system_content_page.dart';
import 'package:frontend/features/content/presentation/content_links.dart';
import 'package:frontend/features/incident/presentation/incidents_page.dart';
import 'package:frontend/features/incident/presentation/create_incident_page.dart';

import 'system_content_test.dart' show MemoryContent;
import 'incident_flow_test.dart' show MemoryIncidents, incidentRow;

void main() {
  test('Contact actions come only from published contact details', () {
    expect(contactLinks('Thông tin sẽ được cập nhật'), isEmpty);
    final links = contactLinks(
      '<a href="mailto:support@example.com">Email</a><p>support@example.com</p><a href="tel:0900000000">Gọi</a><a href="javascript:alert(1)">Không mở</a>',
    );
    expect(links.map((uri) => uri.scheme), ['mailto', 'tel']);
    expect(contactLinks('Hotline: 090 000 0000').single.path, '0900000000');
  });

  testWidgets('External links are checked and launch failures are explained', (
    tester,
  ) async {
    final opened = <Uri>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => openContentLink(
                context,
                'mailto:support@example.com',
                opener: (uri) async {
                  opened.add(uri);
                  return false;
                },
              ),
              child: const Text('Liên hệ thử'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Liên hệ thử'));
    await tester.pumpAndSettle();
    expect(opened.single.scheme, 'mailto');
    expect(find.textContaining('Không mở được liên kết'), findsOneWidget);
    final context = tester.element(find.text('Liên hệ thử'));
    await openContentLink(
      context,
      'javascript:alert(1)',
      opener: (uri) async {
        opened.add(uri);
        return true;
      },
    );
    expect(opened.length, 1);
  });

  testWidgets(
    'All article pages and user reports fit narrow dark screens with enlarged text',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 820));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      for (final slug in contentPages.keys) {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.dark(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(1.6)),
              child: child!,
            ),
            home: SystemContentPage(
              key: ValueKey(slug),
              slug: slug,
              repository: MemoryContent(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: slug);
      }
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(1.6)),
            child: child!,
          ),
          home: IncidentsPage(
            repository: MemoryIncidents()..rows[1] = incidentRow(1),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Xem chi tiết'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Contact and guide link to the live report flow', (tester) async {
    final content = MemoryContent();
    final reports = MemoryIncidents();
    await tester.pumpWidget(
      MaterialApp(
        home: SystemContentPage(
          slug: 'contact',
          repository: content,
          incidentRepository: reports,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Gửi và theo dõi báo cáo'));
    await tester.tap(find.text('Gửi và theo dõi báo cáo'));
    await tester.pumpAndSettle();
    expect(find.byType(IncidentsPage), findsOneWidget);
    await tester.ensureVisible(find.text('Gửi báo cáo mới'));
    await tester.tap(find.text('Gửi báo cáo mới'));
    await tester.pumpAndSettle();
    expect(find.byType(CreateIncidentPage), findsOneWidget);
    expect(reports.lastAdmin, isFalse);
  });

  testWidgets('Render information and report page previews', (tester) async {
    if (Platform.environment['RENDER_HELP_PREVIEW'] != 'true') return;
    await tester.runAsync(() async {
      final font = FontLoader('HelpPreview')
        ..addFont(
          Future.value(
            ByteData.sublistView(
              File('C:/Windows/Fonts/segoeui.ttf').readAsBytesSync(),
            ),
          ),
        );
      await font.load();
      final icons = FontLoader('MaterialIcons')
        ..addFont(
          Future.value(
            ByteData.sublistView(
              File(
                'C:/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
              ).readAsBytesSync(),
            ),
          ),
        );
      await icons.load();
    });
    final key = GlobalKey();
    await tester.binding.setSurfaceSize(const Size(430, 932));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final content = MemoryContent();
    content.publicPages['about'] = const PublishedContent(
      slug: 'about',
      title: 'Một nơi ở, nhiều kết nối',
      body: '<h2>Tìm nơi bạn thuộc về</h2><p>Rental kết nối người tìm nhà, phòng trọ và người ở ghép trong một trải nghiệm đơn giản.</p><h3>Dành cho nhu cầu của bạn</h3><ul><li>Tìm nhà theo khu vực, ngân sách và tiện ích.</li><li>Khám phá vị trí trên bản đồ.</li><li>Quản lý tin đăng và hợp đồng.</li></ul>',
    );
    final reports = MemoryIncidents()..rows[1] = incidentRow(1);
    Future<void> render(Widget page, String path) async {
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              useMaterial3: true,
              fontFamily: 'HelpPreview',
              colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
            ),
            home: page,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        final image =
            await (key.currentContext!.findRenderObject()
                    as RenderRepaintBoundary)
                .toImage(pixelRatio: 1.5);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File(path).writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }

    await render(
      SystemContentPage(slug: 'about', repository: content),
      'build/about-redesign-preview.png',
    );
    await render(
      IncidentsPage(repository: reports),
      'build/incidents-redesign-preview.png',
    );
  });
}
