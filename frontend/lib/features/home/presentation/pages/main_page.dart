import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../user/presentation/pages/profile_page.dart';
import 'home_page.dart';

// --- Design System Colors ---
const kPrimaryDark   = Color(0xFF2C1D11);
const kPrimaryAccent = Color(0xFFD85D15);
const kBackground    = Color(0xFFFAF8F5);
const kSubText       = Color(0xFF64748B);
// ----------------------------

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomePage(),
    const Center(child: Text('Thông báo', style: TextStyle(fontSize: 24, color: kPrimaryDark))),
    const Center(child: Text('Chức năng', style: TextStyle(fontSize: 24, color: kPrimaryDark))),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      body: _pages[_currentIndex],
      // floatingActionButton: _currentIndex == 0 ? FloatingActionButton(
      //   onPressed: () {
      //     Navigator.push(
      //       context,
      //       MaterialPageRoute(builder: (context) => const CreatePropertyPage()),
      //     );
      //   },
      //   tooltip: 'Đăng tin mới',
      //   backgroundColor: kPrimaryAccent,
      //   child: const FaIcon(FontAwesomeIcons.plus, color: Colors.white),
      // ) : null,
      bottomNavigationBar: _buildCustomBottomNav(),
    );
  }

  Widget _buildCustomBottomNav() {
    return Container(
      color: kBackground, // outer bg for desktop
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    )
                  ],
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildNavItem(
                          index: 0,
                          icon: FontAwesomeIcons.house,
                          label: 'Trang chủ',
                        ),
                        _buildNavItem(
                          index: 1,
                          icon: FontAwesomeIcons.bell,
                          label: 'Thông báo',
                          badgeCount: 46,
                        ),
                        _buildNavItem(
                          index: 2,
                          icon: FontAwesomeIcons.layerGroup,
                          label: 'Chức năng',
                        ),
                        _buildNavItem(
                          index: 3,
                          icon: FontAwesomeIcons.circleUser,
                          label: 'Cá nhân',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required FaIconData icon,
    required String label,
    int badgeCount = 0,
  }) {
    final isSelected = _currentIndex == index;
    // Using blue to match the screenshot exactly, or you can change to kPrimaryAccent
    const activeColor = Color(0xFF1451C5); 
    const inactiveColor = Color(0xFF2D3748);

    final color = isSelected ? activeColor : inactiveColor;

    Widget iconWidget = FaIcon(
      icon,
      color: color,
      size: 22,
    );

    // If it has a badge
    if (badgeCount > 0) {
      iconWidget = Stack(
        clipBehavior: Clip.none,
        children: [
          iconWidget,
          Positioned(
            right: -8,
            top: -6,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Text(
                badgeCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          )
        ],
      );
    }

    // Active background behind icon
    Widget iconContainer = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? activeColor.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
      ),
      child: iconWidget,
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          iconContainer,
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
