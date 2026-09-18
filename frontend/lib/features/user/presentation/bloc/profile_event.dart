import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

@immutable
abstract class ProfileEvent {}

class FetchProfileEvent extends ProfileEvent {}

class ChangeAvatarEvent extends ProfileEvent {
  final XFile file;

  ChangeAvatarEvent(this.file);
}
