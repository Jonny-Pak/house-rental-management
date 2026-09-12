import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/repositories/property_repository.dart';
import 'create_property_state.dart';
import '../../../preferences/data/models/area_models.dart';

class CreatePropertyCubit extends Cubit<CreatePropertyState> {
  final PropertyRepository _repository;
  final ImagePicker _imagePicker = ImagePicker();

  CreatePropertyCubit(this._repository) : super(const CreatePropertyState()) {
    loadProvinces();
  }

  Future<void> loadProvinces() async {
    try {
      final provinces = await _repository.getProvinces();
      emit(state.copyWith(provinces: provinces));
    } catch (e) {
      emit(state.copyWith(
        status: CreatePropertyStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> onProvinceChanged(Province province) async {
    emit(state.copyWith(
      selectedProvince: province,
      clearSelectedDistrict: true,
      clearSelectedWard: true,
      districts: [],
      wards: [],
    ));
    try {
      final districts = await _repository.getDistricts(province.id);
      emit(state.copyWith(districts: districts));
    } catch (e) {
      emit(state.copyWith(
        status: CreatePropertyStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> onDistrictChanged(District district) async {
    emit(state.copyWith(
      selectedDistrict: district,
      clearSelectedWard: true,
      wards: [],
    ));
    try {
      final wards = await _repository.getWards(district.id);
      emit(state.copyWith(wards: wards));
    } catch (e) {
      emit(state.copyWith(
        status: CreatePropertyStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  void onWardChanged(Ward ward) {
    emit(state.copyWith(selectedWard: ward));
  }

  Future<void> pickImages() async {
    try {
      final List<XFile> selectedImages = await _imagePicker.pickMultiImage();
      if (selectedImages.isNotEmpty) {
        final newImages = List<XFile>.from(state.images)..addAll(selectedImages);
        emit(state.copyWith(images: newImages));
      }
    } catch (e) {
      emit(state.copyWith(
        status: CreatePropertyStatus.error,
        errorMessage: 'Lỗi chọn ảnh: $e',
      ));
    }
  }

  void removeImage(int index) {
    final newImages = List<XFile>.from(state.images)..removeAt(index);
    emit(state.copyWith(images: newImages));
  }

  Future<void> submitProperty({
    required String name,
    required String description,
    required String address,
    required double electricityPrice,
    required double waterPrice,
    required String propertyType,
  }) async {
    if (state.selectedProvince == null ||
        state.selectedDistrict == null ||
        state.selectedWard == null) {
      emit(state.copyWith(
        status: CreatePropertyStatus.error,
        errorMessage: 'Vui lòng chọn đầy đủ Tỉnh/Thành, Quận/Huyện, Phường/Xã',
      ));
      return;
    }

    try {
      emit(state.copyWith(status: CreatePropertyStatus.uploadingImages));
      
      List<String> imageUrls = [];
      for (var file in state.images) {
        final url = await _repository.uploadImage(file);
        imageUrls.add(url);
      }

      emit(state.copyWith(status: CreatePropertyStatus.loading));

      final data = {
        'name': name,
        'description': description,
        'address': address,
        'provinceId': state.selectedProvince!.id,
        'districtId': state.selectedDistrict!.id,
        'wardId': state.selectedWard!.id,
        'electricityPrice': electricityPrice,
        'waterPrice': waterPrice,
        'propertyType': propertyType,
        'imageUrls': imageUrls,
      };

      await _repository.createProperty(data);
      
      emit(state.copyWith(status: CreatePropertyStatus.success));
    } catch (e) {
      emit(state.copyWith(
        status: CreatePropertyStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }
}
