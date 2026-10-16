import 'package:flutter/material.dart';

import '../../../../core/layout/app_layout.dart';

import 'package:material_symbols_icons/symbols.dart';

import '../theme/home_icon_colors.dart';

import '../../../contract/presentation/pages/my_contracts_page.dart';
import '../../../listing/presentation/pages/create_listing_page.dart';
import '../../../listing/presentation/pages/my_listings_page.dart';
import '../../../listing/presentation/pages/listing_browse_page.dart';
import '../../../map/presentation/pages/listing_map_page.dart';
import '../../../membership/presentation/pages/membership_page.dart';

const _orange = Color(0xFFFF751B);
const _ink = Color(0xFF262626);
const _background = Color(0xFFF7F7F7);

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
              Icon(icon, size: 36, color: HomeIconColors.forIcon(icon)),
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
      Symbols.tune,
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
  Widget build(BuildContext context) {
    return Material(
      color: _background,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppLayout.contentWidth),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final scale = (constraints.maxWidth / 430).clamp(0.85, 1.15);
              final side = 20.0 * scale;
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      height: 188 * scale + MediaQuery.paddingOf(context).top,
                      decoration: const BoxDecoration(
                        color: _orange,
                        borderRadius: BorderRadius.vertical(
                          bottom: Radius.circular(24),
                        ),
                      ),
                      padding: EdgeInsets.fromLTRB(
                        12 * scale,
                        MediaQuery.paddingOf(context).top + 16,
                        12 * scale,
                        0,
                      ),
                      alignment: Alignment.topCenter,
                      child: Row(
                        children: [
                          IconButton(
                            tooltip: 'Mở menu',
                            onPressed:
                                onMenu ??
                                () => Scaffold.maybeOf(context)?.openDrawer(),
                            icon: const Icon(
                              Symbols.menu,
                              size: 29,
                              weight: 600,
                              color: _ink,
                            ),
                          ),
                          Expanded(
                            child: Material(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(24),
                                onTap: () => _open(
                                  context,
                                  const ListingBrowsePage(
                                    title: 'Tìm kiếm nhà cho thuê',
                                    autofocus: true,
                                  ),
                                ),
                                child: Container(
                                  height: 34,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: const Color(0xFFFFC69F),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(
                                        Symbols.search,
                                        size: 21,
                                        color: _ink,
                                      ),
                                      SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          'Tìm kiếm',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: _ink,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Thông báo',
                            onPressed: () {
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
                            icon: const Icon(
                              Symbols.notifications,
                              size: 27,
                              color: _ink,
                              weight: 500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Transform.translate(
                      offset: Offset(0, -43 * scale),
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: side),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Material(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(22),
                              child: Padding(
                                padding: EdgeInsets.fromLTRB(
                                  9 * scale,
                                  26 * scale,
                                  9 * scale,
                                  14 * scale,
                                ),
                                child: Column(
                                  children: [
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: _More(
                                        onTap: () => _showAll(context),
                                        compact: true,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    _ActionGrid(
                                      actions: _primary(context),
                                      scale: scale,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              top: -9,
                              left: 0,
                              right: 0,
                              child: Center(
                                child: ClipPath(
                                  clipper: _RibbonClipper(),
                                  child: Container(
                                    width: 146 * scale,
                                    height: 23,
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Color(0xFFFFEFBA),
                                          Color(0xFFFFD77B),
                                          Color(0xFFFFEFBA),
                                        ],
                                      ),
                                    ),
                                    alignment: Alignment.center,
                                    child: const Text(
                                      'Chức năng',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: side + 6),
                      child: Transform.translate(
                        offset: Offset(0, -22 * scale),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _SectionHeader(
                              title: 'Khám Phá Thêm',
                              onMore: () => _open(
                                context,
                                const ListingBrowsePage(
                                  title: 'Khám phá tin cho thuê',
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _DiscoveryCard(
                                    title: 'TÌM NHÀ\nĐÚNG Ý',
                                    subtitle: 'Khám phá tổ ấm mới',
                                    icon: Symbols.home_work,
                                    colors: const [
                                      Color(0xFFE3F8FC),
                                      Color(0xFF2FC4E0),
                                    ],
                                    onTap: () => _open(
                                      context,
                                      const ListingBrowsePage(
                                        title: 'Thuê nhà',
                                        listingType: 'WHOLE_HOUSE',
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _DiscoveryCard(
                                    title: 'PHÒNG TRỌ\nQUANH BẠN',
                                    subtitle: 'Xem vị trí trên bản đồ',
                                    icon: Symbols.apartment,
                                    colors: const [
                                      Color(0xFFE7F3FF),
                                      Color(0xFF71A8EF),
                                    ],
                                    onTap: () =>
                                        _open(context, const ListingMapPage()),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 22),
                            _SectionHeader(
                              title: 'Các Chức Năng Khác',
                              onMore: () => _showAll(context),
                            ),
                            const SizedBox(height: 14),
                            _ActionGrid(
                              actions: _secondary(context),
                              scale: scale,
                              rowHeight: 91,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 96),
                  ],
                ),
              );
            },
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
          child: Padding(
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
                  actions: [..._primary(context), ..._secondary(context)]
                      .map(
                        (a) => _Action(a.label, a.icon, () {
                          Navigator.pop(sheetContext);
                          a.onTap();
                        }),
                      )
                      .toList(),
                  scale: 1,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Action {
  const _Action(this.label, this.icon, this.onTap);
  final String label;
  final IconData icon;
  final VoidCallback onTap;
}

class _ActionGrid extends StatelessWidget {
  const _ActionGrid({
    required this.actions,
    required this.scale,
    this.rowHeight = 85,
  });
  final List<_Action> actions;
  final double scale;
  final double rowHeight;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => Wrap(
      children: [
        for (final action in actions)
          SizedBox(
            width:
                constraints.maxWidth /
                (MediaQuery.textScalerOf(context).scale(14) > 18
                    ? (constraints.maxWidth >= 900 ? 4 : 2)
                    : (constraints.maxWidth >= 900 ? 8 : 4)),
            height:
                rowHeight * scale +
                (MediaQuery.textScalerOf(context).scale(14) - 14).clamp(0, 56) *
                    2.5,
            child: Semantics(
              button: true,
              label: action.label.replaceAll('\n', ' '),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: action.onTap,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      action.icon,
                      size: 34 * scale,
                      weight: 550,
                      opticalSize: 40,
                      color: HomeIconColors.forIcon(action.icon),
                    ),
                    SizedBox(height: 5 * scale),
                    Text(
                      action.label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11 * scale,
                        color: _ink,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
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
      Expanded(
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
      ),
      _More(onTap: onMore),
    ],
  );
}

class _More extends StatelessWidget {
  const _More({required this.onTap, this.compact = false});
  final VoidCallback onTap;
  final bool compact;
  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(8),
    onTap: onTap,
    child: Padding(
      padding: EdgeInsets.symmetric(horizontal: compact ? 0 : 2, vertical: 5),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Xem thêm', style: TextStyle(fontSize: 11, color: _ink)),
          SizedBox(width: 4),
          Icon(Symbols.chevron_right, size: 16, color: _ink),
        ],
      ),
    ),
  );
}

class _DiscoveryCard extends StatelessWidget {
  const _DiscoveryCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.colors,
    required this.onTap,
  });
  final String title, subtitle;
  final IconData icon;
  final List<Color> colors;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: title.replaceAll('\n', ' '),
    child: Material(
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          height: MediaQuery.textScalerOf(context).scale(88),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: colors,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -18,
                bottom: -22,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
              ),
              Positioned(
                right: 4,
                bottom: 9,
                child: Transform.rotate(
                  angle: -0.08,
                  child: Icon(
                    icon,
                    size: 57,
                    fill: 0,
                    weight: 400,
                    color: const Color(0xFF1162A5),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.2,
                        color: Color(0xFF124B91),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 8,
                        color: Color(0xFF164269),
                        fontWeight: FontWeight.w600,
                      ),
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

class _RibbonClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) => Path()
    ..moveTo(0, 0)
    ..lineTo(size.width, 0)
    ..lineTo(size.width - 17, size.height / 2)
    ..lineTo(size.width, size.height)
    ..lineTo(0, size.height)
    ..lineTo(17, size.height / 2)
    ..close();
  @override
  bool shouldReclip(_RibbonClipper oldClipper) => false;
}
