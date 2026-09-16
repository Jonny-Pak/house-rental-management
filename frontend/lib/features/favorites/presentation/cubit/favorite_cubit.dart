import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/favorite_repository.dart';
import 'favorite_state.dart';

class FavoriteCubit extends Cubit<FavoriteState> {
  final FavoriteRepository _repository;

  FavoriteCubit(this._repository) : super(const FavoriteState());

  Future<void> fetchFavorites() async {
    emit(state.copyWith(status: FavoriteStatus.loading));
    try {
      final properties = await _repository.getFavoriteProperties();
      emit(state.copyWith(
        status: FavoriteStatus.success,
        properties: properties,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: FavoriteStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }
}

