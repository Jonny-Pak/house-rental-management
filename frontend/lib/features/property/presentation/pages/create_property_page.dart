import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../../../core/network/api_client.dart';
import '../../../preferences/data/models/area_models.dart';
import '../../data/repositories/property_repository.dart';
import '../cubit/create_property_cubit.dart';
import '../cubit/create_property_state.dart';

// ─── Design System Colors ─────────────────────────────────────────────
const kPrimaryDark   = Color(0xFF2C1D11);
const kPrimaryAccent = Color(0xFFD85D15);
const kBackground    = Color(0xFFFAF8F5);
const kBorderColor   = Color(0xFFE8DED1);
const kSubText       = Color(0xFF64748B);
// ──────────────────────────────────────────────────────────────────────

class CreatePropertyPage extends StatelessWidget {
  const CreatePropertyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CreatePropertyCubit(
        PropertyRepository(GetIt.I<ApiClient>()),
      ),
      child: const CreatePropertyView(),
    );
  }
}

class CreatePropertyView extends StatefulWidget {
  const CreatePropertyView({super.key});

  @override
  State<CreatePropertyView> createState() => _CreatePropertyViewState();
}

class _CreatePropertyViewState extends State<CreatePropertyView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _addressController = TextEditingController();
  final _elecPriceController = TextEditingController();
  final _waterPriceController = TextEditingController();
  
  String _propertyType = 'WHOLE_HOUSE';

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _addressController.dispose();
    _elecPriceController.dispose();
    _waterPriceController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      context.read<CreatePropertyCubit>().submitProperty(
            name: _nameController.text,
            description: _descController.text,
            address: _addressController.text,
            electricityPrice: double.tryParse(_elecPriceController.text) ?? 0,
            waterPrice: double.tryParse(_waterPriceController.text) ?? 0,
            propertyType: _propertyType,
          );
    }
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, color: kPrimaryAccent, size: 22),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: kPrimaryDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hintText,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: kPrimaryDark,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 15, color: kPrimaryDark),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: kSubText, fontSize: 14),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kBorderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kBorderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kPrimaryAccent, width: 1.5),
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required String hintText,
    required T? value,
    required List<T> items,
    required String Function(T) itemLabel,
    required void Function(T?)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: kPrimaryDark,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        InputDecorator(
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kBorderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kBorderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kPrimaryAccent, width: 1.5),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              isExpanded: true,
              value: value,
              icon: const Icon(Icons.expand_more, color: kSubText),
              hint: Text(hintText, style: const TextStyle(color: kSubText, fontSize: 14)),
              style: const TextStyle(fontSize: 15, color: kPrimaryDark, fontWeight: FontWeight.w500),
              items: items.map((T item) {
                return DropdownMenuItem<T>(
                  value: item,
                  child: Text(itemLabel(item)),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        backgroundColor: kBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: kPrimaryDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Đăng tin cho thuê',
          style: TextStyle(
            color: kPrimaryDark,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: BlocConsumer<CreatePropertyCubit, CreatePropertyState>(
        listener: (context, state) {
          if (state.status == CreatePropertyStatus.success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Đăng tin thành công!'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context);
          } else if (state.status == CreatePropertyStatus.error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage ?? 'Đã xảy ra lỗi'),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state.status == CreatePropertyStatus.loading ||
              state.status == CreatePropertyStatus.uploadingImages;

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20.0),
              children: [
                // ─── THÔNG TIN CƠ BẢN ───
                _buildSectionTitle('Thông tin cơ bản', Icons.info_outline),
                
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'WHOLE_HOUSE', label: Text('Nhà nguyên căn', style: TextStyle(fontSize: 13))),
                    ButtonSegment(value: 'BOARDING_HOUSE', label: Text('Khu trọ', style: TextStyle(fontSize: 13))),
                  ],
                  selected: {_propertyType},
                  onSelectionChanged: (Set<String> newSelection) {
                    setState(() {
                      _propertyType = newSelection.first;
                    });
                  },
                  style: SegmentedButton.styleFrom(
                    backgroundColor: Colors.white,
                    selectedBackgroundColor: kPrimaryAccent.withValues(alpha: 0.1),
                    selectedForegroundColor: kPrimaryAccent,
                    side: const BorderSide(color: kBorderColor),
                  ),
                ),
                const SizedBox(height: 20),

                _buildTextField(
                  label: 'Tên khu trọ / Nhà',
                  hintText: 'Nhập tên khu trọ...',
                  controller: _nameController,
                  validator: (v) => v!.isEmpty ? 'Vui lòng nhập tên' : null,
                ),
                const SizedBox(height: 20),

                _buildTextField(
                  label: 'Mô tả chi tiết',
                  hintText: 'Nhập mô tả về khu trọ, tiện ích xung quanh...',
                  controller: _descController,
                  maxLines: 4,
                ),
                const SizedBox(height: 32),

                // ─── VỊ TRÍ ───
                _buildSectionTitle('Vị trí', Icons.location_on_outlined),
                
                _buildDropdown<Province>(
                  label: 'Tỉnh/Thành phố',
                  hintText: 'Chọn Tỉnh/Thành',
                  value: state.selectedProvince,
                  items: state.provinces,
                  itemLabel: (p) => p.name,
                  onChanged: (val) {
                    if (val != null) context.read<CreatePropertyCubit>().onProvinceChanged(val);
                  },
                ),
                const SizedBox(height: 16),

                _buildDropdown<District>(
                  label: 'Quận/Huyện',
                  hintText: 'Chọn Quận/Huyện',
                  value: state.selectedDistrict,
                  items: state.districts,
                  itemLabel: (d) => d.name,
                  onChanged: state.districts.isEmpty
                      ? null
                      : (val) {
                          if (val != null) context.read<CreatePropertyCubit>().onDistrictChanged(val);
                        },
                ),
                const SizedBox(height: 16),

                _buildDropdown<Ward>(
                  label: 'Phường/Xã',
                  hintText: 'Chọn Phường/Xã',
                  value: state.selectedWard,
                  items: state.wards,
                  itemLabel: (w) => w.name,
                  onChanged: state.wards.isEmpty
                      ? null
                      : (val) {
                          if (val != null) context.read<CreatePropertyCubit>().onWardChanged(val);
                        },
                ),
                const SizedBox(height: 16),

                _buildTextField(
                  label: 'Số nhà, tên đường',
                  hintText: 'Ví dụ: 123 Đường Nguyễn Văn Linh...',
                  controller: _addressController,
                  validator: (v) => v!.isEmpty ? 'Vui lòng nhập địa chỉ' : null,
                ),
                const SizedBox(height: 32),

                // ─── CHI PHÍ MẶC ĐỊNH ───
                _buildSectionTitle('Chi phí mặc định', Icons.payments_outlined),
                
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildTextField(
                        label: 'Giá điện',
                        hintText: 'VD: 3500',
                        controller: _elecPriceController,
                        keyboardType: TextInputType.number,
                        validator: (v) => v!.isEmpty ? 'Bắt buộc' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Padding(
                      padding: EdgeInsets.only(top: 40),
                      child: Text('đ/kWh', style: TextStyle(color: kSubText, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildTextField(
                        label: 'Giá nước',
                        hintText: 'VD: 20000',
                        controller: _waterPriceController,
                        keyboardType: TextInputType.number,
                        validator: (v) => v!.isEmpty ? 'Bắt buộc' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Padding(
                      padding: EdgeInsets.only(top: 40),
                      child: Text('đ/khối', style: TextStyle(color: kSubText, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // ─── HÌNH ẢNH ───
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSectionTitle('Hình ảnh', Icons.photo_library_outlined),
                    if (state.images.isNotEmpty)
                      TextButton.icon(
                        onPressed: isLoading ? null : () => context.read<CreatePropertyCubit>().pickImages(),
                        icon: const Icon(Icons.add, color: kPrimaryAccent),
                        label: const Text('Thêm ảnh', style: TextStyle(color: kPrimaryAccent)),
                      ),
                  ],
                ),
                
                if (state.images.isNotEmpty)
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: state.images.length,
                      itemBuilder: (context, index) {
                        return Stack(
                          children: [
                            Container(
                              margin: const EdgeInsets.only(right: 12.0, top: 8.0, bottom: 8.0),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: kBorderColor),
                                boxShadow: const [
                                  BoxShadow(color: Color(0x05000000), blurRadius: 4, offset: Offset(0, 2)),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  state.images[index].path,
                                  height: 104,
                                  width: 104,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 0,
                              right: 4,
                              child: GestureDetector(
                                onTap: isLoading ? null : () => context.read<CreatePropertyCubit>().removeImage(index),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
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
                  GestureDetector(
                    onTap: isLoading ? null : () => context.read<CreatePropertyCubit>().pickImages(),
                    child: Container(
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: kPrimaryAccent.withValues(alpha: 0.5), style: BorderStyle.solid),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_outlined, size: 40, color: kPrimaryAccent),
                          SizedBox(height: 8),
                          Text('Tải ảnh lên từ thiết bị', style: TextStyle(color: kPrimaryAccent, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 48),

                // ─── NÚT ĐĂNG TIN ───
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: isLoading
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                state.status == CreatePropertyStatus.uploadingImages
                                    ? 'Đang tải ảnh...'
                                    : 'Đang xử lý...',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ],
                          )
                        : const Text('ĐĂNG TIN', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }
}
