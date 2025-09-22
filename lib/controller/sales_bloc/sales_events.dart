import 'package:equatable/equatable.dart';
import 'package:local_shoes_store_pos/models/stock_model.dart';

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
  final VariantModel variant;

  AddVariantToCart({required this.variant});

  @override
  List<Object> get props => [variant];
}

class RemoveVariantFromCart extends SalesEvents {
  final VariantModel variant;

  RemoveVariantFromCart({required this.variant});

  @override
  List<Object> get props => [variant];
}

class SoldEvent extends SalesEvents {
  final List<VariantModel> cartItems;
  SoldEvent({required this.cartItems});
  @override
  List<Object> get props => [cartItems];
}
