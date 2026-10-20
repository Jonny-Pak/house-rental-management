import 'package:flutter/material.dart';

import 'dart:math' as math;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/layout/app_layout.dart';
import '../../../auth/presentation/logout.dart';
import '../../../listing/presentation/pages/saved_listings_page.dart';
import '../../../listing/presentation/pages/my_listings_page.dart';
import '../../../user/data/datasources/user_remote_data_source.dart';
import '../../../user/data/repositories/user_repository.dart';
import '../../../user/presentation/bloc/profile_bloc.dart';
import '../../../user/presentation/bloc/profile_event.dart';
import '../../../user/presentation/bloc/profile_state.dart';
import '../../../user/presentation/pages/profile_page.dart';
import 'home_page.dart';
import '../theme/home_icon_colors.dart';

const _orange = Color(0xFFFF751B);

class MainPage extends StatefulWidget {
  const MainPage({super.key, this.userRepository});
  final UserRepository? userRepository;
  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final _scaffold = GlobalKey<ScaffoldState>();
  final _navigators = List.generate(5, (_) => GlobalKey<NavigatorState>());
  final _visited = <int>{0};
  final _atTabRoot = List<bool>.filled(5, true);
  late final List<_TabRouteObserver> _routeObservers;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _routeObservers = List.generate(
      5,
      (index) => _TabRouteObserver((atRoot) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _atTabRoot[index] != atRoot) {
            setState(() => _atTabRoot[index] = atRoot);
          }
        });
      }),
    );
  }

  void _select(int index) => setState(() {
    _visited.add(index);
    _index = index;
  });

  Widget _page(int index) => switch (index) {
    0 => HomePage(
      onMenu: () => _scaffold.currentState?.openDrawer(),
      onTabSelected: _select,
    ),
    1 => const SavedListingsPage(),
    2 => const MyListingsPage(),
    3 => const HomeNotificationsPage(),
    _ => const ProfilePage(),
  };

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => ProfileBloc(
      widget.userRepository ??
          UserRepositoryImpl(UserRemoteDataSourceImpl(ApiClient())),
    )..add(FetchProfileEvent()),
    child: Builder(
      builder: (context) => PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;
          final popped =
              await _navigators[_index].currentState?.maybePop() ?? false;
          if (!popped && mounted && _index != 0) _select(0);
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            final showRail = constraints.maxWidth >= AppLayout.compact;
            return Scaffold(
              key: _scaffold,
              extendBody: !showRail && _index == 0 && _atTabRoot[_index],
              backgroundColor: const Color(0xFFF7F7F7),
              drawer: _drawer(context),
              body: Row(
                children: [
                  if (showRail)
                    _rail(context, constraints.maxWidth >= AppLayout.expanded),
                  Expanded(
                    key: const ValueKey('tab-content'),
                    child: IndexedStack(
                      index: _index,
                      children: [
                        for (var i = 0; i < 5; i++)
                          _visited.contains(i)
                              ? Navigator(
                                  key: _navigators[i],
                                  observers: [_routeObservers[i]],
                                  onGenerateRoute: (_) => MaterialPageRoute(
                                    builder: (_) => _page(i),
                                  ),
                                )
                              : const SizedBox.shrink(),
                      ],
                    ),
                  ),
                ],
              ),
              bottomNavigationBar: !showRail && _atTabRoot[_index]
                  ? _navigation(context)
                  : null,
            );
          },
        ),
      ),
    ),
  );

  Widget _rail(BuildContext context, bool extended) => SizedBox(
    width: extended ? 240 : 88,
    child: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: SizedBox(
            height: math.max(560, constraints.maxHeight),
            child: NavigationRail(
              extended: extended,
              selectedIndex: _index,
              onDestinationSelected: _select,
              backgroundColor: Colors.white,
              indicatorColor: const Color(0xFFFFD5A1),
              labelType: extended
                  ? NavigationRailLabelType.none
                  : NavigationRailLabelType.selected,
              leading: IconButton(
                tooltip: 'Mở menu',
                onPressed: () => _scaffold.currentState?.openDrawer(),
                icon: const Icon(Symbols.menu),
              ),
              trailing: Padding(
                padding: const EdgeInsets.only(top: 24),
                child: IconButton(
                  tooltip: 'Đăng xuất',
                  onPressed: () => logout(context),
                  icon: const Icon(Symbols.logout),
                ),
              ),
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Symbols.home),
                  label: Text('Trang chủ'),
                ),
                NavigationRailDestination(
                  icon: Icon(Symbols.favorite),
                  label: Text('Yêu thích'),
                ),
                NavigationRailDestination(
                  icon: Icon(Symbols.view_list),
                  label: Text('Quản lý tin đăng'),
                ),
                NavigationRailDestination(
                  icon: Icon(Symbols.notifications),
                  label: Text('Thông báo'),
                ),
                NavigationRailDestination(
                  icon: Icon(Symbols.person),
                  label: Text('Tài khoản'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Widget _avatar({
    double radius = 15,
    Color? iconColor,
  }) => BlocBuilder<ProfileBloc, ProfileState>(
    builder: (_, state) {
      final url = state is ProfileLoaded ? state.profile.avatarUrl : null;
      return CircleAvatar(
        radius: radius,
        backgroundColor: const Color(0xFFFFD5A1),
        backgroundImage: url == null || url.isEmpty ? null : NetworkImage(url),
        onBackgroundImageError: url == null || url.isEmpty ? null : (_, _) {},
        child: url == null || url.isEmpty
            ? Icon(
                Symbols.person,
                size: radius * 1.4,
                color: iconColor ?? HomeIconColors.forIcon(Symbols.person),
                weight: 500,
              )
            : null,
      );
    },
  );

  Widget _navigation(BuildContext context) => SafeArea(
    minimum: const EdgeInsets.fromLTRB(12, 0, 12, 12),
    child: Center(
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Container(
          height:
              82 +
              (MediaQuery.textScalerOf(context).scale(12) - 12).clamp(0, 24),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0B172340),
                blurRadius: 24,
                offset: Offset(0, -3),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(child: _navItem(0, 'Trang chủ', Symbols.home)),
              Expanded(child: _navItem(1, 'Yêu thích', Symbols.favorite)),
              Expanded(child: _navItem(2, 'Tin đăng', Symbols.view_list)),
              Expanded(child: _navItem(3, 'Thông báo', Symbols.notifications)),
              Expanded(
                child: _navItem(4, 'Tài khoản', Symbols.person, avatar: true),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _navItem(
    int index,
    String label,
    IconData icon, {
    bool avatar = false,
  }) {
    final selected = _index == index;
    return Semantics(
      selected: selected,
      button: true,
      label: label,
      child: Tooltip(
        message: label,
        child: InkWell(
          onTap: () => _select(index),
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              color: selected ? const Color(0xFFFFF4ED) : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 5),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 29,
                  child: avatar
                      ? _avatar(radius: 14, iconColor: const Color(0xFF0B1535))
                      : Icon(
                          icon,
                          size: 28,
                          weight: 450,
                          fill: selected ? 1 : 0,
                          color: selected ? _orange : const Color(0xFF0B1535),
                        ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: selected ? _orange : const Color(0xFF71798D),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected ? _orange : Colors.transparent,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _drawer(BuildContext context) => Drawer(
    width: math.min(352, MediaQuery.sizeOf(context).width * .88),
    backgroundColor: const Color(0xFFFFFCF8),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.horizontal(right: Radius.circular(28)),
    ),
    child: SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 12, 8),
            child: Row(
              children: [
                const Icon(Symbols.home_work, color: _orange, size: 25),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Không gian của bạn',
                    style: TextStyle(
                      color: Color(0xFF573B28),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Đóng menu',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Symbols.close, size: 20),
                  color: const Color(0xFF927C6D),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _drawerProfile(),
                const Padding(
                  padding: EdgeInsets.fromLTRB(12, 26, 12, 12),
                  child: Text(
                    'KHÁM PHÁ & QUẢN LÝ',
                    style: TextStyle(
                      fontSize: 10,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF927C6D),
                    ),
                  ),
                ),
                for (final entry in [
                  (0, 'Trang chủ', Symbols.home),
                  (1, 'Yêu thích', Symbols.favorite),
                  (2, 'Quản lý tin đăng', Symbols.assignment),
                  (3, 'Thông báo', Symbols.notifications),
                  (4, 'Tài khoản', Symbols.person),
                ])
                  _drawerItem(context, entry.$1, entry.$2, entry.$3),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: OutlinedButton.icon(
              onPressed: () => logout(context),
              icon: const Icon(Symbols.logout, size: 21),
              label: const Text('Đăng xuất'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFAE5141),
                backgroundColor: const Color(0xFFFFF7F4),
                side: const BorderSide(color: Color(0xFFF0DAD3)),
                minimumSize: const Size.fromHeight(48),
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _drawerProfile() => BlocBuilder<ProfileBloc, ProfileState>(
    builder: (_, state) => Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF1DF), Color(0xFFFFFAF4)],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF0DDC9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: const Color(0xFFEBD3B7)),
            ),
            child: _avatar(radius: 28, iconColor: const Color(0xFF9A5A31)),
          ),
          const SizedBox(height: 16),
          Text(
            state is ProfileLoaded
                ? state.profile.fullName
                : 'Tài khoản của bạn',
            style: const TextStyle(
              fontSize: 19,
              height: 1.3,
              fontWeight: FontWeight.w700,
              color: Color(0xFF38291F),
            ),
          ),
          if (state is ProfileLoaded) ...[
            const SizedBox(height: 5),
            Text(
              state.profile.email,
              style: const TextStyle(fontSize: 12, color: Color(0xFF8A7464)),
            ),
          ],
        ],
      ),
    ),
  );

  Widget _drawerItem(
    BuildContext context,
    int index,
    String label,
    IconData icon,
  ) {
    final selected = _index == index;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        selected: selected,
        selectedColor: const Color(0xFFAF541E),
        textColor: const Color(0xFF573B28),
        selectedTileColor: const Color(0xFFFFEBD9),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: selected ? Colors.white : const Color(0xFFF6F0E9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: selected ? const Color(0xFFC56428) : const Color(0xFF8A7464),
            size: 22,
            weight: 350,
          ),
        ),
        title: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        trailing: selected
            ? Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: _orange,
                  shape: BoxShape.circle,
                ),
              )
            : null,
        onTap: () {
          Navigator.pop(context);
          _select(index);
        },
      ),
    );
  }
}

/// Report the active page depth without treating bottom sheets as detail pages.
class _TabRouteObserver extends NavigatorObserver {
  _TabRouteObserver(this.onChanged);
  final ValueChanged<bool> onChanged;
  final List<Route<dynamic>> _pages = [];

  void _notify() => onChanged(_pages.length <= 1);

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is PageRoute) _pages.add(route);
    _notify();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _pages.remove(route);
    _notify();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _pages.remove(route);
    _notify();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    final index = oldRoute == null ? -1 : _pages.indexOf(oldRoute);
    if (index >= 0) {
      if (newRoute is PageRoute) {
        _pages[index] = newRoute;
      } else {
        _pages.removeAt(index);
      }
    } else if (newRoute is PageRoute) {
      _pages.add(newRoute);
    }
    _notify();
  }
}

class HomeNotificationsPage extends StatelessWidget {
  const HomeNotificationsPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Thông báo')),
    body: const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Symbols.notifications, size: 48, color: _orange),
            SizedBox(height: 16),
            Text(
              'Thông báo hệ thống',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            Text(
              'Tính năng đang được phát triển. Bạn có thể xem trạng thái duyệt tin trong Quản lý tin đăng.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ),
  );
}
