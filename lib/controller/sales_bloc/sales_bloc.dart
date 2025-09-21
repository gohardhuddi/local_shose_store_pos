import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../models/stock_model.dart';
import '../../repository/add_stock_repository.dart';
import 'sales_events.dart';
import 'sales_states.dart';

class SalesBloc extends Bloc<SalesEvents, SalesStates> {
  final AddStockRepository _addStockRepo;

  SalesBloc(this._addStockRepo) : super(SalesInitialState()) {
    on<GetUnSyncedStockFromDB>(_onGetAllUnsyncedStock);
    on<DeleteVariantByIdEvent>(_onDeleteVariantById);
    on<AddStockMovementEvent>(_onAddStockMovementToDB);
    on<AddVariantToCart>(_onAddVariantToCart);
    on<RemoveVariantFromCart>(_onRemoveVariantFromCart);
  }
  List<VariantModel> cartItems = [];

  Future<void> _onGetAllUnsyncedStock(
    GetUnSyncedStockFromDB e,
    Emitter<SalesStates> emit,
  ) async {
    emit(SalesLoadingState());
    try {
      final unSynced = await _addStockRepo.getUnSyncPayloadRepo();
      final mappedList = await _addStockRepo.mapUnsyncedToBackend(unSynced);
      final result = await _addStockRepo.syncProductsToBackend(mappedList);
      // emit(AddStockSuccessState());
    } catch (e) {
      //emit(AddStockErrorState());
    }
  }

  Future<void> _onDeleteVariantById(
    DeleteVariantByIdEvent event,
    Emitter<SalesStates> emit,
  ) async {
    emit(SalesLoadingState());
    try {
      await _addStockRepo.deleteVariantById(event.variantID);
      //   emit(DeleteVariantByIdSuccessState());
    } catch (e) {
      // emit(AddStockErrorState());
    }
  }

  /// record the movement of the stock
  Future<void> _onAddStockMovementToDB(
    AddStockMovementEvent event,
    Emitter<SalesStates> emit,
  ) async {
    emit(SalesLoadingState());
    await _addStockRepo.addInventoryMovementRepo(
      productCodeSku: event.productCodeSku,
      action: event.movementType.toString(),
      quantity: int.parse(event.quantity),
      movementId: const Uuid().v4(),
      dateTime: DateTime.now().toIso8601String(),
      isSynced: false,
    );
    //  emit(VariantAddedToCartSuccessState());
  }

  Future<void> _onAddVariantToCart(
    AddVariantToCart event,
    Emitter<SalesStates> emit,
  ) async {
    emit(SalesLoadingState());
    cartItems.add(event.variant);
    emit(VariantAddedToCartSuccessState(cartItems: cartItems));
  }

  Future<void> _onRemoveVariantFromCart(
    RemoveVariantFromCart event,
    Emitter<SalesStates> emit,
  ) async {
    emit(SalesLoadingState());
    cartItems.remove(event.variant);
    emit(VariantAddedToCartSuccessState(cartItems: cartItems));
  }
}
