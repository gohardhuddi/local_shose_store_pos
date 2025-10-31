import 'package:equatable/equatable.dart';

import '../../models/cart_model.dart';

enum StockMovementType { purchaseIn, saleOut, returnStock, transfer }

sealed class SalesEvents extends Equatable {
  @override
  List<Object> get props => [];
}

class GetUnSyncedStockFromDB extends SalesEvents {
  GetUnSyncedStockFromDB();

  @override
  List<Object> get props => [];
}

class DeleteVariantByIdEvent extends SalesEvents {
  final String variantID;

  DeleteVariantByIdEvent({required this.variantID});

  @override
  List<Object> get props => [variantID];
}

class EditStockVariant extends SalesEvents {
  final String size;
  final String color;
  final String productCodeSku;
  final String quantity;
  final String purchasePrice;
  final String suggestedSalePrice;
  final String productID;
  final String variantID;

  EditStockVariant({
    required this.color,
    required this.productCodeSku,
    required this.purchasePrice,
    required this.quantity,
    required this.size,
    required this.suggestedSalePrice,
    required this.productID,
    required this.variantID,
  });

  @override
  List<Object> get props => [
    color,
    productCodeSku,
    purchasePrice,
    suggestedSalePrice,
    size,
  ];
}

class AddStockMovementEvent extends SalesEvents {
  final String productCodeSku;
  final StockMovementType movementType;
  final String quantity;

  AddStockMovementEvent({
    required this.productCodeSku,
    required this.movementType,
    required this.quantity,
  });

  @override
  List<Object> get props => [productCodeSku, movementType, quantity];
}

class AddVariantToCart extends SalesEvents {
  final CartItemModel cartItem;

  AddVariantToCart({required this.cartItem});

  @override
  List<Object> get props => [cartItem];
}

class RemoveVariantFromCart extends SalesEvents {
  final CartItemModel variant;

  RemoveVariantFromCart({required this.variant});

  @override
  List<Object> get props => [variant];
}

class SoldEvent extends SalesEvents {
  final List<CartItemModel> cartItems;
  final String totalAmount;
  final String paymentType;
  final String amountPaid;
  final String changeReturned;
  final String createdBy;
  final bool isSynced;

  SoldEvent({
    required this.cartItems,
    required this.totalAmount,
    required this.amountPaid,
    required this.changeReturned,
    required this.paymentType,
    required this.createdBy,
    required this.isSynced,
  });

  @override
  List<Object> get props => [
    cartItems,
    totalAmount,
    amountPaid,
    changeReturned,
    paymentType,
    createdBy,
    isSynced,
  ];
}

class GetSalesSummaryEvent extends SalesEvents {
  final String startDate;
  final String endDate;

  GetSalesSummaryEvent({required this.startDate, required this.endDate});
}

class GetAllSalesEvent extends SalesEvents {}

class GetSalesByDateRangeEvent extends SalesEvents {
  final String startDate;
  final String endDate;

  GetSalesByDateRangeEvent({required this.startDate, required this.endDate});
}

class GetCartItemsEvent extends SalesEvents {}

class SearchSalesEvent extends SalesEvents {
  final String query;

  SearchSalesEvent(this.query);

  @override
  List<Object> get props => [query];
}

class ClearSalesSearchEvent extends SalesEvents {}
