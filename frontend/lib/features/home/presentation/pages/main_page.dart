import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/network/api_client.dart';
import '../../../user/data/datasources/user_remote_data_source.dart';
import '../../../user/data/repositories/user_repository.dart';
import '../../../user/presentation/bloc/profile_bloc.dart';
import '../../../user/presentation/bloc/profile_event.dart';
import '../../../user/presentation/bloc/profile_state.dart';
import '../../../user/presentation/pages/profile_page.dart';
import 'home_page.dart';

const _kOrange = Color(0xFFFF6B00);
const _kBlack = Color(0xFF1A1A1A);

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;

  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];

  final List<Widget> _pages = [
    const HomePage(),
    const Center(child: Text('Yêu thích', style: TextStyle(fontSize: 24, color: _kBlack))),
    const Center(child: Text('Danh sách', style: TextStyle(fontSize: 24, color: _kBlack))),
    const Center(child: Text('Thông báo', style: TextStyle(fontSize: 24, color: _kBlack))),
    const ProfilePage(),
  ];

  Widget _buildNavigator(int index) {
    return Navigator(
      key: _navigatorKeys[index],
      onGenerateRoute: (settings) {
        return MaterialPageRoute(builder: (context) => _pages[index]);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final isFirstRouteInCurrentTab = !await _navigatorKeys[_currentIndex].currentState!.maybePop();
        if (isFirstRouteInCurrentTab) {
          if (_currentIndex != 0) {
            setState(() {
              _currentIndex = 0;
            });
          } else {
            // Let system handle exit
          }
        }
      },
      child: BlocProvider(
        create: (context) {
          final apiClient = GetIt.I<ApiClient>();
          final remoteDataSource = UserRemoteDataSourceImpl(apiClient);
          final repository = UserRepositoryImpl(remoteDataSource);
          return ProfileBloc(repository)..add(FetchProfileEvent());
        },
        child: Scaffold(
          extendBody: true,
          backgroundColor: const Color(0xFFF5F5F5),
          drawer: _buildDrawer(context),
          body: IndexedStack(
            index: _currentIndex,
            children: List.generate(5, (index) => _buildNavigator(index)),
          ),
          bottomNavigationBar: _buildBottomNav(),
        ),
      ),
    );
  }
  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required bool isSelected,
    Color? color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      selected: isSelected,
      selectedTileColor: _kOrange.withValues(alpha: 0.12),
      leading: Icon(icon, color: color ?? (isSelected ? _kOrange : _kBlack), weight: 600),
      title: Text(
        title,
        style: TextStyle(
          color: color ?? (isSelected ? _kOrange : _kBlack),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: BlocBuilder<ProfileBloc, ProfileState>(
        builder: (context, state) {
          String name = 'Đang tải...';
          String email = '';
          String? avatarUrl;

          if (state is ProfileLoaded) {
            name = state.profile.fullName;
            email = state.profile.email;
            avatarUrl = state.profile.avatarUrl;
          }

          return Column(
            children: [
              // Custom Header
              Container(
                color: _kOrange,
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 24,
                  bottom: 24,
                  left: 20,
                  right: 20,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                      onBackgroundImageError: (e, s) {},
                      child: avatarUrl == null || avatarUrl.isEmpty
                          ? const Icon(Symbols.person, size: 36, color: _kOrange)
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            email,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              
              // Navigation Items
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _buildDrawerItem(
                      context: context,
                      icon: Symbols.home,
                      title: 'Trang chủ',
                      isSelected: _currentIndex == 0,
                      onTap: () {
                        Navigator.pop(context);
                        setState(() => _currentIndex = 0);
                      },
                    ),
                    _buildDrawerItem(
                      context: context,
                      icon: Symbols.favorite,
                      title: 'Yêu thích',
                      isSelected: _currentIndex == 1,
                      onTap: () {
                        Navigator.pop(context);
                        setState(() => _currentIndex = 1);
                      },
                    ),
                    _buildDrawerItem(
                      context: context,
                      icon: Symbols.format_list_bulleted,
                      title: 'Danh sách',
                      isSelected: _currentIndex == 2,
                      onTap: () {
                        Navigator.pop(context);
                        setState(() => _currentIndex = 2);
                      },
                    ),
                    _buildDrawerItem(
                      context: context,
                      icon: Symbols.person,
                      title: 'Tài khoản',
                      isSelected: _currentIndex == 4,
                      onTap: () {
                        Navigator.pop(context);
                        setState(() => _currentIndex = 4);
                      },
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      child: Divider(color: Color(0xFFEEEEEE)),
                    ),
                    _buildDrawerItem(
                      context: context,
                      icon: Symbols.settings,
                      title: 'Cài đặt',
                      isSelected: false,
                      onTap: () {
                        Navigator.pop(context);
                      },
                    ),
                    _buildDrawerItem(
                      context: context,
                      icon: Symbols.logout,
                      title: 'Đăng xuất',
                      isSelected: false,
                      color: Colors.red,
                      onTap: () {
                        Navigator.pop(context);
                        // TODO: Implement logout
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBottomNav() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.white, // White color
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildNavItem(0, Symbols.home, Symbols.home),
                  const SizedBox(width: 20),
                  _buildNavItem(1, Symbols.favorite, Symbols.favorite),
                  const SizedBox(width: 20),
                  _buildNavItem(2, Symbols.format_list_bulleted, Symbols.format_list_bulleted),
                  const SizedBox(width: 20),
                  _buildNavItem(3, Symbols.notifications, Symbols.notifications),
                  const SizedBox(width: 20),
                  _buildAvatarNavItem(4),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData activeIcon, IconData inactiveIcon) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _currentIndex = index),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isSelected ? _kOrange : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          isSelected ? activeIcon : inactiveIcon,
          color: _kBlack, // Icon is black even when active!
          size: 24,
          weight: 600,
        ),
      ),
    );
  }

  Widget _buildAvatarNavItem(int index) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _currentIndex = index),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isSelected ? _kOrange : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: BlocBuilder<ProfileBloc, ProfileState>(
            builder: (context, state) {
              String? avatarUrl;
              if (state is ProfileLoaded) {
                avatarUrl = state.profile.avatarUrl;
              }

              return Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFFD54F), // Fallback yellow
                  image: avatarUrl != null && avatarUrl.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(avatarUrl),
                          fit: BoxFit.cover,
                          onError: (e, s) {},
                        )
                      : null,
                ),
                child: avatarUrl == null || avatarUrl.isEmpty
                    ? const Icon(Symbols.person, size: 18, color: _kBlack, weight: 600)
                    : null,
              );
            },
          ),
        ),
      ),
    );
  }
}