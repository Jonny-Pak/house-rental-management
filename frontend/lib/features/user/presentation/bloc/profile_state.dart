import 'package:flutter/foundation.dart';
import '../../data/models/user_profile.dart';

@immutable
abstract class ProfileState {}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileLoaded extends ProfileState {
  final UserProfile profile;

  ProfileLoaded(this.profile);
}

class ProfileAvatarUploading extends ProfileLoaded {
  ProfileAvatarUploading(super.profile);
}

class ProfileError extends ProfileState {
  final String message;

  ProfileError(this.message);
}

class ProfileAvatarUploadError extends ProfileLoaded {
  final String message;

  ProfileAvatarUploadError(super.profile, this.message);
}
