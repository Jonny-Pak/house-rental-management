import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/membership_repository.dart';
import 'membership_state.dart';

class MembershipCubit extends Cubit<MembershipState> {
  final MembershipRepository repository;

  MembershipCubit({required this.repository}) : super(MembershipInitial());

  Future<void> fetchPackages() async {
    emit(MembershipLoading());
    try {
      final packages = await repository.getPackages();
      emit(MembershipLoaded(packages));
    } catch (e) {
      emit(MembershipError(e.toString()));
    }
  }
}