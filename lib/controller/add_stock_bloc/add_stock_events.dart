import 'package:equatable/equatable.dart';

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

  AddStockToDB({
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
  ];
}

class GetStockFromDB extends AddStockEvents {
  GetStockFromDB();

  @override
  List<Object> get props => [];
}

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
