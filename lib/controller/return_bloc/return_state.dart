import 'package:equatable/equatable.dart';

abstract class ReturnState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ReturnInitial extends ReturnState {}

class ReturnLoading extends ReturnState {}

class ReturnSuccess extends ReturnState {
  final String returnId;
  ReturnSuccess({required this.returnId});
}

class ReturnListLoaded extends ReturnState {
  final List<Map<String, Object?>> returns;
  ReturnListLoaded(this.returns);
}

class ReturnError extends ReturnState {
  final String message;
  ReturnError(this.message);
}
