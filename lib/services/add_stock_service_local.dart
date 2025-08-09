import '../main.dart';

class StockServiceLocal {
  Future<void> addStockToDbService({
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

    var result = await stockDb.upsertVariant(
      productId: productId,
      sizeEu: int.parse(size),
      colorName: color!,
      sku: productCodeSku.toUpperCase(),
      quantity: int.parse(quantity),
      purchasePrice: double.parse(purchasePrice),
      salePrice: double.parse(suggestedSalePrice),
    );
    print(result);
    final allProducts = await stockDb.getAllProducts();
    print("Products: $allProducts");

    final allVariants = await stockDb.getAllVariants();
    print("Variants: $allVariants");
  }
}
