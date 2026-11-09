import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/chatbot/data/chat_repository.dart';
import 'package:frontend/features/listing/presentation/pages/search_location_page.dart';
import 'package:latlong2/latlong.dart';

import 'chatbot_test.dart' show FakeChat, openChat, send;

ChatHistoryItem saved(int id, String text, double price) => ChatHistoryItem(
  id,
  text,
  ChatReply(
    message: 'Kết quả cũ $id',
    filters: {'maxPrice': price, 'radiusKm': 3},
    conditions: [],
    listings: [],
    total: 0,
    locationRequired: false,
  ),
  const SearchLocation(LatLng(10.78, 106.7), 'Điểm đã chọn'),
  DateTime(2026, 11, 4, 10),
);

void main() {
  testWidgets(
    'Reopen restores messages, filters and point; another account starts empty',
    (tester) async {
      final repository = FakeChat()
        ..saved = ChatHistoryPage([
          saved(5, 'Phòng trọ dưới 4 triệu', 4000000),
        ], false);
      await openChat(tester, repository);
      expect(find.text('Phòng trọ dưới 4 triệu'), findsOneWidget);
      await send(tester, 'Rẻ hơn');
      expect(repository.contexts.last['maxPrice'], 4000000);
      expect(repository.locations.last!.point.latitude, 10.78);
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      await openChat(tester, repository);
      expect(find.text('Phòng trọ dưới 4 triệu'), findsOneWidget);
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      await openChat(tester, FakeChat());
      expect(find.text('Phòng trọ dưới 4 triệu'), findsNothing);
    },
  );

  testWidgets('Older pages do not replace latest search conditions', (
    tester,
  ) async {
    final repository = FakeChat()
      ..saved = ChatHistoryPage([saved(31, 'Tin nhắn mới', 4000000)], true)
      ..older = ChatHistoryPage([saved(1, 'Tin nhắn rất cũ', 2000000)], false);
    await openChat(tester, repository);
    await tester.ensureVisible(find.text('Xem tin nhắn cũ hơn'));
    await tester.tap(find.text('Xem tin nhắn cũ hơn'));
    await tester.pumpAndSettle();
    expect(repository.historyRequests, [null, 31]);
    expect(find.text('Tin nhắn rất cũ'), findsOneWidget);
    await send(tester, 'Rẻ hơn');
    expect(repository.contexts.last['maxPrice'], 4000000);
  });

  testWidgets('Loading failure blocks sending until history is restored', (
    tester,
  ) async {
    final repository = FakeChat()..historyError = StateError('offline');
    await openChat(tester, repository);
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
    expect(repository.messages, isEmpty);
    repository.historyError = null;
    repository.saved = ChatHistoryPage([
      saved(5, 'Điều kiện trước', 4000000),
    ], false);
    await tester.tap(find.text('Tải lại lịch sử'));
    await tester.pumpAndSettle();
    await send(tester, 'Rẻ hơn');
    expect(repository.contexts.last['maxPrice'], 4000000);
  });

  testWidgets(
    'Failed deletion preserves history; success clears it on server before UI',
    (tester) async {
      final repository = FakeChat()
        ..saved = ChatHistoryPage([
          saved(5, 'Tin nhắn đã lưu', 4000000),
        ], false);
      await openChat(tester, repository);
      repository.clearError = StateError('offline');
      await tester.tap(find.byTooltip('Cuộc trò chuyện mới'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bắt đầu mới'));
      await tester.pumpAndSettle();
      expect(find.text('Tin nhắn đã lưu'), findsOneWidget);
      expect(repository.clears, 0);
      repository.clearError = null;
      await tester.tap(find.byTooltip('Cuộc trò chuyện mới'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bắt đầu mới'));
      await tester.pumpAndSettle();
      expect(repository.clears, 1);
      expect(find.text('Tin nhắn đã lưu'), findsNothing);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      await send(tester, 'Tìm phòng');
      expect(repository.contexts.last, isEmpty);
      expect(repository.locations.last, isNull);
    },
  );
}
