import 'package:equatable/equatable.dart';
import 'package:image_picker/image_picker.dart';
import '../../../preferences/data/models/area_models.dart';

enum CreatePropertyStatus { initial, loading, uploadingImages, success, error }

class CreatePropertyState extends Equatable {
  final CreatePropertyStatus status;
  final String? errorMessage;
  
  final List<Province> provinces;
  final List<District> districts;
  final List<Ward> wards;
  
  final Province? selectedProvince;
  final District? selectedDistrict;
  final Ward? selectedWard;
  
  final List<XFile> images;

  const CreatePropertyState({
    this.status = CreatePropertyStatus.initial,
    this.errorMessage,
    this.provinces = const [],
    this.districts = const [],
    this.wards = const [],
    this.selectedProvince,
    this.selectedDistrict,
    this.selectedWard,
    this.images = const [],
  });

  CreatePropertyState copyWith({
    CreatePropertyStatus? status,
    String? errorMessage,
    List<Province>? provinces,
    List<District>? districts,
    List<Ward>? wards,
    Province? selectedProvince,
    District? selectedDistrict,
    Ward? selectedWard,
    List<XFile>? images,
    bool clearSelectedDistrict = false,
    bool clearSelectedWard = false,
  }) {
    return CreatePropertyState(
      status: status ?? this.status,
      errorMessage: errorMessage,
      provinces: provinces ?? this.provinces,
      districts: districts ?? this.districts,
      wards: wards ?? this.wards,
      selectedProvince: selectedProvince ?? this.selectedProvince,
      selectedDistrict: clearSelectedDistrict ? null : (selectedDistrict ?? this.selectedDistrict),
      selectedWard: clearSelectedWard ? null : (selectedWard ?? this.selectedWard),
      images: images ?? this.images,
    );
  }

  @override
  List<Object?> get props => [
        status,
        errorMessage,
        provinces,
        districts,
        wards,
        selectedProvince,
        selectedDistrict,
        selectedWard,
        images,
      ];
}
