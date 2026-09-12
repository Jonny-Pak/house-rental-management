import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../../../core/network/api_client.dart';
import '../../../preferences/data/models/area_models.dart';
import '../../data/repositories/property_repository.dart';
import '../cubit/create_property_cubit.dart';
import '../cubit/create_property_state.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đăng tin cho thuê'),
        centerTitle: true,
      ),
      body: BlocConsumer<CreatePropertyCubit, CreatePropertyState>(
        listener: (context, state) {
          if (state.status == CreatePropertyStatus.success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Tạo khu trọ thành công!')),
            );
            Navigator.pop(context);
          } else if (state.status == CreatePropertyStatus.error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage ?? 'Đã xảy ra lỗi')),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state.status == CreatePropertyStatus.loading ||
              state.status == CreatePropertyStatus.uploadingImages;

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // Thông tin cơ bản
                Text('Thông tin cơ bản', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'WHOLE_HOUSE', label: Text('Nhà nguyên căn')),
                    ButtonSegment(value: 'BOARDING_HOUSE', label: Text('Khu trọ')),
                  ],
                  selected: {_propertyType},
                  onSelectionChanged: (Set<String> newSelection) {
                    setState(() {
                      _propertyType = newSelection.first;
                    });
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Tên khu trọ / Nhà',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v!.isEmpty ? 'Vui lòng nhập tên' : null,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _descController,
                  decoration: const InputDecoration(
                    labelText: 'Mô tả',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 24),

                // Vị trí
                Text('Vị trí', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                
                InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Tỉnh/Thành phố',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<Province>(
                      isExpanded: true,
                      value: state.selectedProvince,
                      hint: const Text('Chọn Tỉnh/Thành'),
                      items: state.provinces.map((p) {
                        return DropdownMenuItem(value: p, child: Text(p.name));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) context.read<CreatePropertyCubit>().onProvinceChanged(val);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Quận/Huyện',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<District>(
                      isExpanded: true,
                      value: state.selectedDistrict,
                      hint: const Text('Chọn Quận/Huyện'),
                      items: state.districts.map((d) {
                        return DropdownMenuItem(value: d, child: Text(d.name));
                      }).toList(),
                      onChanged: state.districts.isEmpty
                          ? null
                          : (val) {
                              if (val != null) context.read<CreatePropertyCubit>().onDistrictChanged(val);
                            },
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Phường/Xã',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<Ward>(
                      isExpanded: true,
                      value: state.selectedWard,
                      hint: const Text('Chọn Phường/Xã'),
                      items: state.wards.map((w) {
                        return DropdownMenuItem(value: w, child: Text(w.name));
                      }).toList(),
                      onChanged: state.wards.isEmpty
                          ? null
                          : (val) {
                              if (val != null) context.read<CreatePropertyCubit>().onWardChanged(val);
                            },
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'Số nhà, tên đường',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v!.isEmpty ? 'Vui lòng nhập địa chỉ' : null,
                ),
                const SizedBox(height: 24),

                // Giá cơ bản
                Text('Chi phí mặc định', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _elecPriceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Giá điện (VNĐ/kWh)',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => v!.isEmpty ? 'Nhập giá điện' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _waterPriceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Giá nước (VNĐ/khối)',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => v!.isEmpty ? 'Nhập giá nước' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Hình ảnh
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Hình ảnh', style: Theme.of(context).textTheme.titleLarge),
                    TextButton.icon(
                      onPressed: isLoading ? null : () => context.read<CreatePropertyCubit>().pickImages(),
                      icon: const Icon(Icons.add_photo_alternate),
                      label: const Text('Thêm ảnh'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                if (state.images.isNotEmpty)
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: state.images.length,
                      itemBuilder: (context, index) {
                        return Stack(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 8.0, top: 8.0),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  state.images[index].path,
                                  height: 90,
                                  width: 90,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: isLoading ? null : () => context.read<CreatePropertyCubit>().removeImage(index),
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close, size: 16, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  )
                else
                  Container(
                    height: 100,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text('Chưa có ảnh nào được chọn', style: TextStyle(color: Colors.grey)),
                    ),
                  ),
                const SizedBox(height: 32),

                // Submit
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: isLoading
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                              const SizedBox(width: 12),
                              Text(state.status == CreatePropertyStatus.uploadingImages
                                  ? 'Đang tải ảnh lên...'
                                  : 'Đang xử lý...'),
                            ],
                          )
                        : const Text('ĐĂNG TIN CHO THUÊ', style: TextStyle(fontSize: 16)),
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
