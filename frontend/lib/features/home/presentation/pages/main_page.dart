import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/storage/token_storage.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../../favorites/presentation/pages/saved_properties_page.dart';
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
    1 => const SavedPropertiesPage(),
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
        child: Scaffold(
          key: _scaffold,
          extendBody: _index == 0 && _atTabRoot[_index],
          backgroundColor: const Color(0xFFF7F7F7),
          drawer: _drawer(context),
          body: IndexedStack(
            index: _index,
            children: [
              for (var i = 0; i < 5; i++)
                _visited.contains(i)
                    ? Navigator(
                        key: _navigators[i],
                        observers: [_routeObservers[i]],
                        onGenerateRoute: (_) =>
                            MaterialPageRoute(builder: (_) => _page(i)),
                      )
                    : const SizedBox.shrink(),
            ],
          ),
          bottomNavigationBar: _atTabRoot[_index] ? _navigation(context) : null,
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
    minimum: const EdgeInsets.fromLTRB(22, 0, 22, 16),
    child: Center(
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _navItem(0, 'Trang chủ', Symbols.home),
              _navItem(1, 'Yêu thích', Symbols.favorite),
              _navItem(2, 'Danh sách', Symbols.view_list),
              _navItem(3, 'Thông báo', Symbols.notifications),
              _navItem(4, 'Tài khoản', Symbols.person, avatar: true),
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
  }) => Semantics(
    selected: _index == index,
    button: true,
    label: label,
    child: Tooltip(
      message: label,
      child: InkResponse(
        onTap: () => _select(index),
        radius: 25,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: _index == index ? _orange : Colors.transparent,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: avatar
              ? _avatar(iconColor: Colors.black)
              : Icon(icon, size: 30, weight: 550, fill: 0, color: Colors.black),
        ),
      ),
    ),
  );

  Widget _drawer(BuildContext context) => Drawer(
    child: SafeArea(
      child: Column(
        children: [
          BlocBuilder<ProfileBloc, ProfileState>(
            builder: (_, state) => Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              color: _orange,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _avatar(radius: 28),
                  const SizedBox(height: 12),
                  Text(
                    state is ProfileLoaded
                        ? state.profile.fullName
                        : 'Tài khoản của bạn',
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  if (state is ProfileLoaded)
                    Text(
                      state.profile.email,
                      style: const TextStyle(color: Colors.white),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          for (final entry in [
            (0, 'Trang chủ', Symbols.home),
            (1, 'Yêu thích', Symbols.favorite),
            (2, 'Quản lý tin đăng', Symbols.assignment),
            (3, 'Thông báo', Symbols.notifications),
            (4, 'Tài khoản', Symbols.person),
          ])
            ListTile(
              selected: _index == entry.$1,
              selectedColor: _orange,
              leading: Icon(entry.$3, color: HomeIconColors.forIcon(entry.$3)),
              title: Text(entry.$2),
              onTap: () {
                Navigator.pop(context);
                _select(entry.$1);
              },
            ),
          const Spacer(),
          const Divider(),
          ListTile(
            leading: Icon(
              Symbols.logout,
              color: HomeIconColors.forIcon(Symbols.logout),
            ),
            title: const Text('Đăng xuất'),
            onTap: () async {
              await TokenStorage.clearToken();
              if (context.mounted) {
                Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (_) => false,
                );
              }
            },
          ),
        ],
      ),
    ),
  );
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
