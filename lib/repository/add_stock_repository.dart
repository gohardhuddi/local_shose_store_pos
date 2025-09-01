import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:local_shoes_store_pos/models/dto/upload_stock_dto.dart';
import 'package:local_shoes_store_pos/services/add_stock_service_local.dart';
import 'package:local_shoes_store_pos/services/add_stock_service_remote.dart';

import '../controller/add_stock_bloc/add_stock_events.dart';

class AddStockRepository {
  final StockServiceLocal _stockServiceLocal;
  final AddStockServiceRemote _stockServiceRemote;

  AddStockRepository(this._stockServiceLocal, this._stockServiceRemote);

  // ---------------------------
  // Create / Upsert
  // ---------------------------

  Future<String> addStockToDBRepo({
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
  }) {
    return _stockServiceLocal.addStockToDbService(
      brand: brand,
      articleCode: articleCode,
      articleName: articleName,
      size: size,
      color: color,
      productCodeSku: productCodeSku,
      quantity: quantity,
      purchasePrice: purchasePrice,
      suggestedSalePrice: suggestedSalePrice,
      isEdit: isEdit,
    );
  }

  // ---------------------------
  // Edit (metadata + optional quantity change)
  // ---------------------------

  /// If you want to also change quantity, pass `newQuantity`.
  /// A movement will be recorded with the delta.
  Future<void> editVariantRepo({
    required String productID,
    required String variantID,
    required String size,
    required String color,
    required String productCodeSku,
    required String purchasePrice,
    required String suggestedSalePrice,
    String? newQuantity, // optional exact quantity to set
    String? movementId, // optional for idempotency
    String? dateTimeIso, // optional timestamp
    bool isSynced = false,
  }) {
    return _stockServiceLocal.editVariantService(
      productId: productID,
      variantID: variantID,
      size: size,
      colorName: color,
      productCodeSku: productCodeSku,
      purchasePrice: purchasePrice,
      salePrice: suggestedSalePrice,
      newQuantity: newQuantity,
      movementId: movementId,
      dateTimeIso: dateTimeIso,
      isSynced: isSynced,
    );
  }

  // ---------------------------
  // Movements (explicit add/subtract)
  // ---------------------------

  Future<String> addStockMovementRepo({
    required String movementId,
    required String productVariantId,
    required String quantity,
    String? dateTimeIso,
    bool isSynced = false,
  }) {
    return _stockServiceLocal.addStockMovement(
      movementId: movementId,
      productVariantId: productVariantId,
      quantity: quantity,
      dateTimeIso: dateTimeIso.toString(),
      isSynced: isSynced,
      movementType: StockMovementType.purchaseIn,
    );
  }

  Future<String> subtractStockMovementRepo({
    required String movementId,
    required String productVariantId,
    required String quantity,
    String? dateTimeIso,
    bool isSynced = false,
  }) {
    return _stockServiceLocal.subtractStockMovement(
      movementId: movementId,
      productVariantId: productVariantId,
      quantity: quantity,
      dateTimeIso: dateTimeIso,
      isSynced: isSynced,
    );
  }

  /// Optional: keep the low-level passthrough for special cases.
  Future<String> addInventoryMovementRepo({
    required String movementId,
    required String productCodeSku,
    required int quantity,
    required String action, // 'add' or 'subtract'
    required String dateTime,
    bool isSynced = false,
  }) {
    return _stockServiceLocal.addInventoryMovementLocalService(
      movementId: movementId,
      productSkuCode: productCodeSku,
      quantity: quantity,
      action: action,
      dateTime: dateTime,
      isSynced: isSynced,
    );
  }

  // ---------------------------
  // Queries / Sync / Deletes
  // ---------------------------

  Future<dynamic> getAllStockRepo() => _stockServiceLocal.getAllStock();

  Future<dynamic> getUnSyncPayloadRepo() =>
      _stockServiceLocal.getUnSyncPayload();

  Future<List<Map<String, dynamic>>> getAllProductsRepo() =>
      _stockServiceLocal.getAllProducts();

  Future<List<Map<String, dynamic>>> getAllVariantsRepo() =>
      _stockServiceLocal.getAllVariants();

  Future<List<Map<String, dynamic>>> getUnsyncedMovementsRepo() =>
      _stockServiceLocal.getUnsyncedMovements();

  Future<void> markMovementSyncedRepo(String movementId) =>
      _stockServiceLocal.markMovementSynced(movementId);

  Future<bool> deleteVariantById(String variantId, {bool hard = false}) {
    // Forward the 'hard' flag (previously ignored).
    return _stockServiceLocal.deleteVariantById(variantId, hard: hard);
  }

  Future<dynamic> syncProductsToBackend(dynamic mapedList) {
    return _stockServiceRemote.uploadCatalogList(mapedList);
  }

  // ---------------------------
  // Business Logic - Data Mapping
  // ---------------------------

  /// Maps unsynced data to backend format
  Future<List<Map<String, dynamic>>> mapUnsyncedToBackend(
    Map<String, dynamic> unsynced,
  ) async {
    if (kDebugMode) {
      print(jsonEncode(unsynced));
    }

    final products = (unsynced['products'] as List? ?? const [])
        .cast<Map>()
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    final variants = (unsynced['variants'] as List? ?? const [])
        .cast<Map>()
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    final productDtos = ProductDto.buildFromLists(
      products: products,
      variants: variants,
    );

    return productDtos.map((dto) => dto.toJson()).toList();
  }

  // Future<String> addStockMovementToDb({
  //   required String movementId,
  //   required String productCodeSku,
  //   required StockMovementType movementType,
  //   required String quantity,
  //   required String dateTimeIso,
  //   required bool isSynced,
  // }) {
  //   return _stockServiceLocal.addStockMovement(
  //     movementId: movementId,
  //     productVariantId: productCodeSku,
  //     movementType: movementType,
  //     quantity: quantity,
  //     dateTimeIso: dateTimeIso,
  //     isSynced: isSynced,
  //   );
  // }
}
