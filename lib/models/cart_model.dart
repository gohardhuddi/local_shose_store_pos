import 'package:local_shoes_store_pos/models/stock_model.dart';

class CartItemModel {
  final VariantModel variant;
  int cartQty;

  CartItemModel({required this.variant, this.cartQty = 1});

  double get lineTotal => cartQty * variant.salePrice;

  Map<String, dynamic> toJson() => {
    ...variant.toJson(),
    'cartQty': cartQty,
    'lineTotal': lineTotal,
  };
}
