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

const _orange = Color(0xFFFF751B);
const _ink = Color(0xFF0B1535);
const _background = Color(0xFFF8F9FB);

class HomePage extends StatelessWidget {
  const HomePage({super.key, this.onMenu, this.onTabSelected});
  final VoidCallback? onMenu;
  final ValueChanged<int>? onTabSelected;

  void _open(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  void _information(
    BuildContext context,
    String title,
    String body,
    IconData icon,
  ) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HomeFeatureIcon(icon: icon, size: 48),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(body, style: const TextStyle(fontSize: 15, height: 1.6)),
            ],
          ),
        ),
      ),
    );
  }

  List<_Action> _primary(BuildContext context) => [
    _Action(
      'Đăng Tin',
      Symbols.post_add,
      () => _open(context, const CreateListingPage()),
    ),
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
    _Action(
      'Bản Đồ',
      Symbols.map,
      () => _open(context, const ListingMapPage()),
    ),
    _Action(
      'Trợ Lý AI',
      Symbols.smart_toy,
      () => _information(
        context,
        'Trợ lý AI',
        'Tính năng tìm nhà bằng ngôn ngữ tự nhiên đang được phát triển. Bạn có thể tìm tin theo địa chỉ hoặc xem vị trí trên bản đồ.',
        Symbols.smart_toy,
      ),
    ),
  ];

  List<_Action> _secondary(BuildContext context) => [
    _Action(
      'Giới Thiệu',
      Symbols.menu_book,
      () => _information(
        context,
        'Giới thiệu',
        'Ứng dụng kết nối người thuê và người cho thuê tại TP.HCM, hỗ trợ đăng tin, xem nhà trên bản đồ và quản lý hợp đồng.',
        Symbols.tune,
      ),
    ),
    _Action(
      'Quy Định',
      Symbols.gavel,
      () => _information(
        context,
        'Quy định đăng tin',
        'Cung cấp đúng địa chỉ, giá thuê và ảnh thực tế. Tin mới và tin chỉnh sửa phải được Admin duyệt trước khi xuất hiện công khai.',
        Symbols.gavel,
      ),
    ),
    _Action(
      'Hướng Dẫn\nSử Dụng',
      Symbols.help,
      () => _information(
        context,
        'Hướng dẫn sử dụng',
        '1. Chọn Đăng Tin và điền thông tin nhà/phòng.\n2. Gửi tin để Admin duyệt.\n3. Xem trạng thái trong Quản Lý Tin Đăng.\n4. Tìm nhà đã duyệt ở mục Thuê Nhà, Thuê Phòng Trọ hoặc Bản Đồ.',
        Symbols.help,
      ),
    ),
    _Action(
      'Báo Cáo\nSự Cố',
      Symbols.report,
      () => _information(
        context,
        'Báo cáo sự cố',
        'Bạn có thể ghi lại thao tác gặp lỗi và ảnh màn hình để gửi cho người quản trị. Chức năng gửi báo cáo trong ứng dụng chưa được kết nối.',
        Symbols.report,
      ),
    ),
    _Action(
      'Liên Hệ',
      Symbols.support_agent,
      () => _information(
        context,
        'Liên hệ',
        'Thông tin liên hệ hỗ trợ sẽ được cập nhật khi hệ thống chính thức triển khai.',
        Symbols.support_agent,
      ),
    ),
  ];

  @override
  Widget build(BuildContext context) => Material(
    color: _background,
    child: AppContent(
      child: SingleChildScrollView(
        key: const PageStorageKey('home-scroll'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _HomeHero(
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
                  _information(
                    context,
                    'Thông báo',
                    'Chức năng thông báo hệ thống đang được phát triển.',
                    Symbols.notifications,
                  );
                }
              },
            ),
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
              child: Column(
                children: [
                  _SectionHeader(
                    title: 'Chức năng',
                    onMore: () => _showAll(context),
                  ),
                  const SizedBox(height: 16),
                  _ActionGrid(actions: _primary(context)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SectionHeader(
                    title: 'Khám Phá Thêm',
                    onMore: () => _open(
                      context,
                      const ListingBrowsePage(title: 'Khám phá tin cho thuê'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final stacked =
                          constraints.maxWidth < 340 ||
                          MediaQuery.textScalerOf(context).scale(14) > 19;
                      final width = stacked
                          ? constraints.maxWidth
                          : (constraints.maxWidth - 12) / 2;
                      return Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          SizedBox(
                            width: width,
                            child: _DiscoveryCard(
                              title: 'TÌM NHÀ ĐÚNG Ý',
                              subtitle: 'Khám phá hàng trăm căn nhà phù hợp với nhu cầu',
                              image: 'assets/images/home/townhouse.webp',
                              onTap: () => _open(
                                context,
                                const ListingBrowsePage(
                                  title: 'Thuê nhà',
                                  listingType: 'WHOLE_HOUSE',
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: width,
                            child: _DiscoveryCard(
                              title: 'PHÒNG TRỌ QUANH BẠN',
                              subtitle: 'Xem vị trí trên bản đồ dễ dàng',
                              image: 'assets/images/home/room.webp',
                              onTap: () =>
                                  _open(context, const ListingMapPage()),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 22),
                  _SectionHeader(
                    title: 'Các Chức Năng Khác',
                    onMore: () => _showAll(context),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      children: [
                        _ActionGrid(
                          actions: _secondary(context).sublist(0, 4),
                          round: true,
                        ),
                        const SizedBox(height: 8),
                        _ContactTile(action: _secondary(context).last),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 124),
          ],
        ),
      ),
    ),
  );

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

class _HomeHero extends StatefulWidget {
  const _HomeHero({
    required this.onMenu,
    required this.onSearch,
    required this.onNotifications,
  });
  final VoidCallback onMenu, onSearch, onNotifications;
  @override
  State<_HomeHero> createState() => _HomeHeroState();
}

class _HomeHeroState extends State<_HomeHero> {
  int _index = 0;
  static const _slides = [
    (
      'Quản lý nhà cho thuê',
      'Dễ dàng\nHiệu quả hơn',
      'Quản lý phòng, hợp đồng, thanh toán\ntất cả trong một ứng dụng',
    ),
    (
      'Tìm nơi ở phù hợp',
      'Nhà đẹp\nTrong tầm tay',
      'Khám phá tin thuê theo khu vực,\ngiá và nhu cầu của bạn',
    ),
    (
      'Kết nối chủ nhà và người thuê',
      'An tâm thuê\nDễ quản lý',
      'Theo dõi tin đăng và hợp đồng\nngay trên ứng dụng',
    ),
  ];
  void _slide(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final wide = constraints.maxWidth >= 760;
      final top = MediaQuery.paddingOf(context).top;
      return GestureDetector(
        onHorizontalDragEnd: (details) {
          final speed = details.primaryVelocity ?? 0;
          if (speed < -100) {
            _slide((_index + 1) % _slides.length);
          }
          if (speed > 100) {
            _slide((_index + _slides.length - 1) % _slides.length);
          }
        },
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: (wide ? 350 : 280) + top),
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  'assets/images/home/townhouse.webp',
                  fit: BoxFit.cover,
                  alignment: const Alignment(.35, .1),
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFFFFAF3).withValues(alpha: .97),
                        const Color(0xFFFFFAF3).withValues(alpha: .70),
                        Colors.white.withValues(alpha: .04),
                      ],
                      stops: const [0, .43, 1],
                    ),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(8, top + 12, 8, 0),
                    child: Row(
                      children: [
                        IconButton(
                          tooltip: 'Mở menu',
                          onPressed: widget.onMenu,
                          icon: const Icon(Symbols.menu, color: _ink, size: 28),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Material(
                            color: Colors.white.withValues(alpha: .97),
                            borderRadius: BorderRadius.circular(32),
                            elevation: 5,
                            shadowColor: const Color(0x15233057),
                            child: InkWell(
                              key: const ValueKey('home-search'),
                              borderRadius: BorderRadius.circular(32),
                              onTap: widget.onSearch,
                              child: const Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 15,
                                ),
                                child: Row(
                                  children: [
                                    Icon(Symbols.search, size: 24, color: _ink),
                                    SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'Tìm kiếm nhà, phòng trọ...',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF778096),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Colors.white, Color(0xFFFFF3E7)],
                            ),
                            border: Border.all(color: const Color(0xFFEAD8C5)),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x183F2918),
                                blurRadius: 16,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: IconButton(
                            tooltip: 'Thông báo',
                            onPressed: widget.onNotifications,
                            style: IconButton.styleFrom(
                              foregroundColor: const Color(0xFF573B28),
                              fixedSize: const Size(48, 48),
                              shape: const CircleBorder(),
                            ),
                            icon: const Icon(
                              Symbols.notifications,
                              size: 25,
                              weight: 300,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(wide ? 36 : 20, 24, 16, 0),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: SizedBox(
                        width: wide ? 500 : constraints.maxWidth * .78,
                        child: Column(
                          key: ValueKey(_index),
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _slides[_index].$1,
                              style: TextStyle(
                                fontSize: wide ? 18 : 14,
                                color: _ink,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _slides[_index].$2,
                              style: TextStyle(
                                fontSize: wide ? 44 : 30,
                                height: 1.08,
                                letterSpacing: -.8,
                                fontWeight: FontWeight.w800,
                                color: _ink,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _slides[_index].$3,
                              style: TextStyle(
                                fontSize: wide ? 16 : 12.5,
                                height: 1.4,
                                color: const Color(0xFF46516A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(wide ? 30 : 14, 8, 0, 24),
                    child: Row(
                      children: [
                        for (var index = 0; index < _slides.length; index++)
                          Semantics(
                            selected: _index == index,
                            child: IconButton(
                              key: ValueKey('home-slide-$index'),
                              tooltip: 'Trang giới thiệu ${index + 1}',
                              constraints: const BoxConstraints(
                                minWidth: 28,
                                minHeight: 32,
                              ),
                              padding: const EdgeInsets.all(6),
                              onPressed: () => _slide(index),
                              icon: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _index == index
                                      ? _orange
                                      : const Color(0xFFD4CEC8),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
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
      final columns = constraints.maxWidth < 330 || largeText
          ? 2
          : (constraints.maxWidth >= 1000 && !round ? 8 : 4);
      final width = constraints.maxWidth / columns;
      return Wrap(
        runSpacing: 18,
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
                        const SizedBox(height: 8),
                        Text(
                          action.label,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 12.5,
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
      width: round ? 62 : 72,
      height: round ? 62 : 72,
      decoration: BoxDecoration(
        color: const Color(0xFFFFFAF5),
        border: Border.all(color: const Color(0xFFF3DDCD)),
        borderRadius: BorderRadius.circular(20),
      ),
      alignment: Alignment.center,
      child: HomeFeatureIcon(icon: action.icon, size: round ? 48 : 56),
    );
  }
}

class _ContactTile extends StatelessWidget {
  const _ContactTile({required this.action});
  final _Action action;
  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(18),
    onTap: action.onTap,
    child: Padding(
      padding: const EdgeInsets.all(5),
      child: Row(
        children: [
          _ActionIcon(action: action, round: true),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              action.label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _ink,
              ),
            ),
          ),
        ],
      ),
    ),
  );
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
          color: _orange,
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
          foregroundColor: _ink,
          padding: const EdgeInsets.symmetric(horizontal: 4),
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

class _DiscoveryCard extends StatelessWidget {
  const _DiscoveryCard({
    required this.title,
    required this.subtitle,
    required this.image,
    required this.onTap,
  });
  final String title, subtitle, image;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: title,
    child: Material(
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: MediaQuery.textScalerOf(context).scale(155),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(image, fit: BoxFit.cover),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0xE60B1931)],
                    stops: [.2, 1],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.15,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        height: 1.25,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const CircleAvatar(
                      radius: 11,
                      backgroundColor: Colors.white,
                      child: Icon(Symbols.arrow_forward, size: 16, color: _ink),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
