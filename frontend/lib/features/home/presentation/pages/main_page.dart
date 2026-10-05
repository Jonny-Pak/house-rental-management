import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../user/presentation/pages/profile_page.dart';
import 'home_page.dart';

const _kOrange = Color(0xFFFF6B00);
const _kBlack = Color(0xFF1A1A1A);
const _kGrey = Color(0xFF8A8A8A);

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomePage(),
    const Center(child: Text('Yêu thích', style: TextStyle(fontSize: 24, color: _kBlack))),
    const Center(child: Text('Danh sách', style: TextStyle(fontSize: 24, color: _kBlack))),
    const Center(child: Text('Thông báo', style: TextStyle(fontSize: 24, color: _kBlack))),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: const Color(0xFFF5F5F5),
      body: _pages[_currentIndex],
      bottomNavigationBar: _buildBottomNav(),
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
              height: 64,
              padding: const EdgeInsets.symmetric(horizontal: 16),
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
                  const SizedBox(width: 12),
                  _buildNavItem(1, Symbols.favorite, Symbols.favorite),
                  const SizedBox(width: 12),
                  _buildNavItem(2, Symbols.format_list_bulleted, Symbols.format_list_bulleted),
                  const SizedBox(width: 12),
                  _buildNavItem(3, Symbols.notifications, Symbols.notifications),
                  const SizedBox(width: 12),
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
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: isSelected ? _kOrange : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          isSelected ? activeIcon : inactiveIcon,
          color: _kBlack, // Icon is black even when active!
          size: 26,
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
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: isSelected ? _kOrange : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFFFD54F), // Yellow background matching the design's avatar
            ),
            child: const Icon(Symbols.person, size: 20, color: _kBlack, weight: 600),
          ),
        ),
      ),
    );
  }
}
