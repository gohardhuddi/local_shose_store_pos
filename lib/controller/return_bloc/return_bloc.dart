import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:local_shoes_store_pos/controller/return_bloc/return_state.dart';

import '../../repository/return_repository.dart';
import 'return_events.dart';

class ReturnBloc extends Bloc<ReturnEvent, ReturnState> {
  final ReturnRepository _repository;
  ReturnBloc(this._repository) : super(ReturnInitial()) {
    on<ProcessReturnEvent>(_onProcessReturn);
    on<GetAllReturnsEvent>(_onGetAllReturns);
  }

  Future<void> _onProcessReturn(
    ProcessReturnEvent event,
    Emitter<ReturnState> emit,
  ) async {
    emit(ReturnLoading());
    try {
      final id = await _repository.addReturn(
        saleId: event.saleId,
        items: event.items,
        totalRefund: event.totalRefund,
        reason: event.reason,
        createdBy: event.createdBy,
      );
      emit(ReturnSuccess(returnId: id));
    } catch (e) {
      emit(ReturnError(e.toString()));
    }
  }

  Future<void> _onGetAllReturns(
    GetAllReturnsEvent event,
    Emitter<ReturnState> emit,
  ) async {
    emit(ReturnLoading());
    try {
      //final returns = await _repository.getAllReturns();
      emit(ReturnListLoaded([]));
    } catch (e) {
      emit(ReturnError(e.toString()));
    }
  }
}
