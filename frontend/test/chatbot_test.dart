import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/chatbot/data/chat_repository.dart';
import 'package:frontend/features/chatbot/presentation/chatbot_page.dart';
import 'package:frontend/features/chatbot/presentation/chat_listing_card.dart';
import 'package:frontend/features/listing/data/models/listing_model.dart';
import 'package:frontend/features/listing/presentation/pages/search_location_page.dart';

class FakeChat extends ChatRepository {
  FakeChat() : super(ApiClient());
  final messages = <String>[];
  final contexts = <Map<String, dynamic>>[];
  final locations = <SearchLocation?>[];
  Completer<ChatReply>? pending;
  Object? error;
  ChatHistoryPage saved = const ChatHistoryPage([], false);
  Object? historyError;
  Object? clearError;
  ChatHistoryPage older = const ChatHistoryPage([], false);
  final historyRequests = <int?>[];
  int clears = 0;

  @override
  Future<ChatHistoryPage> history({int? beforeId}) async {
    historyRequests.add(beforeId);
    if (historyError != null) throw historyError!;
    return beforeId == null ? saved : older;
  }

  @override
  Future<void> clearHistory() async {
    if (clearError != null) throw clearError!;
    clears++;
    saved = const ChatHistoryPage([], false);
  }

  ChatReply reply = const ChatReply(
    message: 'Tìm thấy 1 tin phù hợp.',
    filters: {'maxPrice': 4000000},
    conditions: ['Đến 4.000.000 đ/tháng'],
    listings: [],
    total: 1,
    locationRequired: false,
  );

  @override
  Future<ChatReply> send(
    String message,
    Map<String, dynamic> filters,
    SearchLocation? location,
  ) async {
    messages.add(message);
    contexts.add(Map.of(filters));
    locations.add(location);
    if (pending != null) return pending!.future;
    if (error != null) throw error!;
    return reply;
  }
}

class ChatApi extends ApiClient {
  Map<String, dynamic>? body;
  Options? options;
  @override
  Future<Response> post(String path, dynamic data, {Options? options}) async {
    expect(path, '/chatbot/messages');
    body = Map<String, dynamic>.from(data);
    this.options = options;
    return Response(
      requestOptions: RequestOptions(path: path),
      data: {
        'message': 'Không có tin phù hợp',
        'filters': {'maxPrice': 4000000},
        'conditions': [],
        'listings': [],
        'total': 0,
        'locationRequired': false,
      },
    );
  }

  @override
  Future<Response> get(String path, {Map<String, dynamic>? queryParams}) async {
    return Response(
      requestOptions: RequestOptions(path: path),
      statusCode: 200,
      data: [
        {
          'id': 1,
          'title': 'Tin 1',
          'approvalStatus': 'APPROVED',
          'rentalStatus': 'AVAILABLE',
        },
        {
          'id': 2,
          'title': 'Tin 2',
          'approvalStatus': 'APPROVED',
          'rentalStatus': 'AVAILABLE',
        },
      ],
    );
  }
}

Future<void> openChat(
  WidgetTester tester,
  FakeChat repository, {
  double scale = 1,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: ChatbotPage(
        repository: repository,
        locationPicker: (_) async =>
            const SearchLocation(LatLng(10.78, 106.7), 'Điểm đã chọn'),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> send(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField), text);
  await tester.tap(find.byTooltip('Gửi tin nhắn'));
  await tester.pumpAndSettle();
}

void main() {
  test('Reply decodes an explicit server location reset', () {
    final reply = ChatReply.fromJson({
      'message': 'Đã xóa điều kiện',
      'filters': {},
      'conditions': [],
      'listings': [],
      'total': 0,
      'locationRequired': false,
      'clearLocation': true,
    });
    expect(reply.clearLocation, isTrue);
    expect(reply.filters, isEmpty);
  });
  test('Repository sends only typed context and explicit coordinates with a longer AI timeout', () async {
    final api = ChatApi();
    final repository = ChatRepository(api);
    final reply = await repository.send('Rẻ hơn', {
      'maxPrice': 4000000,
    }, const SearchLocation(LatLng(10.78, 106.7), 'Điểm đã chọn'));
    expect(reply.total, 0);
    expect(api.body!['latitude'], 10.78);
    expect(api.body!['context'], {'maxPrice': 4000000});
    expect(api.options!.receiveTimeout, const Duration(seconds: 40));
  });
  test('Map refresh keeps only IDs returned by chatbot', () async {
    final map = ChatMapRepository(ChatApi(), {2});
    expect((await map.fetchApprovedListings()).map((row) => row.id), [2]);
    expect((await map.fetchNearby(10.78, 106.7, 3)).map((row) => row.id), [2]);
  });
  testWidgets(
    'Send, cards and followup preserve server filters without filling another form',
    (tester) async {
      final repository = FakeChat();
      repository.reply = ChatReply(
        message: 'Tìm thấy 1 tin phù hợp.',
        filters: const {'maxPrice': 4000000},
        conditions: const ['Đến 4.000.000 đ/tháng'],
        listings: [
          Listing(
            id: 1,
            title: 'Phòng yên tĩnh',
            rentPrice: 3000000,
            areaSqm: 25,
            listingType: 'BOARDING_ROOM',
            address: 'Thủ Đức',
          ),
        ],
        total: 1,
        locationRequired: false,
      );
      await openChat(tester, repository);
      await send(tester, '   ');
      expect(repository.messages, isEmpty);
      await send(tester, 'Phòng dưới 4 triệu');
      expect(find.byType(ChatListingCard), findsOneWidget);
      expect(find.text('Phòng yên tĩnh'), findsOneWidget);
      await send(tester, 'Rẻ hơn');
      expect(repository.contexts.last, {'maxPrice': 4000000});
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'Radius search asks for a chosen point and follows up with the same conditions',
    (tester) async {
      final repository = FakeChat();
      repository.reply = const ChatReply(
        message: 'Hãy chọn điểm trên bản đồ',
        filters: {'maxPrice': 4000000, 'radiusKm': 3},
        conditions: ['Bán kính 3 km'],
        listings: [],
        total: 0,
        locationRequired: true,
      );
      await openChat(tester, repository);
      await send(tester, 'Trong bán kính 3 km');
      expect(repository.locations.first, isNull);
      repository.reply = const ChatReply(
        message: 'Chưa có tin phù hợp',
        filters: {'maxPrice': 4000000, 'radiusKm': 3},
        conditions: [],
        listings: [],
        total: 0,
        locationRequired: false,
      );
      await tester.tap(find.text('Chọn vị trí tìm quanh đây'));
      await tester.pumpAndSettle();
      expect(repository.locations.last!.point.latitude, 10.78);
      expect(repository.contexts.last, {'maxPrice': 4000000, 'radiusKm': 3});
      expect(find.text('Điểm đã chọn'), findsOneWidget);
    },
  );
  testWidgets(
    'Pending request disables duplicates and error retries without duplicating user message',
    (tester) async {
      final repository = FakeChat();
      repository.pending = Completer<ChatReply>();
      await openChat(tester, repository);
      await tester.enterText(find.byType(TextField), 'Tìm phòng');
      await tester.tap(find.byTooltip('Gửi tin nhắn'));
      await tester.pump();
      await tester.tap(find.byTooltip('Gửi tin nhắn'));
      await tester.pump();
      expect(repository.messages.length, 1);
      final request = RequestOptions(path: '/chatbot/messages');
      repository.pending!.completeError(
        DioException(
          requestOptions: request,
          response: Response(
            requestOptions: request,
            statusCode: 503,
            data: {'message': 'Mô hình nội bộ chưa sẵn sàng'},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Mô hình nội bộ chưa sẵn sàng'), findsOneWidget);
      repository.pending = null;
      await tester.ensureVisible(find.text('Thử lại'));
      await tester.tap(find.text('Thử lại'));
      await tester.pumpAndSettle();
      expect(repository.messages.length, 2);
      expect(find.text('Tìm phòng'), findsOneWidget);
    },
  );
  testWidgets('New conversation clears previous context after confirmation', (
    tester,
  ) async {
    final repository = FakeChat();
    await openChat(tester, repository);
    await send(tester, 'Dưới 4 triệu');
    await tester.tap(find.byTooltip('Cuộc trò chuyện mới'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bắt đầu mới'));
    await tester.pumpAndSettle();
    await send(tester, 'Nhà nguyên căn');
    expect(repository.contexts.last, isEmpty);
    expect(find.text('Dưới 4 triệu'), findsNothing);
  });
  testWidgets(
    'Text reset clears selected point and filters for the next request',
    (tester) async {
      final repository = FakeChat();
      await openChat(tester, repository);
      await tester.tap(find.text('Chọn vị trí tìm quanh đây'));
      await tester.pumpAndSettle();
      repository.reply = const ChatReply(
        message: 'Đã xóa điều kiện',
        filters: {},
        conditions: [],
        listings: [],
        total: 0,
        locationRequired: false,
        clearLocation: true,
      );
      await send(tester, 'Bắt đầu lại');
      expect(repository.locations.last, isNotNull);
      await send(tester, 'Tìm phòng');
      expect(repository.locations.last, isNull);
      expect(repository.contexts.last, isEmpty);
    },
  );
  testWidgets('Closing the page ignores a late response', (tester) async {
    final repository = FakeChat();
    repository.pending = Completer<ChatReply>();
    await openChat(tester, repository);
    await tester.enterText(find.byType(TextField), 'Tìm phòng');
    await tester.tap(find.byTooltip('Gửi tin nhắn'));
    await tester.pump();
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    repository.pending!.complete(repository.reply);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
  testWidgets('Small windows and large text keep composer and results usable', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = FakeChat();
    await openChat(tester, repository, scale: 1.8);
    await send(tester, 'Tìm phòng');
    expect(find.byTooltip('Gửi tin nhắn'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
