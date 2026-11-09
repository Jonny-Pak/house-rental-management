import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/contract_model.dart';
import '../../data/repositories/contract_repository.dart';

// ─── States ─────────────────────────────────────────────────────────────────
abstract class ContractState {}

class ContractInitial extends ContractState {}

class ContractLoading extends ContractState {}

class ContractLoaded extends ContractState {
  final List<ContractModel> contracts;
  ContractLoaded(this.contracts);
}

class ContractError extends ContractState {
  final String message;
  ContractError(this.message);
}

class ContractCreating extends ContractState {}

class ContractCreated extends ContractState {
  final ContractModel contract;
  ContractCreated(this.contract);
}

// ─── Cubit ───────────────────────────────────────────────────────────────────
class ContractCubit extends Cubit<ContractState> {
  final ContractRepository _repository;

  ContractCubit(this._repository) : super(ContractInitial());

  Future<void> fetchMyContracts() async {
    emit(ContractLoading());
    try {
      final contracts = await _repository.getMyContracts();
      emit(ContractLoaded(contracts));
    } catch (e) {
      emit(ContractError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> createNewContract(CreateContractRequest request) async {
    emit(ContractCreating());
    try {
      final contract = await _repository.createContract(request);
      emit(ContractCreated(contract));
      // Refresh the list after creation
      await fetchMyContracts();
    } catch (e) {
      emit(ContractError(e.toString().replaceAll('Exception: ', '')));
    }
  }
}
