import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../models/stock_model.dart';
import '../../repository/add_stock_repository.dart';
import 'add_stock_events.dart';
import 'add_stock_states.dart';

class AddStockBloc extends Bloc<AddStockEvents, AddStockStates> {
  final AddStockRepository _addStockRepo;

  AddStockBloc(this._addStockRepo) : super(AddStockInitialState()) {
    on<AddStockToDB>(_onAddStockToDB);
    on<EditStockVariant>(_onEditVariant);
    on<GetStockFromDB>(_onGetAllStock);
    on<GetUnSyncedStockFromDB>(_onGetAllUnsyncedStock);
    on<DeleteVariantByIdEvent>(_onDeleteVariantById);
    on<AddStockMovementEvent>(_onAddStockMovementToDB);
  }

  Future<void> _onAddStockToDB(
    AddStockToDB event,
    Emitter<AddStockStates> emit,
  ) async {
    emit(AddStockLoadingState());
    await _addStockRepo.addStockToDBRepo(
      brand: event.brand,
      articleCode: event.articleCode,
      articleName: event.articleName,
      size: event.size,
      color: event.color,
      productCodeSku: event.productCodeSku,
      quantity: event.quantity,
      purchasePrice: event.purchasePrice,
      suggestedSalePrice: event.suggestedSalePrice,
      isEdit: event.isEdit,
    );

    // Optionally reload list here if your UI expects fresh data:
    // await _reloadStock(emit);

    emit(AddStockSuccessState());
  }

  Future<void> _onEditVariant(
    EditStockVariant event,
    Emitter<AddStockStates> emit,
  ) async {
    emit(AddStockLoadingState());

    // Let DB layer handle movement logging based on quantity delta.
    final movementId = const Uuid().v4();
    await _addStockRepo.editVariantRepo(
      size: event.size,
      color: event.color,
      productCodeSku: event.productCodeSku,
      purchasePrice: event.purchasePrice,
      suggestedSalePrice: event.suggestedSalePrice,
      productID: event.productID,
      variantID: event.variantID,
      // If you want to set quantity exactly to event.quantity:
      newQuantity: event.quantity, // ← triggers movement if changed
      movementId: movementId, // ← idempotency
      dateTimeIso: DateTime.now().toIso8601String(),
      isSynced: false,
    );

    emit(AddStockSuccessState());
  }

  Future<void> _onGetAllStock(
    GetStockFromDB e,
    Emitter<AddStockStates> emit,
  ) async {
    emit(AddStockLoadingState());
    try {
      final json = await _addStockRepo.getAllStockRepo();
      final stockList = StockModel.listFromJsonString(json);
      emit(GetStockFromDBSuccessState(stockList: stockList, query: ''));
    } catch (e) {
      emit(AddStockErrorState());
    }
  }

  Future<void> _onGetAllUnsyncedStock(
    GetUnSyncedStockFromDB e,
    Emitter<AddStockStates> emit,
  ) async {
    emit(AddStockLoadingState());
    try {
      final unSynced = await _addStockRepo.getUnSyncPayloadRepo();
      final mappedList = await _addStockRepo.mapUnsyncedToBackend(unSynced);
      final result = await _addStockRepo.syncProductsToBackend(mappedList);
      emit(AddStockSuccessState());
    } catch (e) {
      emit(AddStockErrorState());
    }
  }

  Future<void> _onDeleteVariantById(
    DeleteVariantByIdEvent event,
    Emitter<AddStockStates> emit,
  ) async {
    emit(AddStockLoadingState());
    try {
      bool result = await _addStockRepo.deleteVariantById(event.variantID);
      if (result) emit(DeleteVariantByIdSuccessState());
    } catch (e) {
      emit(AddStockErrorState());
    }
  }

  /// record the movement of the stock
  Future<void> _onAddStockMovementToDB(
    AddStockMovementEvent event,
    Emitter<AddStockStates> emit,
  ) async {
    emit(AddStockLoadingState());
    await _addStockRepo.addInventoryMovementRepo(
      productCodeSku: event.productCodeSku,
      action: event.movementType.toString(),
      quantity: int.parse(event.quantity),
      movementId: const Uuid().v4(),
      dateTime: DateTime.now().toIso8601String(),
      isSynced: false,
    );
    emit(MovementsSuccessState());
  }
}
