import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:local_shoes_store_pos/repository/sales_repository.dart';

import '../../models/cart_model.dart';
import 'sales_events.dart';
import 'sales_states.dart';

class SalesBloc extends Bloc<SalesEvents, SalesStates> {
  final SalesRepository _salesRepository;

  SalesBloc(this._salesRepository) : super(SalesInitialState()) {
    on<AddVariantToCart>(_onAddVariantToCart);
    on<RemoveVariantFromCart>(_onRemoveVariantFromCart);
    on<SoldEvent>(_onSoldEvent);
    on<GetSalesSummaryEvent>(_onGetSalesSummaryEvent);
    on<GetAllSalesEvent>(_onGetAllSalesEvents);
  }

  List<CartItemModel> cartItems = [];

  Future<void> _onAddVariantToCart(
    AddVariantToCart event,
    Emitter<SalesStates> emit,
  ) async {
    emit(SalesLoadingState());
    if (event.cartItem.variant.qty > 0) {
      cartItems.add(event.cartItem);
      emit(VariantAddedToCartSuccessState(cartItems: cartItems));
    } else {
      emit(VariantAddToCartFailedState('This variant is out of stock.'));
      return;
    }
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

  Future<void> _onGetSalesSummaryEvent(
    GetSalesSummaryEvent event,
    Emitter<SalesStates> emit,
  ) async {
    emit(SalesLoadingState());
    try {
      final summary = await _salesRepository.getSalesSummary(
        startDate: event.startDate,
        endDate: event.endDate,
      );
      emit(SalesSummaryLoadedState(summary));
    } catch (e) {
      emit(SalesErrorState('Failed to load sales summary: $e'));
    }
  }

  Future<void> _onGetAllSalesEvents(
    GetAllSalesEvent event,
    Emitter<SalesStates> emit,
  ) async {
    try {
      emit(SalesLoadingState());
      final sales = await _salesRepository.getAllSalesWithLines();
      emit(GetAllSalesSuccessState(sales));
    } catch (e) {
      emit(SalesErrorState(e.toString()));
    }
  }
}
