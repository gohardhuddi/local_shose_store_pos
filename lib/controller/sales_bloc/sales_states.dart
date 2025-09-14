import 'package:equatable/equatable.dart';
import 'package:local_shoes_store_pos/helper/constants.dart';

sealed class SalesStates extends Equatable {
  @override
  List<Object> get props => [];
}

class SalesInitialState extends SalesStates {}

class SalesLoadingState extends SalesStates {}

class VariantAddedToCartSuccessState extends SalesStates {
  final String success = CustomStrings.itemAddedToCartSuccessfully;

  @override
  List<Object> get props => [success];
}
