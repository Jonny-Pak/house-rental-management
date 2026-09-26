import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../membership/presentation/pages/membership_page.dart';
import '../../../contract/presentation/pages/my_contracts_page.dart';
import '../../../map/presentation/pages/map_page.dart';
import '../../../property/presentation/pages/property_browse_page.dart';

// --- Design System Colors ---
const kPrimaryDark   = Color(0xFF2C1D11); // Brown
const kPrimaryAccent = Color(0xFFD85D15); // Orange
const kBackground    = Color(0xFFFAF8F5); // Off-white
const kBorderColor   = Color(0xFFE8DED1); // Border
const kSubText       = Color(0xFF64748B); // Slate subtitle text
// ----------------------------

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 800;
    final contentWidth = isDesktop ? 800.0 : screenWidth;
    final crossAxisCount = isDesktop ? 8 : 4;

    return Scaffold(
      backgroundColor: kBackground,
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: contentWidth),
          child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                // 1. Header Background
                Container(
                  height: 300,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [kPrimaryAccent, kPrimaryDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(32),
                      bottomRight: Radius.circular(32),
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const FaIcon(FontAwesomeIcons.buildingUser, color: Colors.white, size: 20),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'House Rental Management',
                                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Quản lý Trọ',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Ứng dụng dành cho Chủ trọ & Người thuê',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 15),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // 2. Main Features Card
                Container(
                  margin: const EdgeInsets.only(top: 200, left: 16, right: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Card Header
                      Padding(
                        padding: const EdgeInsets.only(left: 20, right: 16, top: 20, bottom: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Chức năng',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kPrimaryDark),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const FaIcon(FontAwesomeIcons.sliders, color: kPrimaryAccent, size: 20),
                                  onPressed: () {},
                                ),
                                Container(width: 1, height: 20, color: kBorderColor),
                                IconButton(
                                  icon: const FaIcon(FontAwesomeIcons.magnifyingGlass, color: kPrimaryAccent, size: 20),
                                  onPressed: () {},
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                      
                      // Grid of features
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: crossAxisCount,
                          childAspectRatio: 0.7,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 8,
                          children: [
                            _buildFeatureItem(FontAwesomeIcons.house, 'Thuê nhà', Colors.blue, onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => const PropertyBrowsePage(propertyType: 'WHOLE_HOUSE', title: 'Thuê nhà')));
                            }),
                            _buildFeatureItem(FontAwesomeIcons.building, 'Thuê phòng trọ', Colors.orange, onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => const PropertyBrowsePage(propertyType: 'BOARDING_HOUSE', title: 'Thuê phòng trọ')));
                            }),
                            _buildFeatureItem(FontAwesomeIcons.plus, 'Đăng tin', Colors.teal, onTap: () {}),
                            _buildFeatureItem(FontAwesomeIcons.houseUser, 'Quản lý', Colors.deepOrange, onTap: () {}),
                            _buildFeatureItem(FontAwesomeIcons.fileSignature, 'Hợp đồng', Colors.green, onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => const MyContractsPage(isLandlord: true)));
                            }),
                            _buildFeatureItem(FontAwesomeIcons.fileInvoiceDollar, 'Hóa đơn', Colors.red, onTap: () {}),
                            _buildFeatureItem(FontAwesomeIcons.gem, 'Dịch vụ', Colors.purple, onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => const MembershipPage()));
                            }),
                            _buildFeatureItem(FontAwesomeIcons.map, 'Bản đồ', Colors.teal, onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => const MapPage()));
                            }),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 32),

            // 3. Banner Image placeholder
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  height: 140,
                  width: double.infinity,
                  color: kPrimaryDark.withValues(alpha: 0.1),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        'https://images.unsplash.com/photo-1560518883-ce09059eeffa?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
                        fit: BoxFit.cover,
                      ),
                      Container(
                        color: Colors.black.withValues(alpha: 0.3),
                      ),
                      const Center(
                        child: Text(
                          'Khu trọ nổi bật',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // 5. Chức năng khác (Other Features)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(
                'Chức năng khác',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kPrimaryDark),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: crossAxisCount,
                childAspectRatio: 0.75,
                mainAxisSpacing: 16,
                crossAxisSpacing: 12,
                children: [
                  _buildOtherFeatureItem(FontAwesomeIcons.bookOpen, 'Hướng dẫn sử dụng', Colors.blue),
                  _buildOtherFeatureItem(FontAwesomeIcons.shieldHalved, 'Quy định chung', Colors.orange),
                  _buildOtherFeatureItem(FontAwesomeIcons.circleQuestion, 'Câu hỏi thường gặp', Colors.green),
                  _buildOtherFeatureItem(FontAwesomeIcons.users, 'Cộng đồng', Colors.purple),
                  _buildOtherFeatureItem(FontAwesomeIcons.triangleExclamation, 'Báo cáo sự cố', Colors.red),
                  _buildOtherFeatureItem(FontAwesomeIcons.phone, 'Liên hệ', Colors.teal),
                ],
              ),
            ),

            const SizedBox(height: 60), // Bottom padding
          ],
        ),
      ),
    )));
  }

  Widget _buildFeatureItem(FaIconData icon, String title, Color color, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: FaIcon(icon, color: color, size: 24),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: kPrimaryDark,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtherFeatureItem(FaIconData icon, String title, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: kBorderColor, width: 0.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Center(
            child: FaIcon(icon, color: color, size: 24),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          textAlign: TextAlign.center,
          maxLines: 2,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.blueAccent,
            height: 1.2,
          ),
        ),
      ],
    );
  }
}
