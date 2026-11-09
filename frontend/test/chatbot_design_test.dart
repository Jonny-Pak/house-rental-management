import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/chatbot/data/chat_repository.dart';
import 'package:frontend/features/chatbot/presentation/chatbot_page.dart';
import 'package:frontend/features/chatbot/presentation/chat_listing_card.dart';
import 'package:frontend/features/listing/data/models/listing_model.dart';

import 'chatbot_test.dart' show FakeChat, openChat, send;

Future<void> press(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'Budget shortcut prepares an editable question without calling AI',
    (tester) async {
      final repository = FakeChat();
      await openChat(tester, repository);
      await press(tester, find.text('Giá phù hợp'));
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Tìm phòng trọ dưới ',
      );
      expect(repository.messages, isEmpty);
      await send(tester, 'Tìm phòng trọ dưới 3 triệu');
      expect(repository.messages.single, 'Tìm phòng trọ dưới 3 triệu');
    },
  );

  testWidgets('Nearby shortcut chooses a point and submits only one query', (
    tester,
  ) async {
    final repository = FakeChat();
    await openChat(tester, repository);
    await press(tester, find.text('Tìm quanh đây'));
    expect(repository.messages.length, 1);
    expect(repository.locations.single, isNotNull);
    expect(repository.messages.single, contains('3 km'));
  });

  testWidgets(
    'Info opens supported functionality and closes without losing conversation',
    (tester) async {
      final repository = FakeChat();
      await openChat(tester, repository);
      await send(tester, 'Phòng trọ dưới 4 triệu');
      await tester.tap(find.byTooltip('Về trợ lý AI'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Kết quả lấy từ tin đã duyệt'),
        findsOneWidget,
      );
      await tester.tap(find.text('Đã hiểu'));
      await tester.pumpAndSettle();
      expect(find.text('Phòng trọ dưới 4 triệu'), findsOneWidget);
    },
  );

  testWidgets(
    'Listing cards stay readable on phone, desktop and with large text',
    (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      for (final settings in [(320.0, 1.8), (430.0, 1.0), (1100.0, 1.0)]) {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.binding.setSurfaceSize(Size(settings.$1, 850));
        final repository = FakeChat();
        repository.reply = ChatReply(
          message: 'Tìm thấy 2 tin phù hợp.',
          filters: const {},
          conditions: const [],
          listings: [
            for (int i = 1; i <= 2; i++)
              Listing(
                id: i,
                title: 'Phòng trọ thoáng sáng có ban công',
                rentPrice: 3000000,
                areaSqm: 25,
                listingType: 'BOARDING_ROOM',
                address: 'Thành phố Hồ Chí Minh',
              ),
          ],
          total: 2,
          locationRequired: false,
        );
        await openChat(tester, repository, scale: settings.$2);
        await send(tester, 'Tìm phòng');
        expect(find.byType(ChatListingCard), findsNWidgets(2));
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets('Render welcome and conversation previews', (tester) async {
    if (Platform.environment['RENDER_CHATBOT_PREVIEW'] != 'true') return;
    await tester.runAsync(() async {
      final font = FontLoader('ChatPreview')
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
    await tester.binding.setSurfaceSize(const Size(430, 932));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final key = GlobalKey();
    final navigator = GlobalKey<NavigatorState>();
    final repository = FakeChat();
    repository.reply = ChatReply(
      message: 'Mình tìm được 2 phòng trọ phù hợp với ngân sách của bạn.',
      filters: const {'maxPrice': 4000000},
      conditions: const ['Phòng trọ', 'Đến 4.000.000 đ/tháng'],
      listings: [
        Listing(
          id: 1,
          title: 'Phòng trọ thoáng sáng có ban công',
          rentPrice: 3000000,
          areaSqm: 25,
          listingType: 'BOARDING_ROOM',
          address: 'Phường Linh Xuân, TP.HCM',
        ),
        Listing(
          id: 2,
          title: 'Phòng đầy đủ nội thất',
          rentPrice: 3500000,
          areaSqm: 30,
          listingType: 'BOARDING_ROOM',
          address: 'Phường Hiệp Bình, TP.HCM',
        ),
      ],
      total: 2,
      locationRequired: false,
    );
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          navigatorKey: navigator,
          theme: ThemeData(useMaterial3: true, fontFamily: 'ChatPreview'),
          home: const Scaffold(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    navigator.currentState!.push(
      MaterialPageRoute(builder: (_) => ChatbotPage(repository: repository)),
    );
    await tester.pumpAndSettle();
    Future<void> save(String path) async {
      await tester.runAsync(() async {
        final boundary =
            key.currentContext!.findRenderObject() as RenderRepaintBoundary;
        final picture = await boundary.toImage(pixelRatio: 1.5);
        final bytes = await picture.toByteData(format: ui.ImageByteFormat.png);
        await File(path).writeAsBytes(bytes!.buffer.asUint8List());
        picture.dispose();
      });
    }

    await save('build/chatbot-welcome-preview.png');
    await send(tester, 'Mình cần phòng trọ dưới 4 triệu');
    await save('build/chatbot-conversation-preview.png');
  });
}
