import 'package:flutter/foundation.dart';

@immutable
abstract class ProfileEvent {}

class FetchProfileEvent extends ProfileEvent {}

class ChangeAvatarEvent extends ProfileEvent {}
