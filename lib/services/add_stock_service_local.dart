import 'dart:convert';

import '../main.dart';

class StockServiceLocal {
  Future<String> addStockToDbService({
    required String brand,
    required String articleCode,
    required String? articleName,
    required String size,
    required String color,
    required String productCodeSku,
    required String quantity,
    required String purchasePrice,
    required String suggestedSalePrice,
  }) async {
    final productId = await stockDb.upsertProduct(
      brand: brand.trim(),
      articleCode: articleCode.toUpperCase(),
      articleName: articleName?.trim(),
    );

   await stockDb.upsertVariant(
      productId: productId,
      sizeEu: int.parse(size),
      colorName: color!,
      sku: productCodeSku.toUpperCase(),
      quantity: int.parse(quantity),
      purchasePrice: double.parse(purchasePrice),
      salePrice: double.parse(suggestedSalePrice),
    );
   return productId;
  }
  Future<dynamic> getAllStock() async {
   return await stockDb.getAllStock();
   ///it will return json and all other stuff like join etc and heavy logics are in db class
  }
}
