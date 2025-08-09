import 'package:equatable/equatable.dart';

sealed class AddStockStates extends Equatable {
  @override
  List<Object> get props => [];
}

class AddStockInitialState extends AddStockStates {}

class AddStockLoadingState extends AddStockStates {}

class AddStockSuccessState extends AddStockStates {
  final String successMessage = "Stock Added Successfully";

  @override
  List<Object> get props => [successMessage];
}

class AddStockErrorState extends AddStockStates {
  final String error = "Something went wrong! Try Again";

  @override
  List<Object> get props => [error];
}
