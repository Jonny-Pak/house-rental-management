import '../../../../core/layout/app_layout.dart';

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../cubit/create_listing_cubit.dart';
import '../cubit/create_listing_state.dart';
import '../widgets/listing_area_selector.dart';
import '../../../preferences/data/datasources/area_remote_data_source.dart';

const _kAccent = Color(0xFFD76B28);
const _kDark = Color(0xFF38291F);
const _kBackground = Color(0xFFFAF8F5);
const _kBorder = Color(0xFFEEDFD1);

class ListingPricingStep extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onSubmit;
  final VoidCallback onPreview;
  final AreaRemoteDataSource? areas;

  const ListingPricingStep({
    super.key,
    required this.onBack,
    required this.onSubmit,
    required this.onPreview,
    this.areas,
  });

  @override
  State<ListingPricingStep> createState() => _ListingPricingStepState();
}

class _ListingPricingStepState extends State<ListingPricingStep> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _depositController = TextEditingController();
  final _areaController = TextEditingController();
  final _picker = ImagePicker();

  Future<void> _pickImages(BuildContext context) async {
    final cubit = context.read<CreateListingCubit>();
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        cubit.addImages(images.map((e) => e.path).toList());
      }
    } catch (e) {
      debugPrint('Error picking images: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    final state = context.read<CreateListingCubit>().state;
    _areaController.text = state.calculatedArea > 0
        ? state.calculatedArea.toStringAsFixed(2)
        : '';
    _titleController.text = state.title;
    _descController.text = state.description;
    _priceController.text = state.rentPrice?.toStringAsFixed(0) ?? '';
    _depositController.text = state.depositAmount?.toStringAsFixed(0) ?? '';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _depositController.dispose();
    _areaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kBackground,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _kDark),
          onPressed: widget.onBack,
        ),
        title: const Text(
          'Giá thuê & mô tả',
          style: TextStyle(
            color: _kDark,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: AppContent(
        maxWidth: AppLayout.formWidth,
        child: BlocBuilder<CreateListingCubit, CreateListingState>(
          builder: (context, state) {
            final cubit = context.read<CreateListingCubit>();

            return Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      const Text(
                        'BƯỚC 04 / 04  ·  HOÀN THIỆN TIN ĐĂNG',
                        style: TextStyle(
                          fontSize: 10,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF8A7464),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Sẵn sàng đón người thuê',
                        style: TextStyle(
                          fontSize: 25,
                          height: 1.25,
                          fontWeight: FontWeight.w700,
                          color: _kDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Thêm hình ảnh, giá thuê và mô tả để hoàn thiện tin của bạn.',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.5,
                          color: Color(0xFF8A7464),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _PricingSection(
                        title: 'Diện tích & khu vực',
                        icon: Symbols.location_on,
                        children: [
                          _buildSectionTitle('Diện tích (m²) *'),
                          const SizedBox(height: 12),
                          _buildTextField(
                            controller: _areaController,
                            hint: 'Ví dụ: 30',
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            onChanged: (value) => cubit.updateArea(
                              double.tryParse(value.replaceAll(',', '.')) ?? 0,
                            ),
                          ),
                          const SizedBox(height: 24),
                          _buildSectionTitle('Khu vực hành chính *'),
                          const SizedBox(height: 12),
                          Theme(
                            data: Theme.of(context).copyWith(
                              inputDecorationTheme: InputDecorationTheme(
                                filled: true,
                                fillColor: const Color(0xFFFCFAF7),
                                labelStyle: const TextStyle(
                                  color: Color(0xFF8A7464),
                                  fontSize: 13,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 16,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(color: _kBorder),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(color: _kBorder),
                                ),
                                disabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(color: _kBorder),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(color: _kAccent),
                                ),
                              ),
                            ),
                            child: ListingAreaSelector(
                              dataSource: widget.areas,
                              onChanged: cubit.updateAreaId,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _PricingSection(
                        title: 'Hình ảnh không gian',
                        icon: Symbols.add_photo_alternate,
                        children: [
                          _buildSectionTitle('Hình ảnh (Tối đa 10 ảnh) *'),
                          const SizedBox(height: 12),
                          _buildImageSection(context, state, cubit),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _PricingSection(
                        title: 'Giá thuê & tiền cọc',
                        icon: Symbols.payments,
                        children: [
                          _buildSectionTitle(
                            state.propertyType == 'SHARED_ROOM'
                                ? 'Chi phí mỗi người (VND/tháng) *'
                                : 'Giá cho thuê (VND/tháng) *',
                          ),
                          const SizedBox(height: 12),
                          _buildTextField(
                            controller: _priceController,
                            hint: 'Nhập giá thuê',
                            keyboardType: TextInputType.number,
                            onChanged: (val) {
                              final price = double.tryParse(val);
                              cubit.updateRentPrice(price);
                            },
                          ),
                          const SizedBox(height: 24),

                          _buildSectionTitle(
                            state.propertyType == 'SHARED_ROOM'
                                ? 'Tiền cọc mỗi người (VND)'
                                : 'Tiền cọc (VND)',
                          ),
                          const SizedBox(height: 12),
                          _buildTextField(
                            controller: _depositController,
                            hint: 'Nhập số tiền cọc (nếu có)',
                            keyboardType: TextInputType.number,
                            onChanged: (val) {
                              final deposit = double.tryParse(val);
                              cubit.updateDepositAmount(deposit);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _PricingSection(
                        title: 'Nội dung tin đăng',
                        icon: Symbols.edit_note,
                        children: [
                          _buildSectionTitle('Bạn là *'),
                          const SizedBox(height: 12),
                          _buildDropdown(
                            value: state.posterType,
                            hint: 'Chọn tư cách người đăng',
                            items: const [
                              DropdownMenuItem(
                                value: 'CA_NHAN',
                                child: Text('Cá nhân (Chủ nhà)'),
                              ),
                              DropdownMenuItem(
                                value: 'MOI_GIOI',
                                child: Text('Môi giới'),
                              ),
                            ],
                            onChanged: (val) => cubit.updatePosterType(val),
                          ),
                          const SizedBox(height: 24),

                          _buildSectionTitle('Tiêu đề bài đăng *'),
                          const SizedBox(height: 12),
                          _buildTextField(
                            controller: _titleController,
                            hint: 'VD: Cho thuê nhà nguyên căn 2 tầng...',
                            onChanged: (val) => cubit.updateTitle(val),
                          ),
                          const SizedBox(height: 24),

                          _buildSectionTitle('Mô tả chi tiết *'),
                          const SizedBox(height: 12),
                          _buildTextField(
                            controller: _descController,
                            hint:
                                'Mô tả thêm về tiện ích, an ninh, điện nước...',
                            maxLines: 5,
                            onChanged: (val) => cubit.updateDescription(val),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '* Thông tin bắt buộc. Tin sẽ được Admin duyệt trước khi hiển thị công khai.',
                        style: TextStyle(
                          fontSize: 11,
                          height: 1.5,
                          color: Color(0xFF8A7464),
                        ),
                      ),
                    ],
                  ),
                ),

                Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: _kBorder)),
                  ),
                  child: SafeArea(
                    top: false,
                    minimum: const EdgeInsets.fromLTRB(20, 14, 20, 16),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final stacked =
                            MediaQuery.textScalerOf(context).scale(15) > 22;
                        final width = stacked
                            ? constraints.maxWidth
                            : (constraints.maxWidth - 12) / 2;
                        return Wrap(
                          spacing: 12,
                          runSpacing: 10,
                          children: [
                            SizedBox(
                              width: width,
                              child: OutlinedButton(
                                onPressed: _canProceed(state)
                                    ? widget.onPreview
                                    : null,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: _kAccent,
                                  side: const BorderSide(color: _kBorder),
                                  minimumSize: const Size.fromHeight(52),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: const Text(
                                  'Xem trước',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: width,
                              child: FilledButton(
                                onPressed: _canProceed(state)
                                    ? widget.onSubmit
                                    : null,
                                style: FilledButton.styleFrom(
                                  backgroundColor: _kAccent,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: const Color(
                                    0xFFF0EBE5,
                                  ),
                                  disabledForegroundColor: const Color(
                                    0xFFAD9D8E,
                                  ),
                                  minimumSize: const Size.fromHeight(52),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: const Text(
                                  'Đăng tin',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: _kDark,
      ),
    );
  }

  Widget _buildImageSection(
    BuildContext context,
    CreateListingState state,
    CreateListingCubit cubit,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        '${state.imagePaths.length}/10 ảnh · Ưu tiên ảnh rõ, đủ ánh sáng',
        style: const TextStyle(
          fontSize: 11,
          height: 1.5,
          color: Color(0xFF8A7464),
        ),
      ),
      const SizedBox(height: 12),
      Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          for (var index = 0; index < state.imagePaths.length; index++)
            SizedBox(
              width: 108,
              height: 108,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image(
                        image: kIsWeb
                            ? NetworkImage(state.imagePaths[index])
                            : FileImage(File(state.imagePaths[index]))
                                  as ImageProvider,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const ColoredBox(
                          color: Color(0xFFF5EFE8),
                          child: Icon(Symbols.image, color: Color(0xFFAA998A)),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 2,
                    right: 2,
                    child: IconButton(
                      tooltip: 'Xóa ảnh ${index + 1}',
                      onPressed: () => cubit.removeImage(index),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFFAE5141),
                      ),
                      icon: const Icon(Symbols.close, size: 18),
                    ),
                  ),
                ],
              ),
            ),
          if (state.imagePaths.length < 10)
            SizedBox(
              width: state.imagePaths.isEmpty ? double.infinity : 108,
              child: Material(
                color: const Color(0xFFFFF7EE),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Color(0xFFF1D6BB)),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => _pickImages(context),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 22,
                      horizontal: 12,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Symbols.add_photo_alternate,
                          size: 30,
                          color: _kAccent,
                        ),
                        const SizedBox(height: 7),
                        Text(
                          state.imagePaths.isEmpty
                              ? 'Thêm ảnh không gian'
                              : 'Thêm ảnh',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _kAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    ],
  );

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required ValueChanged<String> onChanged,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 15, color: _kDark),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFAA998A), fontSize: 13),
        filled: true,
        fillColor: const Color(0xFFFCFAF7),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _kBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _kBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _kAccent, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required String hint,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: value,
          hint: Text(
            hint,
            style: const TextStyle(color: Color(0xFF8A7464), fontSize: 13),
          ),
          itemHeight: null,
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(16),
          style: const TextStyle(fontSize: 14, color: _kDark),
          items: items,
          onChanged: onChanged,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _kDark),
        ),
      ),
    );
  }

  bool _canProceed(CreateListingState state) {
    if (state.propertyType == 'SHARED_ROOM' && !state.roommateInfo.isValid) {
      return false;
    }
    return state.status != CreateListingStatus.submitting &&
        state.areaId != null &&
        state.calculatedArea > 0 &&
        state.rentPrice != null &&
        state.rentPrice! > 0 &&
        state.posterType != null &&
        state.title.trim().isNotEmpty &&
        state.description.trim().isNotEmpty &&
        state.imagePaths.isNotEmpty;
  }
}

class _PricingSection extends StatelessWidget {
  const _PricingSection({
    required this.title,
    required this.icon,
    required this.children,
  });
  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: _kBorder),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0E1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: _kAccent, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _kDark,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        ...children,
      ],
    ),
  );
}
