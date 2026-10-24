import '../../../../core/layout/app_layout.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../home/presentation/widgets/home_feature_icon.dart';

import '../cubit/create_listing_cubit.dart';
import 'listing_details_step.dart';
import 'listing_location_map_step.dart';
import 'listing_pricing_step.dart';
import 'listing_preview_page.dart';
import '../cubit/create_listing_state.dart';

class CreateListingPage extends StatelessWidget {
  const CreateListingPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Provide the cubit at the root of the create listing flow.
    // This allows all steps to share the same draft state.
    return BlocProvider(
      create: (context) => CreateListingCubit(),
      child: const _CreateListingFlow(),
    );
  }
}

class _CreateListingFlow extends StatefulWidget {
  const _CreateListingFlow();

  @override
  State<_CreateListingFlow> createState() => _CreateListingFlowState();
}

class _CreateListingFlowState extends State<_CreateListingFlow> {
  final PageController _pageController = PageController();

  void _nextStep() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _previousStep() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Keep the draft across all steps and block repeated submission while saving.
    return BlocBuilder<CreateListingCubit, CreateListingState>(
      builder: (context, state) => Stack(
        children: [
          AbsorbPointer(
            absorbing: state.status == CreateListingStatus.submitting,
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(), // Disable swipe to navigate
              children: [
                // Step 1: Select listing type.
                _buildTypeSelectionStep(context),

                // Step 2: Location Map
                ListingLocationMapStep(
                  onBack: _previousStep,
                  onConfirm: () {
                    // Move to step 3 when confirmed
                    _nextStep();
                  },
                ),

                // Step 3: Property Details
                ListingDetailsStep(onBack: _previousStep, onNext: _nextStep),

                // Step 4: Pricing and General Info
                ListingPricingStep(
                  onBack: _previousStep,
                  onPreview: () {
                    // Push preview page
                    final state = context.read<CreateListingCubit>().state;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ListingPreviewPage(state: state),
                      ),
                    );
                  },
                  onSubmit: () async {
                    final cubit = context.read<CreateListingCubit>();
                    final success = await cubit.submit();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          success
                              ? 'Đã gửi tin. Tin sẽ xuất hiện trên bản đồ sau khi Admin duyệt.'
                              : cubit.state.errorMessage ??
                                    'Không thể gửi tin.',
                        ),
                      ),
                    );
                    if (success) Navigator.of(context).pop(true);
                  },
                ),
              ],
            ),
          ),
          if (state.status == CreateListingStatus.submitting)
            const Positioned.fill(
              child: ColoredBox(
                color: Color(0x66000000),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTypeSelectionStep(BuildContext context) {
    final cubit = context.read<CreateListingCubit>();
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAF8F5),
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        title: const Text(
          'Đăng tin mới',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Color(0xFF38291F),
          ),
        ),
        leading: IconButton(
          tooltip: 'Đóng',
          icon: const Icon(Symbols.close, size: 23),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: AppContent(
        maxWidth: AppLayout.formWidth,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBD9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'BƯỚC 01 / 04',
                      style: TextStyle(
                        color: Color(0xFFAF541E),
                        fontSize: 10,
                        letterSpacing: 1,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Loại bất động sản',
                      style: TextStyle(fontSize: 12, color: Color(0xFF927C6D)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              const Text(
                'Bắt đầu từ một\nkhông gian của bạn',
                style: TextStyle(
                  fontSize: 28,
                  height: 1.2,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF38291F),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Chọn loại bất động sản bạn muốn cho thuê.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: Color(0xFF8A7464),
                ),
              ),
              const SizedBox(height: 28),
              LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 560;
                  final width = wide
                      ? (constraints.maxWidth - 16) / 2
                      : constraints.maxWidth;
                  return Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      SizedBox(
                        width: width,
                        child: _TypeOptionCard(
                          title: 'Nhà nguyên căn',
                          subtitle: 'Không gian riêng cho gia đình, cho thuê toàn bộ ngôi nhà.',
                          icon: Symbols.home_work,
                          onTap: () {
                            cubit.updatePropertyType('WHOLE_HOUSE');
                            _nextStep();
                          },
                        ),
                      ),
                      SizedBox(
                        width: width,
                        child: _TypeOptionCard(
                          title: 'Phòng trọ',
                          subtitle: 'Phòng riêng trong dãy trọ hoặc nhà chung, tiện lợi và linh hoạt.',
                          icon: Symbols.apartment,
                          onTap: () {
                            cubit.updatePropertyType('BOARDING_ROOM');
                            _nextStep();
                          },
                        ),
                      ),
                      SizedBox(
                        width: width,
                        child: _TypeOptionCard(
                          title: 'Tìm người ở ghép',
                          subtitle: 'Chia sẻ không gian và chi phí, tìm bạn cùng phòng phù hợp.',
                          icon: Symbols.group,
                          onTap: () {
                            cubit.updatePropertyType('SHARED_ROOM');
                            _nextStep();
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 28),
              const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Symbols.verified_user,
                    size: 18,
                    color: Color(0xFFAD8A68),
                  ),
                  SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      'Tin đăng sẽ được kiểm duyệt trước khi hiển thị công khai.',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.5,
                        color: Color(0xFF927C6D),
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
}

class _TypeOptionCard extends StatelessWidget {
  const _TypeOptionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title, subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(24),
      side: const BorderSide(color: Color(0xFFEEDFD1)),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFF2E4), Color(0xFFFFFAF5)],
                    ),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Center(child: HomeFeatureIcon(icon: icon, size: 64)),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFAF5EF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Symbols.arrow_forward,
                    size: 19,
                    color: Color(0xFFAE6B3B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: Color(0xFF38291F),
              ),
            ),
            const SizedBox(height: 7),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 13,
                height: 1.5,
                color: Color(0xFF8A7464),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
