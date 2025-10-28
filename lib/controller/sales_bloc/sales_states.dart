import 'package:equatable/equatable.dart';
import 'package:local_shoes_store_pos/helper/constants.dart';

import '../../models/cart_model.dart';
import '../../models/dto/get_all_sales_with_lines_model.dart';
import '../../models/dto/sales_summery_query.dart';

sealed class SalesStates extends Equatable {
  @override
  List<Object> get props => [];
}

class SalesInitialState extends SalesStates {}

class SalesLoadingState extends SalesStates {}

class VariantAddedToCartSuccessState extends SalesStates {
  final String success = CustomStrings.itemAddedToCartSuccessfully;
  final List<CartItemModel> cartItems;
  VariantAddedToCartSuccessState({required this.cartItems});

  @override
  List<Object> get props => [success, cartItems];
}

class VariantAddToCartFailedState extends SalesStates {
  final String error;
  VariantAddToCartFailedState(this.error);
}

class SalesSummaryLoadedState extends SalesStates {
  final SalesSummaryQuery? summary;

  SalesSummaryLoadedState(this.summary);
}

class SalesErrorState extends SalesStates {
  final String error;
  SalesErrorState(this.error);
}

class GetAllSalesSuccessState extends SalesStates {
  final List<SaleWithLines> sales;
  GetAllSalesSuccessState(this.sales);

  @override
  List<Object> get props => [sales]; // 👈 ADD THIS
}
