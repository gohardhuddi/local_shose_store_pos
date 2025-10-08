import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:local_shoes_store_pos/repository/sales_repository.dart';

import '../../models/stock_model.dart';
import 'sales_events.dart';
import 'sales_states.dart';

class SalesBloc extends Bloc<SalesEvents, SalesStates> {
  final SalesRepository _salesRepository;

  SalesBloc(this._salesRepository) : super(SalesInitialState()) {
    on<AddVariantToCart>(_onAddVariantToCart);
    on<RemoveVariantFromCart>(_onRemoveVariantFromCart);
    on<SoldEvent>(_onSoldEvent);
  }

  List<VariantModel> cartItems = [];
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

  Future<void> _onSoldEvent(SoldEvent event, Emitter<SalesStates> emit) async {
    emit(SalesLoadingState());
    await _salesRepository.addSalesToDB(
      cartItems: event.cartItems,
      totalAmount: event.totalAmount,
      paymentType: event.paymentType,
      amountPaid: event.amountPaid,
      changeReturned: event.changeReturned,
      createdBy: event.createdBy,
      isSynced: event.isSynced,
    );
  }
}
