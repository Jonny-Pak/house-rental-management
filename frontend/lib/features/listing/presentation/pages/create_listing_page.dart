import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/create_listing_cubit.dart';
import 'listing_details_step.dart';
import 'listing_location_map_step.dart';
import 'listing_pricing_step.dart';
import 'listing_preview_page.dart';
import 'my_listings_page.dart';

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
  Widget build(BuildContext context) {
    // For now, we only have Step 2 (Map) implemented as a full page component.
    // We can just show the ListingLocationMapStep directly or in a PageView.
    return PageView(
      controller: _pageController,
      physics: const NeverScrollableScrollPhysics(), // Disable swipe to navigate
      children: [
        // Step 1: Select Type (Placeholder)
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
        ListingDetailsStep(
          onBack: _previousStep,
          onNext: _nextStep,
        ),

        // Step 4: Pricing and General Info
        ListingPricingStep(
          onBack: _previousStep,
          onPreview: () {
            // Push preview page
            final state = context.read<CreateListingCubit>().state;
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ListingPreviewPage(state: state)),
            );
          },
          onSubmit: () {
            // Show toast and navigate to management page
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Đăng tin thành công!')),
            );
            // In a real app we'd pop to home then push MyListingsPage.
            // For now, we replace the create flow with MyListingsPage.
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const MyListingsPage()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTypeSelectionStep(BuildContext context) {
    final cubit = context.read<CreateListingCubit>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đăng tin mới'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bạn muốn cho thuê loại bất động sản nào?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            _TypeOptionCard(
              title: 'Nhà nguyên căn',
              subtitle: 'Cho thuê toàn bộ ngôi nhà, phù hợp cho gia đình.',
              icon: Icons.house_rounded,
              onTap: () {
                cubit.updatePropertyType('WHOLE_HOUSE');
                _nextStep();
              },
            ),
            const SizedBox(height: 16),
            _TypeOptionCard(
              title: 'Phòng trọ',
              subtitle: 'Cho thuê phòng riêng lẻ trong dãy trọ hoặc nhà chung.',
              icon: Icons.meeting_room_rounded,
              onTap: () {
                cubit.updatePropertyType('BOARDING_ROOM');
                _nextStep();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeOptionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _TypeOptionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFD85D15).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: const Color(0xFFD85D15), size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
