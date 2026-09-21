import 'package:equatable/equatable.dart';
import '../../data/models/membership_package_model.dart';

abstract class MembershipState extends Equatable {
  const MembershipState();

  @override
  List<Object?> get props => [];
}

class MembershipInitial extends MembershipState {}

class MembershipLoading extends MembershipState {}

class MembershipLoaded extends MembershipState {
  final List<MembershipPackage> packages;

  const MembershipLoaded(this.packages);

  @override
  List<Object?> get props => [packages];
}

class MembershipError extends MembershipState {
  final String message;

  const MembershipError(this.message);

  @override
  List<Object?> get props => [message];
}