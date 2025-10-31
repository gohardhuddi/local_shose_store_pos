import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:local_shoes_store_pos/repository/sales_repository.dart';

import '../../models/cart_model.dart';
import '../../models/dto/get_all_sales_with_lines_model.dart';
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
    on<GetSalesByDateRangeEvent>(_onGetSalesByDateRange);
    on<GetCartItemsEvent>(_onGetCartItems);
    on<SearchSalesEvent>(_onSearchSales); // 👈 ADD THIS
    on<ClearSalesSearchEvent>(_onClearSalesSearchEvent);
  }

  List<CartItemModel> cartItems = [];
  List<SaleWithLines> _allSales = [];

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
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    add(GetSalesSummaryEvent(startDate: today, endDate: today));
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
      print(sales);
      _allSales = sales; // store master copy
      emit(GetAllSalesSuccessState(sales));
    } catch (e) {
      emit(SalesErrorState(e.toString()));
    }
  }

  Future<void> _onGetSalesByDateRange(
    GetSalesByDateRangeEvent event,
    Emitter<SalesStates> emit,
  ) async {
    try {
      emit(SalesLoadingState());
      final sales = await _salesRepository.getSalesByDateRange(
        startDate: event.startDate,
        endDate: event.endDate,
      );
      _allSales = sales; // also store master copy for search
      emit(GetAllSalesSuccessState(sales));
    } catch (e) {
      emit(SalesErrorState(e.toString()));
    }
  }

  void _onSearchSales(SearchSalesEvent event, Emitter<SalesStates> emit) async {
    final query = event.query.trim().toLowerCase();

    // If no cached data, fetch first
    if (_allSales.isEmpty) {
      final sales = await _salesRepository.getAllSalesWithLines();
      _allSales = sales;
    }

    if (query.isEmpty) {
      emit(GetAllSalesSuccessState(_allSales));
      return;
    }

    final filtered = _allSales.where((saleWithLines) {
      final sale = saleWithLines.sale;
      final dateStr = sale.dateTime;

      // Try parsing the date
      DateTime? saleDate;
      try {
        saleDate = DateTime.parse(dateStr);
      } catch (_) {
        saleDate = null;
      }

      // Multiple date formats for matching
      final formattedDates = [
        if (saleDate != null) DateFormat('dd-MM-yyyy').format(saleDate),
        if (saleDate != null) DateFormat('dd/MM/yyyy').format(saleDate),
        if (saleDate != null) DateFormat('dd MMM yyyy').format(saleDate),
        if (saleDate != null) DateFormat('yyyy-MM-dd').format(saleDate),
      ];

      // 🔍 Sale ID match (new)
      final saleIdMatch =
          sale.saleId.toLowerCase().contains(query) ||
          sale.saleId.replaceAll('-', '').toLowerCase().contains(query);

      // 💰 Amount match
      final amountMatch =
          sale.totalAmount.toString().toLowerCase().contains(query) ||
          sale.finalAmount.toString().toLowerCase().contains(query);

      // 🗓️ Date match
      final dateMatch = formattedDates.any(
        (d) => d.toLowerCase().contains(query),
      );

      // 📦 SKU / product match
      final skuMatch = saleWithLines.lines.any(
        (line) => line.sku.toLowerCase().contains(query),
      );

      return saleIdMatch || dateMatch || amountMatch || skuMatch;
    }).toList();

    emit(GetAllSalesSuccessState(filtered));
  }

  // 🔍 NEW SEARCH HANDLER
  // void _onSearchSales(SearchSalesEvent event, Emitter<SalesStates> emit) {
  //   final query = event.query.trim().toLowerCase();
  //
  //   // If query empty → return full list
  //   if (query.isEmpty) {
  //     emit(GetAllSalesSuccessState(_allSales));
  //     return;
  //   }
  //
  //   final filtered = _allSales.where((saleWithLines) {
  //     final sale = saleWithLines.sale;
  //     final dateStr = sale.dateTime; // e.g., "2025-01-28"
  //
  //     // --- ✅ DATE FILTERING ---
  //     // Parse and format date in multiple formats
  //     DateTime? saleDate;
  //     try {
  //       saleDate = DateTime.parse(dateStr);
  //     } catch (_) {
  //       saleDate = null;
  //     }
  //
  //     String formattedDate1 = saleDate != null
  //         ? DateFormat('dd-MM-yyyy').format(saleDate)
  //         : '';
  //     String formattedDate2 = saleDate != null
  //         ? DateFormat('dd/MM/yyyy').format(saleDate)
  //         : '';
  //     String formattedDate3 = saleDate != null
  //         ? DateFormat('dd MMM yyyy').format(saleDate)
  //         : '';
  //     String formattedDate4 = saleDate != null
  //         ? DateFormat('yyyy-MM-dd').format(saleDate)
  //         : '';
  //
  //     final dateMatch =
  //         formattedDate1.toLowerCase().contains(query) ||
  //         formattedDate2.toLowerCase().contains(query) ||
  //         formattedDate3.toLowerCase().contains(query) ||
  //         formattedDate4.toLowerCase().contains(query) ||
  //         saleDate?.month.toString().padLeft(2, '0').contains(query) == true ||
  //         saleDate?.year.toString().contains(query) == true ||
  //         DateFormat(
  //           'MMM',
  //         ).format(saleDate ?? DateTime(2000)).toLowerCase().contains(query);
  //
  //     // --- 💰 AMOUNT MATCH (partial number or text) ---
  //     final amountMatch = sale.totalAmount.toString().toLowerCase().contains(
  //       query,
  //     );
  //
  //     // --- 📦 SKU MATCH (any line item) ---
  //     final skuMatch = saleWithLines.lines.any(
  //       (line) => line.sku.toLowerCase().contains(query),
  //     );
  //
  //     return dateMatch || amountMatch || skuMatch;
  //   }).toList();
  //
  //   emit(GetAllSalesSuccessState(filtered));
  // }

  FutureOr<void> _onGetCartItems(
    GetCartItemsEvent event,
    Emitter<SalesStates> emit,
  ) {
    emit(VariantAddedToCartSuccessState(cartItems: cartItems));
  }

  Future<void> _onClearSalesSearchEvent(
    ClearSalesSearchEvent event,
    Emitter<SalesStates> emit,
  ) async {
    // Clear search results (return empty state for UI)
    emit(GetAllSalesSuccessState([]));
  }
}
