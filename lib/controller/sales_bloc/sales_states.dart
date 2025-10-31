import 'package:equatable/equatable.dart';
import 'package:local_shoes_store_pos/helper/constants.dart';

import '../../models/cart_model.dart';
import '../../models/dto/get_all_sales_with_lines_model.dart';
import '../../models/dto/sales_summery_query.dart';

/// 🔹 Base class for all Sales states
sealed class SalesStates extends Equatable {
  @override
  List<Object> get props => [];
}

/// 🌀 Initial / Idle state
class SalesInitialState extends SalesStates {}

/// ⏳ Loading (for long-running ops)
class SalesLoadingState extends SalesStates {}

/// 🛒 Item successfully added to cart
class VariantAddedToCartSuccessState extends SalesStates {
  final String success = CustomStrings.itemAddedToCartSuccessfully;
  final List<CartItemModel> cartItems;

  VariantAddedToCartSuccessState({required this.cartItems});

  @override
  List<Object> get props => [success, cartItems];
}

/// ❌ Failed to add variant to cart
class VariantAddToCartFailedState extends SalesStates {
  final String error;
  VariantAddToCartFailedState(this.error);
}

/// 📊 Sales summary loaded
class SalesSummaryLoadedState extends SalesStates {
  final SalesSummaryQuery? summary;
  SalesSummaryLoadedState(this.summary);
}

/// ⚠️ Generic error
class SalesErrorState extends SalesStates {
  final String error;
  SalesErrorState(this.error);
}

/// 📋 All sales (or filtered sales) successfully fetched
class GetAllSalesSuccessState extends SalesStates {
  final List<SaleWithLines> sales;
  GetAllSalesSuccessState(this.sales);

  @override
  List<Object> get props => [sales];
}

/// 🔎 Search results successfully returned
class SearchSalesSuccessState extends SalesStates {
  final List<SaleWithLines> sales;
  SearchSalesSuccessState(this.sales);

  @override
  List<Object> get props => [sales];
}

/// 🧹 Search cleared (empty results)
class ClearSalesState extends SalesStates {}
