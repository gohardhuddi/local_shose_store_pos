import 'package:equatable/equatable.dart';

enum StockMovementType { purchaseIn, saleOut, returnStock, transfer }

sealed class AddStockEvents extends Equatable {
  @override
  List<Object> get props => [];
}

class AddStockToDB extends AddStockEvents {
  final String brand;
  final String articleCode;
  final String? articleName;
  final String size;
  final String color;
  final String productCodeSku;
  final String quantity;
  final String purchasePrice;
  final String suggestedSalePrice;
  final bool isEdit;
  final String category;
  final String gender;

  AddStockToDB({
    required this.category,
    required this.gender,
    required this.articleCode,
    required this.articleName,
    required this.brand,
    required this.color,
    required this.productCodeSku,
    required this.purchasePrice,
    required this.quantity,
    required this.size,
    required this.suggestedSalePrice,
    required this.isEdit,
  });

  @override
  List<Object> get props => [
    brand,
    articleCode,
    articleName ?? '',
    color,
    productCodeSku,
    purchasePrice,
    suggestedSalePrice,
    size,
    category,
    gender,
  ];
}

class GetStockFromDB extends AddStockEvents {}

class GetUnSyncedStockFromDB extends AddStockEvents {
  GetUnSyncedStockFromDB();

  @override
  List<Object> get props => [];
}

class DeleteVariantByIdEvent extends AddStockEvents {
  final String variantID;

  DeleteVariantByIdEvent({required this.variantID});

  @override
  List<Object> get props => [variantID];
}

class EditStockVariant extends AddStockEvents {
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

class AddStockMovementEvent extends AddStockEvents {
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

class GetCategoriesEvent extends AddStockEvents {}

class GetGendersEvent extends AddStockEvents {}
