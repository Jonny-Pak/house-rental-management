import 'package:equatable/equatable.dart';
import '../../data/models/admin_listing_model.dart';

abstract class AdminListingState extends Equatable {
  const AdminListingState();

  @override
  List<Object?> get props => [];
}

class AdminListingInitial extends AdminListingState {}

class AdminListingLoading extends AdminListingState {}

class AdminListingLoaded extends AdminListingState {
  final List<AdminListingModel> pendingListings;

  const AdminListingLoaded(this.pendingListings);

  @override
  List<Object?> get props => [pendingListings];
}

class AdminListingError extends AdminListingState {
  final String message;

  const AdminListingError(this.message);

  @override
  List<Object?> get props => [message];
}

class AdminListingActionSuccess extends AdminListingState {
  final String message;

  const AdminListingActionSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

