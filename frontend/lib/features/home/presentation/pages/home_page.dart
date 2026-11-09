import '../../../chatbot/presentation/chatbot_page.dart';
import '../../../chatbot/data/chat_repository.dart';

import 'dart:async';

import '../widgets/home_recent_listings.dart';
import '../../../listing/data/repositories/listing_repository.dart';

import 'package:frontend/core/theme/app_colors.dart';

import '../../../incident/data/incident_repository.dart';
import '../../../incident/presentation/incidents_page.dart';
import '../../../content/presentation/system_content_page.dart';
import '../../../content/data/repositories/system_content_repository.dart';
import '../../../notification/presentation/notification_store.dart';
import '../../../notification/presentation/notifications_page.dart';

import 'package:flutter/material.dart';

import '../../../../core/layout/app_layout.dart';

import 'package:material_symbols_icons/symbols.dart';

import '../widgets/home_feature_icon.dart';

import '../../../contract/presentation/pages/my_contracts_page.dart';
import '../../../listing/presentation/pages/create_listing_page.dart';
import '../../../listing/presentation/pages/my_listings_page.dart';
import '../../../listing/presentation/pages/listing_browse_page.dart';
import '../../../map/presentation/pages/listing_map_page.dart';
import '../../../membership/presentation/pages/membership_page.dart';

const _accent = AppColors.primary;
const _ink = Color(0xFF16352B);
const _background = AppColors.background;

class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
    this.onMenu,
    this.onTabSelected,
    this.contentRepository,
    this.incidentRepository,
    this.userName,
    this.listingRepository,
    this.chatRepository,
  });
  final String? userName;
  final ListingRepository? listingRepository;
  final ChatRepository? chatRepository;
  final SystemContentRepository? contentRepository;
  final IncidentRepository? incidentRepository;
  final VoidCallback? onMenu;
  final ValueChanged<int>? onTabSelected;

  void _open(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  List<_Action> _primary(BuildContext context) => [
    _Action(
      'Thuê Nhà',
      Symbols.home_work,
      () => _open(
        context,
        const ListingBrowsePage(title: 'Thuê nhà', listingType: 'WHOLE_HOUSE'),
      ),
    ),
    _Action(
      'Thuê Phòng Trọ',
      Symbols.apartment,
      () => _open(
        context,
        const ListingBrowsePage(
          title: 'Thuê phòng trọ',
          listingType: 'BOARDING_ROOM',
        ),
      ),
    ),
    _Action(
      'Tìm Ở Ghép',
      Symbols.group,
      () => _open(
        context,
        const ListingBrowsePage(
          title: 'Tìm người ở ghép',
          listingType: 'SHARED_ROOM',
        ),
      ),
    ),
    _Action(
      'Đăng Tin',
      Symbols.post_add,
      () => _open(context, const CreateListingPage()),
    ),
    _Action(
      'Bản Đồ',
      Symbols.map,
      () => _open(context, const ListingMapPage()),
    ),
    _Action('Quản Lý\nTin Đăng', Symbols.assignment, () {
      if (onTabSelected != null) {
        onTabSelected!(2);
      } else {
        _open(context, const MyListingsPage());
      }
    }),
    _Action(
      'Quản Lý\nHợp Đồng',
      Symbols.receipt_long,
      () => _open(context, const MyContractsPage(isLandlord: true)),
    ),
    _Action(
      'Gói Dịch Vụ',
      Symbols.payments,
      () => _open(context, const MembershipPage()),
    ),
  ];

  List<_Action> _secondary(BuildContext context) => [
    _Action(
      'Trợ Lý AI',
      Symbols.smart_toy,
      () => _open(context, ChatbotPage(repository: chatRepository)),
    ),
    _Action(
      'Giới Thiệu',
      Symbols.menu_book,
      () => _open(
        context,
        SystemContentPage(slug: 'about', repository: contentRepository),
      ),
    ),
    _Action(
      'Quy Định',
      Symbols.gavel,
      () => _open(
        context,
        SystemContentPage(slug: 'rules', repository: contentRepository),
      ),
    ),
    _Action(
      'Hướng Dẫn\nSử Dụng',
      Symbols.help,
      () => _open(
        context,
        SystemContentPage(slug: 'guide', repository: contentRepository),
      ),
    ),
    _Action(
      'Báo Cáo\nSự Cố',
      Symbols.report,
      () => _open(
        context,
        IncidentsPage(
          contentRepository: contentRepository,
          repository: incidentRepository,
        ),
      ),
    ),
    _Action(
      'Liên Hệ',
      Symbols.support_agent,
      () => _open(
        context,
        SystemContentPage(slug: 'contact', repository: contentRepository),
      ),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final actions = _primary(context);
    return Material(
      color: _background,
      child: AppContent(
        child: SingleChildScrollView(
          key: const PageStorageKey('home-scroll'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _HomeHeader(
                userName: userName,
                onMenu: onMenu ?? () => Scaffold.maybeOf(context)?.openDrawer(),
                onSearch: () => _open(
                  context,
                  const ListingBrowsePage(
                    title: 'Tìm kiếm nhà cho thuê',
                    autofocus: true,
                  ),
                ),
                onNotifications: () {
                  if (onTabSelected != null) {
                    onTabSelected!(3);
                  } else {
                    _open(context, const NotificationsPage());
                  }
                },
              ),
              Transform.translate(
                offset: const Offset(0, -24),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  decoration: const BoxDecoration(
                    color: _background,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _SectionHeader(
                        title: 'Dành cho bạn',
                        onMore: () => _showAll(context),
                      ),
                      const SizedBox(height: 10),
                      _ActionGrid(actions: actions),
                      const SizedBox(height: 16),
                      _HomeBanner(
                        onPost: () => _open(context, const CreateListingPage()),
                        onSearch: () => _open(
                          context,
                          const ListingBrowsePage(title: 'Tin cho thuê'),
                        ),
                        onMap: () => _open(context, const ListingMapPage()),
                      ),
                      const SizedBox(height: 18),
                      _SectionHeader(
                        title: 'Tin cho thuê mới nhất',
                        onMore: () => _open(
                          context,
                          const ListingBrowsePage(title: 'Tin cho thuê'),
                        ),
                      ),
                      const SizedBox(height: 10),
                      HomeRecentListings(repository: listingRepository),
                      const SizedBox(height: 24),
                      _SectionHeader(
                        title: 'Khám phá thêm',
                        onMore: () => _showAll(context),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: _ActionGrid(
                          actions: _secondary(context),
                          round: true,
                        ),
                      ),
                      const SizedBox(height: 124),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAll(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Tất cả chức năng',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 20),
              _ActionGrid(
                actions: [
                  for (final action in [
                    ..._primary(context),
                    ..._secondary(context),
                  ])
                    _Action(action.label, action.icon, () {
                      Navigator.pop(sheetContext);
                      action.onTap();
                    }),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.userName,
    required this.onMenu,
    required this.onSearch,
    required this.onNotifications,
  });
  final String? userName;
  final VoidCallback onMenu, onSearch, onNotifications;

  @override
  Widget build(BuildContext context) {
    final name = userName?.trim() ?? '';
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/home/townhouse.webp'),
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
        ),
      ),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xF018674A), Color(0xD12A8862), Color(0x705DA98C)],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 38),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      tooltip: 'Mở menu',
                      onPressed: onMenu,
                      icon: const Icon(
                        Symbols.menu,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              name.isEmpty
                                  ? 'Chào mừng bạn'
                                  : 'Chào bạn, $name',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                                height: 1.3,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(
                            Symbols.waving_hand,
                            color: Color(0xFFFFD58D),
                            size: 20,
                            fill: 1,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      tooltip: 'Thông báo',
                      onPressed: onNotifications,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primaryDark,
                      ),
                      icon: const NotificationBadge(
                        child: Icon(Symbols.notifications, size: 23),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Tìm nhà, phòng trọ, ở ghép dễ dàng hơn!',
                  style: TextStyle(
                    color: Color(0xFFE4F6EA),
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 18),
                Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  elevation: 2,
                  shadowColor: const Color(0x18203E2D),
                  child: InkWell(
                    onTap: onSearch,
                    borderRadius: BorderRadius.circular(28),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Symbols.search,
                            color: AppColors.primaryDark,
                            size: 24,
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'Tìm kiếm nhà, phòng trọ, khu vực...',
                              style: TextStyle(
                                color: AppColors.muted,
                                fontSize: 12,
                                height: 1.4,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            tooltip: 'Tìm kiếm và bộ lọc',
                            visualDensity: VisualDensity.compact,
                            onPressed: onSearch,
                            icon: const Icon(
                              Symbols.tune,
                              color: AppColors.primaryDark,
                              size: 22,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeBanner extends StatefulWidget {
  const _HomeBanner({
    required this.onPost,
    required this.onSearch,
    required this.onMap,
  });
  final VoidCallback onPost, onSearch, onMap;
  @override
  State<_HomeBanner> createState() => _HomeBannerState();
}

class _HomeBannerState extends State<_HomeBanner> with WidgetsBindingObserver {
  Timer? _timer;
  bool _resumed = true;
  double _dragOffset = 0;
  int _index = 0;
  static const _titles = [
    'Đăng tin cho thuê',
    'Tìm nơi ở phù hợp',
    'Khám phá quanh bạn',
  ];
  static const _subtitles = [
    'Kết nối với người thuê dễ dàng hơn.',
    'Nhà, phòng trọ và chỗ ở ghép dành cho bạn.',
    'Tìm nhà theo vị trí và bán kính trên bản đồ.',
  ];
  static const _buttons = ['Đăng tin ngay', 'Tìm nhà ngay', 'Xem bản đồ'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    _resumed = lifecycle == null || lifecycle == AppLifecycleState.resumed;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _startAutoSlide();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _resumed = state == AppLifecycleState.resumed;
    _startAutoSlide();
  }

  void _startAutoSlide() {
    _timer?.cancel();
    if (!_resumed ||
        !TickerMode.valuesOf(context).enabled ||
        ModalRoute.of(context)?.isCurrent == false) {
      return;
    }
    _timer = Timer(const Duration(seconds: 4), () {
      _changeSlide((_index + 1) % _titles.length);
    });
  }

  void _changeSlide(int index) {
    setState(() => _index = index);
    _startAutoSlide();
  }

  void _endSwipe(DragEndDetails details) {
    if (_dragOffset.abs() >= 24) {
      final direction = _dragOffset < 0 ? 1 : -1;
      _changeSlide((_index + direction + _titles.length) % _titles.length);
    } else {
      _startAutoSlide();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _openBanner() {
    if (_index == 0) {
      widget.onPost();
    } else if (_index == 1) {
      widget.onSearch();
    } else {
      widget.onMap();
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      GestureDetector(
        key: const ValueKey('home-banner'),
        onHorizontalDragStart: (_) {
          _dragOffset = 0;
          _timer?.cancel();
        },
        onHorizontalDragUpdate: (details) =>
            _dragOffset += details.primaryDelta ?? 0,
        onHorizontalDragEnd: _endSwipe,
        onHorizontalDragCancel: _startAutoSlide,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: Container(
            key: ValueKey('home-banner-content-$_index'),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFCDEEDB), Color(0xFFEAF7EF)],
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _titles[_index],
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _subtitles[_index],
                        style: const TextStyle(
                          color: AppColors.primaryDark,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      FilledButton(
                        onPressed: _openBanner,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                        ),
                        child: Text(
                          _buttons[_index],
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      _index == 1
                          ? 'assets/images/home/room.webp'
                          : 'assets/images/home/townhouse.webp',
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      const SizedBox(height: 6),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < _titles.length; i++)
            Semantics(
              label: 'Banner ${i + 1}',
              selected: i == _index,
              button: true,
              child: InkWell(
                key: ValueKey('home-slide-$i'),
                borderRadius: BorderRadius.circular(20),
                onTap: () => _changeSlide(i),
                child: Padding(
                  padding: const EdgeInsets.all(7),
                  child: Container(
                    width: i == _index ? 16 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: i == _index
                          ? AppColors.primary
                          : const Color(0xFFCEDFD4),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    ],
  );
}

class _Action {
  const _Action(this.label, this.icon, this.onTap);
  final String label;
  final IconData icon;
  final VoidCallback onTap;
}

class _ActionGrid extends StatelessWidget {
  const _ActionGrid({required this.actions, this.round = false});
  final List<_Action> actions;
  final bool round;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final largeText = MediaQuery.textScalerOf(context).scale(14) > 18;
      final columns = constraints.maxWidth < 280 || largeText
          ? 2
          : (constraints.maxWidth >= 1000 && !round ? 8 : 4);
      final width = constraints.maxWidth / columns;
      return Wrap(
        runSpacing: 12,
        children: [
          for (final action in actions)
            SizedBox(
              width: width,
              child: Semantics(
                button: true,
                label: action.label.replaceAll('\n', ' '),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: action.onTap,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 4,
                    ),
                    child: Column(
                      children: [
                        _ActionIcon(action: action, round: round),
                        const SizedBox(height: 6),
                        Text(
                          action.label,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 12,
                            height: 1.15,
                            fontWeight: FontWeight.w700,
                            color: _ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    },
  );
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({required this.action, this.round = false});
  final _Action action;
  final bool round;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: HomeFeatureIcon(icon: action.icon).backgroundColor,
        border: Border.all(color: const Color(0x0F26384A)),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: HomeFeatureIcon(icon: action.icon, size: 36),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.onMore});
  final String title;
  final VoidCallback onMore;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 4,
        height: 18,
        decoration: BoxDecoration(
          color: _accent,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: _ink,
          ),
        ),
      ),
      TextButton(
        onPressed: onMore,
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Xem tất cả',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w400),
            ),
            SizedBox(width: 4),
            Icon(Symbols.chevron_right, size: 18),
          ],
        ),
      ),
    ],
  );
}
