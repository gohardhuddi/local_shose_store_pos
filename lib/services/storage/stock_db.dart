abstract class StockDb {
  Future<void> init();

  /// returns productId
  Future<String> upsertProduct({
    required String brand,
    required String articleCode, // unique key (e.g., ADSH001)
    String? articleName,
  });

  /// returns variantId
  Future<String> upsertVariant({
    required String productId,
    required int sizeEu,
    required String colorName,
    String? colorHex,
    required String sku, // unique key (e.g., ADSH001-BLK-42)
    required int quantity,
    required double purchasePrice,
    double? salePrice,
  });

  ///fetch data all
  Future<List<Map<String, dynamic>>> getAllProducts();
  Future<List<Map<String, dynamic>>> getAllVariants();
}
