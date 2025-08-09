import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:local_shoes_store_pos/controller/add_stock_bloc/add_stock_events.dart';
import 'package:local_shoes_store_pos/controller/add_stock_bloc/add_stock_states.dart';
import 'package:local_shoes_store_pos/repository/add_stock_repository.dart';

class AddStockBloc extends Bloc<AddStockEvents, AddStockStates> {
  final AddStockRepository _addStockRepository;
  AddStockBloc(this._addStockRepository) : super(AddStockInitialState()) {
    on<AddStockToDB>(_onAddStockToDB);
  }

  Future<void> _onAddStockToDB(
    AddStockToDB event,
    Emitter<AddStockStates> emit,
  ) async {
    emit(AddStockLoadingState());
    await _addStockRepository.addStockToDBRepo(
      brand: event.brand,
      articleCode: event.articleCode,
      articleName: event.articleName,
      size: event.size,
      color: event.color,
      productCodeSku: event.productCodeSku,
      quantity: event.quantity,
      purchasePrice: event.purchasePrice,
      suggestedSalePrice: event.suggestedSalePrice,
    );
  }
}
