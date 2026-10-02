import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../cubit/create_listing_cubit.dart';
import '../cubit/create_listing_state.dart';

const _kAccent = Color(0xFFD85D15);
const _kDark = Color(0xFF2C1D11);
const _kBackground = Color(0xFFFAF8F5);
const _kBorder = Color(0xFFE8DED1);

class ListingPricingStep extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onSubmit;
  final VoidCallback onPreview;

  const ListingPricingStep({
    super.key,
    required this.onBack,
    required this.onSubmit,
    required this.onPreview,
  });

  @override
  State<ListingPricingStep> createState() => _ListingPricingStepState();
}

class _ListingPricingStepState extends State<ListingPricingStep> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _depositController = TextEditingController();
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _kDark),
          onPressed: widget.onBack,
        ),
        title: const Text(
          'Thông tin giá & Mô tả',
          style: TextStyle(color: _kDark, fontSize: 16, fontWeight: FontWeight.w700),
        ),
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _kBorder),
        ),
      ),
      body: BlocBuilder<CreateListingCubit, CreateListingState>(
        builder: (context, state) {
          final cubit = context.read<CreateListingCubit>();

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // --- Hình ảnh ---
                    _buildSectionTitle('Hình ảnh (Tối đa 10 ảnh) *'),
                    const SizedBox(height: 12),
                    _buildImageSection(context, state, cubit),
                    const SizedBox(height: 24),

                    // --- Giá thuê ---
                    _buildSectionTitle('Giá cho thuê (VND/tháng) *'),
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

                    // --- Tiền cọc ---
                    _buildSectionTitle('Tiền cọc (VND)'),
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
                    const SizedBox(height: 24),

                    // --- Loại người đăng ---
                    _buildSectionTitle('Bạn là *'),
                    const SizedBox(height: 12),
                    _buildDropdown(
                      value: state.posterType,
                      hint: 'Chọn tư cách người đăng',
                      items: const [
                        DropdownMenuItem(value: 'CA_NHAN', child: Text('Cá nhân (Chủ nhà)')),
                        DropdownMenuItem(value: 'MOI_GIOI', child: Text('Môi giới')),
                      ],
                      onChanged: (val) => cubit.updatePosterType(val),
                    ),
                    const SizedBox(height: 24),

                    // --- Tiêu đề ---
                    _buildSectionTitle('Tiêu đề bài đăng *'),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _titleController,
                      hint: 'VD: Cho thuê nhà nguyên căn 2 tầng...',
                      onChanged: (val) => cubit.updateTitle(val),
                    ),
                    const SizedBox(height: 24),

                    // --- Mô tả ---
                    _buildSectionTitle('Mô tả chi tiết *'),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _descController,
                      hint: 'Mô tả thêm về tiện ích, an ninh, điện nước...',
                      maxLines: 5,
                      onChanged: (val) => cubit.updateDescription(val),
                    ),
                  ],
                ),
              ),

              // --- Bottom Navigation ---
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: _kBorder)),
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _canProceed(state) ? widget.onPreview : null,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _kAccent,
                            side: const BorderSide(color: _kAccent),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text(
                            'Xem trước',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: _canProceed(state) ? widget.onSubmit : null,
                          style: FilledButton.styleFrom(
                            backgroundColor: _kAccent,
                            disabledBackgroundColor: Colors.grey.shade300,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text(
                            'Đăng tin',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: _kDark,
      ),
    );
  }

  Widget _buildImageSection(BuildContext context, CreateListingState state, CreateListingCubit cubit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (state.imagePaths.isNotEmpty)
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: state.imagePaths.length + (state.imagePaths.length < 10 ? 1 : 0),
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                if (index == state.imagePaths.length) {
                  // Add more button
                  return _buildAddImageButton(context);
                }
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _kBorder),
                        image: DecorationImage(
                          image: FileImage(File(state.imagePaths[index])),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: -8,
                      right: -8,
                      child: GestureDetector(
                        onTap: () => cubit.removeImage(index),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                            ],
                          ),
                          child: const Icon(Icons.close, size: 16, color: Colors.redAccent),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          )
        else
          SizedBox(
            width: double.infinity,
            height: 100,
            child: _buildAddImageButton(context),
          ),
      ],
    );
  }

  Widget _buildAddImageButton(BuildContext context) {
    return InkWell(
      onTap: () => _pickImages(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 100,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _kAccent.withValues(alpha: 0.5), style: BorderStyle.solid),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate_outlined, color: _kAccent, size: 32),
            const SizedBox(height: 4),
            Text(
              'Thêm ảnh',
              style: TextStyle(color: _kAccent, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

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
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 15),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _kBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _kBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: value,
          hint: Text(hint, style: TextStyle(color: Colors.grey.shade400, fontSize: 15)),
          items: items,
          onChanged: onChanged,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _kDark),
        ),
      ),
    );
  }

  bool _canProceed(CreateListingState state) {
    return state.rentPrice != null && state.rentPrice! > 0 &&
           state.posterType != null &&
           state.title.trim().isNotEmpty &&
           state.description.trim().isNotEmpty &&
           state.imagePaths.isNotEmpty;
  }
}
