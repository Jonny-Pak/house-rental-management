import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../membership/presentation/pages/membership_page.dart';
import '../../../contract/presentation/pages/my_contracts_page.dart';
import '../../../map/presentation/pages/map_page.dart';
import '../../../property/presentation/pages/property_browse_page.dart';
import '../../../listing/presentation/pages/create_listing_page.dart';

// --- Design System Colors ---
const kOrange = Color(0xFFFF6B00);
const kOrangeDark = Color(0xFFE05A00);
const kBlack = Color(0xFF1A1A1A);
const kGrey = Color(0xFF8A8A8A);
const kLightGrey = Color(0xFFF5F5F5);
const kBorder = Color(0xFFE8E8E8);
const kGoldLabel = Color(0xFFD4A017);
// ----------------------------

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kLightGrey,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Header (Orange) ───
            _buildHeader(context),

            // ─── Features Card ───
            _buildFeaturesCard(context),

            const SizedBox(height: 12),

            // ─── Khám Phá Thêm ───
            _buildSectionHeader('Khám Phá Thêm', 'Xem thêm'),
            _buildBannerRow(),

            const SizedBox(height: 16),

            // ─── Các Chức Năng Khác ───
            _buildSectionHeader('Các Chức Năng Khác', 'Xem thêm'),
            _buildOtherFeaturesGrid(context),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  // ───────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Container(
      color: kOrange,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Menu button
              GestureDetector(
                onTap: () {},
                child: const Icon(Icons.menu, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 12),
              // Search bar
              Expanded(
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 12),
                      const Icon(Icons.search, color: kGrey, size: 20),
                      const SizedBox(width: 8),
                      const Text('Tìm kiếm', style: TextStyle(color: kGrey, fontSize: 15)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Notification bell
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.notifications_outlined, color: Colors.white, size: 24),
                  ),
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text('1', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ───────────────────────────────
  Widget _buildFeaturesCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 0),
      child: Stack(
        children: [
          // Orange background top portion
          Container(
            height: 60,
            color: kOrange,
          ),
          // White card
          Container(
            margin: const EdgeInsets.only(top: 24, left: 12, right: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Column(
              children: [
                // "Chức năng" gold label
                Transform.translate(
                  offset: const Offset(0, -14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFD4A017), Color(0xFFF0C040)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Chức năng',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                // "Xem thêm" row
                Padding(
                  padding: const EdgeInsets.only(right: 16, top: 0, bottom: 8),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () {},
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Text('Xem thêm', style: TextStyle(fontSize: 13, color: kBlack)),
                          SizedBox(width: 4),
                          Icon(Icons.chevron_right, size: 16, color: kBlack),
                        ],
                      ),
                    ),
                  ),
                ),

                // Row 1: 4 items
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildFeatureItem(context, Symbols.post_add, 'Đăng Tin', color: Colors.green, onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateListingPage()));
                      })),
                      Expanded(child: _buildFeatureItem(context, Symbols.maps_home_work, 'Thuê Nhà', color: Colors.blue, onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const PropertyBrowsePage(propertyType: 'WHOLE_HOUSE', title: 'Thuê Nhà')));
                      })),
                      Expanded(child: _buildFeatureItem(context, Symbols.corporate_fare, 'Thuê Phòng\nTrọ', color: Colors.orange, onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const PropertyBrowsePage(propertyType: 'BOARDING_HOUSE', title: 'Thuê Phòng Trọ')));
                      })),
                      Expanded(child: _buildFeatureItem(context, Symbols.assignment, 'Quản Lý\nTin Đăng', color: Colors.teal, onTap: () {})),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Row 2: 4 items
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildFeatureItem(context, Symbols.contract, 'Quản Lý\nHợp Đồng', color: Colors.purple, onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const MyContractsPage(isLandlord: true)));
                      })),
                      Expanded(child: _buildFeatureItem(context, Symbols.request_quote, 'Gói Dịch Vụ', color: Colors.amber.shade700, onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const MembershipPage()));
                      })),
                      Expanded(child: _buildFeatureItem(context, Symbols.map, 'Bản Đồ', color: Colors.red, onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const MapPage()));
                      })),
                      Expanded(child: _buildFeatureItem(context, Symbols.smart_toy, 'Trợ Lý AI', color: Colors.indigo, onTap: () {})),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(BuildContext context, IconData icon, String label, {VoidCallback? onTap, Color color = kBlack}) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 72,
        child: Column(
          children: [
            SizedBox(
              height: 56,
              child: Center(
                child: Icon(icon, size: 32, color: color, weight: 600),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: const TextStyle(fontSize: 11.5, color: kBlack, height: 1.3),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────────────
  Widget _buildSectionHeader(String title, String action) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: kBlack)),
          GestureDetector(
            onTap: () {},
            child: Row(
              children: [
                Text(action, style: const TextStyle(fontSize: 13, color: kBlack)),
                const Icon(Icons.chevron_right, size: 16, color: kBlack),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────
  Widget _buildBannerRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(child: _buildBannerCard()),
          const SizedBox(width: 12),
          Expanded(child: _buildBannerCard()),
        ],
      ),
    );
  }

  Widget _buildBannerCard() {
    return Container(
      height: 110,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 6,
            left: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text('TRỌ MỚI', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('RINH NGAY DEAL HỜI', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                const Text('Tặng 3 SLOT', style: TextStyle(color: Colors.yellow, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: kOrange,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('Tạo Trọ Mới', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────
  Widget _buildOtherFeaturesGrid(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildOtherFeatureItem(Symbols.tune, 'Giới Thiệu', Colors.blue)),
              Expanded(child: _buildOtherFeatureItem(Symbols.gavel, 'Quy Định', Colors.brown)),
              Expanded(child: _buildOtherFeatureItem(Symbols.help, 'Hướng Dẫn\nSử Dụng', Colors.green)),
              Expanded(child: _buildOtherFeatureItem(Symbols.report, 'Báo Cáo\nSự Cố', Colors.red)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildOtherFeatureItem(Symbols.support_agent, 'Liên Hệ', Colors.teal)),
              Expanded(child: const SizedBox()), // Empty spaces for alignment
              Expanded(child: const SizedBox()),
              Expanded(child: const SizedBox()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOtherFeatureItem(IconData icon, String label, Color color) {
    return SizedBox(
      width: 72,
      child: Column(
        children: [
          SizedBox(
            height: 56,
            child: Center(
              child: Icon(icon, size: 32, color: color, weight: 600),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: const TextStyle(fontSize: 11.5, color: kBlack, height: 1.3),
          ),
        ],
      ),
    );
  }
}
