import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/admin_listing_repository.dart';
import 'admin_listing_state.dart';

class AdminListingCubit extends Cubit<AdminListingState> {
  final AdminListingRepository repository;

  AdminListingCubit(this.repository) : super(AdminListingInitial());

  Future<void> fetchPendingListings() async {
    emit(AdminListingLoading());
    try {
      final listings = await repository.getPendingListings();
      emit(AdminListingLoaded(listings));
    } catch (e) {
      emit(AdminListingError(e.toString()));
    }
  }

  Future<void> approveListing(int id) async {
    final currentState = state;
    try {
      emit(AdminListingLoading());
      await repository.approveListing(id);
      emit(const AdminListingActionSuccess('Phê duyệt bài đăng thành công!'));
      fetchPendingListings();
    } catch (e) {
      emit(AdminListingError(e.toString()));
      if (currentState is AdminListingLoaded) {
        emit(currentState);
      } else {
        fetchPendingListings();
      }
    }
  }

  Future<void> rejectListing(int id, String reason) async {
    final currentState = state;
    try {
      emit(AdminListingLoading());
      await repository.rejectListing(id, reason);
      emit(const AdminListingActionSuccess('Đã từ chối bài đăng!'));
      fetchPendingListings();
    } catch (e) {
      emit(AdminListingError(e.toString()));
      if (currentState is AdminListingLoaded) {
        emit(currentState);
      } else {
        fetchPendingListings();
      }
    }
  }
}

