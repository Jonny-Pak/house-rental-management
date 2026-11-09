import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'chatbot_welcome.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../listing/data/models/listing_filter.dart';
import '../../listing/presentation/pages/listing_detail_page.dart';
import '../../listing/presentation/pages/search_location_page.dart';
import '../../map/presentation/pages/listing_map_page.dart';
import '../data/chat_repository.dart';
import 'chat_listing_card.dart';

class ChatbotPage extends StatefulWidget {
  const ChatbotPage({super.key, this.repository, this.locationPicker});
  final ChatRepository? repository;
  final Future<SearchLocation?> Function(BuildContext context)? locationPicker;

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatTurn {
  _ChatTurn(this.text, {this.reply, this.location, DateTime? createdAt})
    : time = createdAt ?? DateTime.now();
  final DateTime time;
  final String text;
  final ChatReply? reply;
  final SearchLocation? location;
  bool get isUser => reply == null;
}

class _ChatbotPageState extends State<ChatbotPage> {
  late final _repository = widget.repository ?? ChatRepository(ApiClient());
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _focus = FocusNode();
  final List<_ChatTurn> _turns = [];
  Map<String, dynamic> _filters = {};
  SearchLocation? _location;
  bool _busy = false;
  String? _error;
  String? _retry;
  bool _loadingHistory = true;
  bool _loadingOlder = false;
  bool _hasMore = false;
  int? _beforeId;
  String? _historyError;

  bool get _blocked =>
      _busy || _loadingHistory || _loadingOlder || _historyError != null;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory({bool older = false}) async {
    setState(() {
      if (older) {
        _loadingOlder = true;
      } else {
        _loadingHistory = true;
        _historyError = null;
      }
    });
    try {
      final page = await _repository.history(
        beforeId: older ? _beforeId : null,
      );
      if (!mounted) return;
      final loaded = <_ChatTurn>[];
      for (final item in page.items) {
        loaded.add(_ChatTurn(item.message, createdAt: item.createdAt));
        loaded.add(
          _ChatTurn(
            item.reply.message,
            reply: item.reply,
            location: item.location,
            createdAt: item.createdAt,
          ),
        );
      }
      setState(() {
        if (!older) _turns.clear();
        _turns.insertAll(0, loaded);
        _hasMore = page.hasMore;
        _beforeId = page.items.isEmpty ? null : page.items.first.id;
        if (!older && page.items.isNotEmpty) {
          final last = page.items.last;
          _filters = Map<String, dynamic>.from(last.reply.filters);
          _location = last.reply.clearLocation || last.reply.locationRequired
              ? null
              : last.location;
        }
      });
      if (!older) _toBottom();
    } catch (error) {
      if (!mounted) return;
      if (older) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ChatRepository.errorMessage(error))),
        );
      } else {
        setState(() => _historyError = ChatRepository.errorMessage(error));
      }
    } finally {
      if (mounted) {
        setState(() {
          _loadingHistory = false;
          _loadingOlder = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _toBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  Future<void> _send(String text, {bool retry = false}) async {
    final message = text.trim();
    if (_blocked || message.isEmpty) return;
    if (message.length > 1000) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
      _retry = null;
      if (!retry) _turns.add(_ChatTurn(message));
      _input.clear();
    });
    _toBottom();
    final sentLocation = _location;
    try {
      final reply = await _repository.send(message, _filters, sentLocation);
      if (!mounted) return;
      setState(() {
        _filters = Map<String, dynamic>.from(reply.filters);
        if (reply.locationRequired || reply.clearLocation) _location = null;
        _turns.add(
          _ChatTurn(reply.message, reply: reply, location: sentLocation),
        );
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = ChatRepository.errorMessage(error);
          _retry = message;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        _toBottom();
      }
    }
  }

  Future<void> _chooseLocation() async {
    if (_blocked) return;
    final chosen = widget.locationPicker == null
        ? await Navigator.of(context).push<SearchLocation>(
            MaterialPageRoute(
              builder: (_) => SearchLocationPage(initial: _location),
            ),
          )
        : await widget.locationPicker!(context);
    if (!mounted || chosen == null) return;
    setState(() => _location = chosen);
    if (_filters['radiusKm'] != null) {
      await _send(
        'Đã chọn điểm trên bản đồ. Tìm quanh điểm này theo các điều kiện hiện tại.',
      );
    }
  }

  Future<void> _reset() async {
    if (_blocked) return;
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('Cuộc trò chuyện mới?'),
        content: const Text(
          'Xóa toàn bộ lịch sử trò chuyện đã lưu của tài khoản và bắt đầu lại?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialog, true),
            child: const Text('Bắt đầu mới'),
          ),
        ],
      ),
    );
    if (!mounted || accepted != true) return;
    setState(() => _busy = true);
    try {
      await _repository.clearHistory();
    } catch (error) {
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ChatRepository.errorMessage(error))),
        );
      }
      return;
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      _turns.clear();
      _hasMore = false;
      _beforeId = null;
      _filters = {};
      _location = null;
      _error = null;
      _retry = null;
      _input.clear();
    });
  }

  void _openMap(_ChatTurn turn) {
    final reply = turn.reply!;
    final radius = (reply.filters['radiusKm'] as num?)?.toDouble();
    final center = radius == null ? null : turn.location?.point;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ListingMapPage(
          initialFilter: ListingFilter(
            center: center,
            radiusKm: center == null ? null : radius,
            centerName: turn.location?.name,
          ),
          repository: ChatMapRepository(
            ApiClient(),
            reply.listings.map((item) => item.id).toSet(),
          ),
        ),
      ),
    );
  }

  void _draft(String text) {
    _input.text = text;
    _input.selection = TextSelection.collapsed(offset: text.length);
    _focus.requestFocus();
  }

  Future<void> _nearby() async {
    await _chooseLocation();
    if (mounted && _location != null && !_busy && _turns.isEmpty) {
      await _send('Tìm nhà, phòng trọ quanh điểm đã chọn trong bán kính 3 km');
    }
  }

  void _showInfo() {
    showDialog<void>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('Trợ lý AI tìm nhà'),
        scrollable: true,
        content: const Text(
          'Bạn có thể tìm nhà, phòng trọ hoặc người ở ghép theo giá, diện tích, tiện ích và vị trí. '
          'Kết quả lấy từ tin đã duyệt, còn trống. Chọn điểm trên bản đồ khi tìm theo bán kính. '
          'Lịch sử và điều kiện được lưu riêng theo tài khoản để tiếp tục khi mở lại. '
          'Bạn cũng có thể hỏi cách dùng các chức năng trong ứng dụng. '
          'Chatbot không truy cập dữ liệu riêng tư, không thêm, sửa, xóa dữ liệu và không thực hiện giao dịch.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog),
            child: const Text('Đã hiểu'),
          ),
        ],
      ),
    );
  }

  Widget _results(_ChatTurn turn) => LayoutBuilder(
    builder: (context, constraints) {
      final reply = turn.reply!;
      final largeText = MediaQuery.textScalerOf(context).scale(14) > 19;
      final columns = constraints.maxWidth >= 300 && !largeText ? 2 : 1;
      final width = (constraints.maxWidth - (columns - 1) * 9) / columns;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (reply.conditions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 10),
              child: Wrap(
                spacing: 5,
                runSpacing: 5,
                children: [
                  for (final value in reply.conditions)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F8F3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        value,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          Wrap(
            spacing: 9,
            runSpacing: 10,
            children: [
              for (final listing in reply.listings)
                SizedBox(
                  width: width,
                  child: ChatListingCard(
                    listing: listing,
                    distanceLabel:
                        turn.location == null ||
                            reply.filters['radiusKm'] == null
                        ? null
                        : ListingFilter(center: turn.location!.point)
                              .distanceLabel(listing),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            ListingDetailPage(listingId: listing.id),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          if (reply.listings.any(
            (item) => item.latitude != null && item.longitude != null,
          ))
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: FilledButton.tonalIcon(
                onPressed: () => _openMap(turn),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFDEF5E5),
                  foregroundColor: AppColors.primaryDark,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.map_outlined, size: 18),
                label: const Text('Bản đồ các tin này'),
              ),
            ),
        ],
      );
    },
  );

  Widget _turn(_ChatTurn turn) {
    final user = turn.isUser;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: user
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!user) ...[
            const Padding(
              padding: EdgeInsets.only(top: 3),
              child: ChatbotAvatar(size: 29),
            ),
            const SizedBox(width: 7),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(maxWidth: user ? 520 : 720),
              padding: const EdgeInsets.fromLTRB(13, 11, 13, 9),
              decoration: BoxDecoration(
                gradient: user
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF16974F), Color(0xFF087942)],
                      )
                    : null,
                color: user ? null : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(user ? 18 : 5),
                  bottomRight: Radius.circular(user ? 5 : 18),
                ),
                border: user
                    ? null
                    : Border.all(color: const Color(0xFFE4EBE7)),
                boxShadow: user
                    ? null
                    : [
                        BoxShadow(
                          color: const Color(0xFF1A583A)
                              .withValues(alpha: .035),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: user
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  Text(
                    turn.text,
                    style: TextStyle(
                      color: user ? Colors.white : AppColors.text,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  if (!user) _results(turn),
                  const SizedBox(height: 5),
                  Text(
                    DateFormat('dd/MM HH:mm').format(turn.time),
                    style: TextStyle(
                      fontSize: 10,
                      color: user ? Colors.white70 : AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _composer() => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF18472E).withValues(alpha: .05),
          blurRadius: 18,
          offset: const Offset(0, -3),
        ),
      ],
    ),
    padding: const EdgeInsets.fromLTRB(12, 3, 12, 10),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: TextButton.icon(
                onPressed: _blocked ? null : _chooseLocation,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.muted,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  textStyle: TextStyle(
                    fontSize: 11,
                    fontFamily: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.fontFamily,
                  ),
                ),
                icon: const Icon(Icons.location_on_outlined, size: 16),
                label: Text(
                  _location?.name ?? 'Chọn vị trí tìm quanh đây',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            if (_location != null)
              IconButton(
                tooltip: 'Bỏ vị trí',
                onPressed: _blocked
                    ? null
                    : () => setState(() => _location = null),
                icon: const Icon(Icons.close, size: 16),
              ),
          ],
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: _input,
                focusNode: _focus,
                enabled: !_blocked,
                minLines: 1,
                maxLines: 3,
                maxLength: 1000,
                textInputAction: TextInputAction.send,
                onSubmitted: _send,
                style: const TextStyle(fontSize: 14, height: 1.4),
                decoration: InputDecoration(
                  hintText: 'Nhập câu hỏi tìm nhà…',
                  counterText: '',
                  filled: true,
                  fillColor: const Color(0xFFF2F5F3),
                  hintStyle: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 13,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 17,
                    vertical: 13,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(26),
                    borderSide: const BorderSide(color: Color(0xFFE3EAE6)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(26),
                    borderSide: const BorderSide(color: Color(0xFFE3EAE6)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(26),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 9),
            IconButton.filled(
              tooltip: 'Gửi tin nhắn',
              onPressed: _blocked ? null : () => _send(_input.text),
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFF0A9849),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(13),
              ),
              icon: const Icon(Icons.arrow_upward_rounded, size: 24),
            ),
          ],
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final largeText = MediaQuery.textScalerOf(context).scale(15) > 22;
    return Scaffold(
      backgroundColor: const Color(0xFFF3F7F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF087846),
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: largeText ? 88 : 68,
        titleSpacing: 0,
        title: Row(
          children: [
            const ChatbotAvatar(size: 37),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Trợ lý AI tìm nhà',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                  if (!largeText)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(
                        _busy
                            ? 'Đang tìm tin phù hợp…'
                            : 'Người bạn đồng hành tìm nơi ở',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white.withValues(alpha: .85),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Cuộc trò chuyện mới',
            onPressed: _blocked || _turns.isEmpty ? null : _reset,
            disabledColor: Colors.white38,
            icon: const Icon(Icons.delete_outline_rounded, size: 21),
          ),
          IconButton(
            tooltip: 'Về trợ lý AI',
            onPressed: _showInfo,
            icon: const Icon(Icons.info_outline_rounded, size: 21),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    controller: _scroll,
                    padding: EdgeInsets.only(
                      top: _turns.isEmpty ? 0 : 16,
                      bottom: 10,
                    ),
                    children: [
                      if (_loadingHistory)
                        const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      if (_historyError != null)
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              Text('Chưa tải được lịch sử. $_historyError'),
                              TextButton(
                                onPressed: _loadHistory,
                                child: const Text('Tải lại lịch sử'),
                              ),
                            ],
                          ),
                        ),
                      if (_hasMore)
                        TextButton(
                          onPressed: _blocked
                              ? null
                              : () => _loadHistory(older: true),
                          child: Text(
                            _loadingOlder ? 'Đang tải…' : 'Xem tin nhắn cũ hơn',
                          ),
                        ),
                      if (_turns.isEmpty &&
                          !_loadingHistory &&
                          _historyError == null)
                        ChatbotWelcome(
                          onSend: _send,
                          onDraft: _draft,
                          onNearby: _nearby,
                        ),
                      for (final turn in _turns) _turn(turn),
                      if (_busy)
                        const Padding(
                          padding: EdgeInsets.fromLTRB(15, 0, 16, 18),
                          child: Row(
                            children: [
                              ChatbotAvatar(size: 29),
                              SizedBox(width: 10),
                              SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primary,
                                ),
                              ),
                              SizedBox(width: 9),
                              Flexible(
                                child: Text(
                                  'Đang phân tích và tìm tin…',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.muted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF3EF),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFF2DDD4),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _error!,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    height: 1.5,
                                    color: Color(0xFF865140),
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: _blocked || _retry == null
                                      ? null
                                      : () => _send(_retry!, retry: true),
                                  icon: const Icon(
                                    Icons.refresh_rounded,
                                    size: 17,
                                  ),
                                  label: const Text('Thử lại'),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                _composer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
