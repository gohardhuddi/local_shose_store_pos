import 'package:flutter/foundation.dart';
import 'package:local_shoes_store_pos/controller/add_stock_bloc/add_stock_events.dart';

import '../main.dart'; // expects a global `stockDb` that implements the extended StockDb interface

class StockServiceLocal {
  // ---------------------------
  // Helpers
  // ---------------------------
  int _parseInt(String label, String value) {
    final v = int.tryParse(value.trim());
    if (v == null)
      throw FormatException('Invalid integer for $label: "$value"');
    return v;
  }

  double _parseDouble(String label, String value) {
    final v = double.tryParse(value.trim());
    if (v == null) throw FormatException('Invalid number for $label: "$value"');
    return v;
  }

  String _normStr(String? s) => (s ?? '').trim();

  String _normUpper(String s) => s.trim().toUpperCase();

  // ---------------------------
  // Create / Upsert
  // ---------------------------

  /// Create or update a product and its variant.
  /// If `isEdit == true`, quantity is set exactly to `quantity`.
  /// If `isEdit == false`, quantity is ADDED to the existing quantity.
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
    required bool isEdit,
  }) async {
    final productId = await stockDb.upsertProduct(
      brand: _normStr(brand),
      articleCode: _normUpper(articleCode),
      articleName: _normStr(articleName),
    );

    await stockDb.upsertVariant(
      productId: productId,
      sizeEu: _parseInt('size', size),
      colorName: _normStr(color),
      sku: _normUpper(productCodeSku),
      quantity: _parseInt('quantity', quantity),
      purchasePrice: _parseDouble('purchasePrice', purchasePrice),
      salePrice: _parseDouble('suggestedSalePrice', suggestedSalePrice),
      isEdit: isEdit,
    );

    return productId;
  }

  // ---------------------------
  // Edit (metadata + optional quantity change)
  // ---------------------------

  /// Edit an existing variant’s fields. If you also want to change quantity,
  /// pass `newQuantity`. This will record a movement with the delta.
  Future<void> editVariantService({
    required String productId,
    required String variantID, // product_variant_id (stringified PK)
    required String size,
    required String colorName,
    required String productCodeSku,
    required String purchasePrice,
    required String salePrice,
    String? newQuantity, // optional: if provided, set qty exactly to this value
    String? movementId, // optional: for idempotency if your UI might retry
    String? dateTimeIso, // optional: else uses now() in DB layer
    bool isSynced = false,
  }) async {
    await stockDb.editStock(
      productVariantId: variantID,
      productId: productId,
      sizeEu: _parseInt('size', size),
      colorName: _normStr(colorName),
      sku: _normUpper(productCodeSku),
      purchasePrice: _parseDouble('purchasePrice', purchasePrice),
      salePrice: _parseDouble('salePrice', salePrice),
      newQuantity: newQuantity == null
          ? null
          : _parseInt('newQuantity', newQuantity),
      movementId: movementId,
      dateTimeIso: dateTimeIso,
      isSynced: isSynced,
    );
  }

  // ---------------------------
  // Movements (explicit add/subtract) — nice for “Adjust Stock” screen
  // ---------------------------

  Future<String> addStockMovement({
    required String movementId,
    required String productVariantId,
    required String quantity,
    required String dateTimeIso,
    bool isSynced = false,
    required StockMovementType movementType,
  }) async {
    return stockDb.addInventoryMovement(
      movementId: movementId,
      productVariantId: productVariantId,
      quantity: _parseInt('quantity', quantity),
      dateTime: dateTimeIso,
      isSynced: isSynced,
      action: movementType.toString(),
    );
  }

  Future<String> subtractStockMovement({
    required String movementId,
    required String productVariantId,
    required String quantity,
    String? dateTimeIso,
    bool isSynced = false,
  }) async {
    return stockDb.subtractStock(
      movementId: movementId,
      productVariantId: productVariantId,
      quantity: _parseInt('quantity', quantity),
      dateTimeIso: dateTimeIso,
      isSynced: isSynced,
    );
  }

  /// Low-level passthrough (if you really want to call it directly).
  Future<String> addInventoryMovementLocalService({
    required String movementId,
    required String productSkuCode,
    required int quantity,
    required String action, // 'add' or 'subtract'
    required String dateTime,
    bool isSynced = false,
  }) async {
    return stockDb.addInventoryMovement(
      movementId: movementId,
      productVariantId: productSkuCode,
      quantity: quantity,
      action: action,
      dateTime: dateTime,
      isSynced: isSynced,
    );
  }

  // ---------------------------
  // Movement sync helpers
  // ---------------------------

  Future<List<Map<String, dynamic>>> getUnsyncedMovements() {
    return stockDb.getUnsyncedMovements();
  }

  Future<void> markMovementSynced(String movementId) {
    return stockDb.markMovementSynced(movementId);
  }

  // ---------------------------
  // Queries / Deletes
  // ---------------------------

  Future<dynamic> getAllStock() => stockDb.getAllStock();

  Future<dynamic> getUnSyncPayload() {
    var unsynced = stockDb.getUnsyncedPayload();
    if (kDebugMode) {
      print(unsynced);
    }
    return unsynced;
  }

  Future<List<Map<String, dynamic>>> getAllProducts() =>
      stockDb.getAllProducts();

  Future<List<Map<String, dynamic>>> getAllVariants() =>
      stockDb.getAllVariants();

  Future<bool> deleteVariantById(String variantId, {bool hard = false}) {
    return stockDb.deleteVariantById(variantId, hard: hard);
  }
}
