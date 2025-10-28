import '../../models/cart_model.dart';

abstract class StockDb {
  Future<void> init();

  // -------------------------
  // Products
  // -------------------------
  /// Returns productId (stringified)
  Future<String> upsertProduct({
    required String brand,
    required String articleCode, // unique key (e.g., ADSH001)
    String? articleName,
  });

  // -------------------------
  // Variants
  // -------------------------
  /// Returns variantId (stringified)
  /// If variantID is provided, update that variant.
  /// Otherwise, upsert by SKU.
  /// If isEdit == true, quantity is set exactly; else quantity is added to current.
  Future<String> upsertVariant({
    required String productId,
    String? variantID,
    required int sizeEu,
    required String colorName,
    String? colorHex,
    required String sku, // unique key (e.g., ADSH001-BLK-42)
    required int quantity,
    required double purchasePrice,
    double? salePrice,
    bool? isEdit,
  });

  // -------------------------
  // Movements (core primitive)
  // -------------------------
  /// Apply a stock movement to a variant. Must be idempotent by movementId.
  Future<String> addInventoryMovement({
    required String movementId,
    required String productVariantId, // variant id, not SKU (stringified)
    required int quantity, // > 0
    required String action, // 'add' or 'subtract'
    required String dateTime, // ISO-8601
    bool isSynced = false,
  });

  // -------------------------
  // Movement helpers (recommended)
  // -------------------------
  /// Convenience wrappers for add/subtract movements.
  Future<String> addStock({
    required String movementId,
    required String productVariantId,
    required int quantity,
    String? dateTimeIso,
    bool isSynced = false,
  });

  Future<String> subtractStock({
    required String movementId,
    required String productVariantId,
    required int quantity,
    String? dateTimeIso,
    bool isSynced = false,
  });

  /// Edit metadata (size/color/sku/prices) and/or set quantity exactly.
  /// If quantity changes, log a movement with the delta.
  Future<void> editStock({
    required String productVariantId,
    String? productId,
    int? sizeEu,
    String? colorName,
    String? colorHex,
    String? sku,
    double? purchasePrice,
    double? salePrice,
    int? newQuantity,
    String? movementId,
    String? dateTimeIso,
    bool isSynced = false,
  });

  /// Movement sync helpers (optional but useful for an offline-first pipeline)
  Future<List<Map<String, dynamic>>> getUnsyncedMovements();

  Future<void> markMovementSynced(String movementId);

  //get unsynced pro and vari

  Future<Map<String, dynamic>> getUnsyncedPayload();

  // -------------------------
  // Queries / Reporting
  // -------------------------
  Future<List<Map<String, dynamic>>> getAllProducts();

  Future<List<Map<String, dynamic>>> getAllVariants();

  /// Stock snapshot with aggregated totals and nested variants (JSON string)
  Future<String> getAllStock();

  /// Delete a variant by id; soft by default
  Future<bool> deleteVariantById(String variantId, {bool hard = false});

  ///now moving towards sales
  Future<String> performSaleTransaction({
    required List<CartItemModel> cartItems,
    required String totalAmount,
    required String paymentType,
    required String amountPaid,
    required String changeReturned,
    required String createdBy,
    required bool isSynced,
  });

  ///summery
  Future<List<Map<String, Object?>>> getSalesSummery({
    required String startDate,
    required String endDate,
  });

  Future<List<Map<String, Object?>>> getAllSales();

  Future<List<Map<String, Object?>>> getSalesByDateRange({
    required String startDate,
    required String endDate,
  });
}
