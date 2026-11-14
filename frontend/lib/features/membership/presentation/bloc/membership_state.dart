import 'package:equatable/equatable.dart';
import '../../data/models/membership_package_model.dart';
import '../../data/models/subscription_benefits.dart';

abstract class MembershipState extends Equatable {
  const MembershipState();

  @override
  List<Object?> get props => [];
}

class MembershipInitial extends MembershipState {}

class MembershipLoading extends MembershipState {}

class MembershipLoaded extends MembershipState {
  final List<MembershipPackage> packages;
  final SubscriptionBenefits? currentBenefits;

  const MembershipLoaded(this.packages, {this.currentBenefits});

  @override
  List<Object?> get props => [packages, currentBenefits];
}

class MembershipError extends MembershipState {
  final String message;

  const MembershipError(this.message);

  @override
  List<Object?> get props => [message];
}
