import 'package:equatable/equatable.dart';
import 'package:local_shoes_store_pos/helper/constants.dart';

import '../../models/stock_model.dart';

sealed class SalesStates extends Equatable {
  @override
  List<Object> get props => [];
}

class SalesInitialState extends SalesStates {}

class SalesLoadingState extends SalesStates {}

class VariantAddedToCartSuccessState extends SalesStates {
  final String success = CustomStrings.itemAddedToCartSuccessfully;
  final List<VariantModel> cartItems;
  VariantAddedToCartSuccessState({required this.cartItems});

  @override
  List<Object> get props => [success, cartItems];
}
