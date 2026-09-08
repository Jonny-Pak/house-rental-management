import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import '../../data/repositories/user_repository.dart';
import 'profile_event.dart';
import 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final UserRepository _userRepository;

  ProfileBloc(this._userRepository) : super(ProfileInitial()) {
    on<FetchProfileEvent>(_onFetchProfile);
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
}
