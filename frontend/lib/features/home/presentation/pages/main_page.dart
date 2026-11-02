import '../../../auth/presentation/pages/qr_login_scanner_page.dart';
import '../../../listing/data/repositories/listing_repository.dart';
import '../../../listing/presentation/pages/create_listing_page.dart';
import '../widgets/user_bottom_navigation.dart';

import '../../../notification/data/notification_repository.dart';
import '../../../notification/presentation/notification_store.dart';
import '../../../notification/presentation/notifications_page.dart';

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
import '../widgets/user_navigation_drawer.dart';
import '../../../listing/presentation/pages/listing_browse_page.dart';
import '../../../contract/presentation/pages/my_contracts_page.dart';
import '../../../membership/presentation/pages/membership_page.dart';
import '../../../map/presentation/pages/listing_map_page.dart';
import '../../../content/presentation/system_content_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({
    super.key,
    this.userRepository,
    this.notificationRepository,
    this.listingRepository,
  });
  final UserRepository? userRepository;
  final NotificationRepository? notificationRepository;
  final ListingRepository? listingRepository;
  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final _scaffold = GlobalKey<ScaffoldState>();
  final _navigators = List.generate(5, (_) => GlobalKey<NavigatorState>());
  final _visited = <int>{0};
  final _showNavigation = List<bool>.filled(5, true);
  late final List<_TabRouteObserver> _routeObservers;
  int _index = 0;
  late final NotificationStore _notifications;

  @override
  void initState() {
    super.initState();
    _notifications = NotificationStore(
      widget.notificationRepository ?? NotificationRepository(ApiClient()),
    )..start();
    _routeObservers = List.generate(
      5,
      (index) => _TabRouteObserver((atRoot) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() => _showNavigation[index] = atRoot);
          }
        });
      }),
    );
  }

  @override
  void dispose() {
    _notifications.dispose();
    super.dispose();
  }

  void _select(int index) {
    if (index == 3) _notifications.refresh();
    final profileContext = _scaffold.currentContext;
    if (index == 4 && profileContext != null) {
      profileContext.read<ProfileBloc>().add(FetchProfileEvent());
    }
    setState(() {
      _visited.add(index);
      _index = index;
    });
  }

  Widget _page(int index) => switch (index) {
    0 => BlocBuilder<ProfileBloc, ProfileState>(
      builder: (_, state) => HomePage(
        userName: state is ProfileLoaded ? state.profile.fullName : null,
        listingRepository: widget.listingRepository,
        onMenu: () => _scaffold.currentState?.openDrawer(),
        onTabSelected: _select,
      ),
    ),
    1 => const SavedListingsPage(),
    2 => const MyListingsPage(),
    3 => NotificationsPage(store: _notifications),
    _ => const ProfilePage(),
  };

  @override
  Widget build(BuildContext context) =>
      NotificationScope(store: _notifications, child: _shell(context));

  Widget _shell(BuildContext context) => BlocProvider(
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
              extendBody:
                  !showRail && _index == 0 && _routeObservers[_index].atRoot,
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
                              ? TickerMode(
                                  enabled: _index == i,
                                  child: Navigator(
                                    key: _navigators[i],
                                    observers: [_routeObservers[i]],
                                    onGenerateRoute: (_) => MaterialPageRoute(
                                      builder: (_) => _page(i),
                                    ),
                                  ),
                                )
                              : const SizedBox.shrink(),
                      ],
                    ),
                  ),
                ],
              ),
              bottomNavigationBar: !showRail && _showNavigation[_index]
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
              indicatorColor: const Color(0xFFD8EDDF),
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
                  icon: NotificationBadge(child: Icon(Symbols.notifications)),
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

  Future<void> _onBottomSelected(int index) async {
    if (index == 2) {
      if (!_routeObservers[_index].atRoot) return;
      await _navigators[_index].currentState?.push(
        MaterialPageRoute(builder: (_) => const CreateListingPage()),
      );
      if (mounted && _index == 4) _select(4);
      return;
    }
    _select(index);
  }

  Widget _navigation(BuildContext context) => UserBottomNavigation(
    selectedIndex: _index == 2 ? -1 : _index,
    onSelected: _onBottomSelected,
  );

  Widget _drawer(BuildContext context) =>
      BlocBuilder<ProfileBloc, ProfileState>(
        builder: (_, state) => UserNavigationDrawer(
          profile: state is ProfileLoaded ? state.profile : null,
          selectedAction: const [
            'home',
            'favorites',
            'listings',
            'notifications',
            'profile',
          ][_index],
          onClose: () => _scaffold.currentState?.closeDrawer(),
          onAction: _onDrawerAction,
        ),
      );

  Future<void> _openDrawerPage(Widget page) async {
    await _navigators[_index].currentState?.push(
      MaterialPageRoute(builder: (_) => page),
    );
    if (mounted && _index == 4) _select(4);
  }

  void _onDrawerAction(String action) {
    _scaffold.currentState?.closeDrawer();
    switch (action) {
      case 'home':
        _select(0);
        break;
      case 'favorites':
        _select(1);
        break;
      case 'listings':
        _select(2);
        break;
      case 'notifications':
        _select(3);
        break;
      case 'profile':
        _select(4);
        break;
      case 'search':
        _openDrawerPage(
          ListingBrowsePage(
            title: 'Tìm kiếm',
            autofocus: true,
            repository: widget.listingRepository,
          ),
        );
        break;
      case 'rent-house':
        _openDrawerPage(
          ListingBrowsePage(
            title: 'Thuê nhà',
            listingType: 'WHOLE_HOUSE',
            repository: widget.listingRepository,
          ),
        );
        break;
      case 'rent-room':
        _openDrawerPage(
          ListingBrowsePage(
            title: 'Thuê phòng trọ',
            listingType: 'BOARDING_ROOM',
            repository: widget.listingRepository,
          ),
        );
        break;
      case 'roommate':
        _openDrawerPage(
          ListingBrowsePage(
            title: 'Tìm người ở ghép',
            listingType: 'SHARED_ROOM',
            repository: widget.listingRepository,
          ),
        );
        break;
      case 'post':
        _openDrawerPage(const CreateListingPage());
        break;
      case 'contracts':
        _openDrawerPage(const MyContractsPage(isLandlord: true));
        break;
      case 'qr-login':
        _openDrawerPage(const QrLoginScannerPage());
        break;
      case 'membership':
        _openDrawerPage(const MembershipPage());
        break;
      case 'map':
        _openDrawerPage(const ListingMapPage());
        break;
      case 'help':
        _openDrawerPage(const SystemContentPage(slug: 'guide'));
        break;
      case 'logout':
        logout(_scaffold.currentContext!);
        break;
    }
  }
}

/// Report the active page depth without treating bottom sheets as detail pages.
class _TabRouteObserver extends NavigatorObserver {
  _TabRouteObserver(this.onChanged);
  final ValueChanged<bool> onChanged;
  final List<Route<dynamic>> _pages = [];
  bool get atRoot => _pages.length <= 1;

  void _notify() => onChanged(atRoot);

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
