import 'package:equatable/equatable.dart';

import '../../models/cart_model.dart';

abstract class ReturnEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class ProcessReturnEvent extends ReturnEvent {
  final String saleId;
  final List<CartItemModel> items;
  final double totalRefund;
  final String? reason;
  final String? createdBy;

  ProcessReturnEvent({
    required this.saleId,
    required this.items,
    required this.totalRefund,
    this.reason,
    this.createdBy,
  });

  @override
  List<Object?> get props => [saleId, items, totalRefund, reason, createdBy];
}

class GetAllReturnsEvent extends ReturnEvent {}
