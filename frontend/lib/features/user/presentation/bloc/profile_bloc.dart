import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/repositories/user_repository.dart';
import 'profile_event.dart';
import 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final UserRepository _userRepository;
  final ImagePicker _imagePicker = ImagePicker();

  ProfileBloc(this._userRepository) : super(ProfileInitial()) {
    on<FetchProfileEvent>(_onFetchProfile);
    on<ChangeAvatarEvent>(_onChangeAvatar);
  }

  Future<void> _onFetchProfile(
      FetchProfileEvent event, Emitter<ProfileState> emit) async {
    emit(ProfileLoading());
    try {
      final profile = await _userRepository.getProfile();
      emit(ProfileLoaded(profile));
    } on DioException catch (e) {
      final errorMsg =
          e.response?.data['message'] ?? e.message ?? 'Unknown error occurred';
      emit(ProfileError(errorMsg));
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }

  Future<void> _onChangeAvatar(
      ChangeAvatarEvent event, Emitter<ProfileState> emit) async {
    if (state is! ProfileLoaded) return;
    
    final currentState = state as ProfileLoaded;
    
    try {
      final pickedFile = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (pickedFile == null) return;
      
      emit(ProfileAvatarUploading(currentState.profile));
      
      final uploadedUrl = await _userRepository.uploadImage(pickedFile);
      final updatedProfile = await _userRepository.updateAvatar(uploadedUrl);
      
      emit(ProfileLoaded(updatedProfile));
    } on DioException catch (e) {
      final errorMsg = e.response?.data['message'] ?? e.message ?? 'Unknown error occurred';
      emit(ProfileAvatarUploadError(currentState.profile, errorMsg));
      emit(currentState);
    } catch (e) {
      emit(ProfileAvatarUploadError(currentState.profile, e.toString()));
      emit(currentState);
    }
  }
}
