import 'package:local_shoes_store_pos/services/add_stock_service_local.dart';

class AddStockRepository {
  final StockServiceLocal _stockServiceLocal;
  AddStockRepository(this._stockServiceLocal);
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
  }) async {
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

  Future<dynamic> getAllStockRepo() async {
    return await _stockServiceLocal.getAllStock();
  }

  Future<bool> deleteVariantById(String variantId, {bool hard = false}) async {
    return await _stockServiceLocal.deleteVariantById(variantId);
  }

  Future<String> addInventoryMovementRepo({
    required String movementId,
    required String sku,
    required int quantity,
    required String action, // 'add' or 'subtract'
    required String dateTime,
    bool isSynced = false,
  }) async {
    return await _stockServiceLocal.addInventoryMovement(
      movementId: movementId,
      sku: sku,
      quantity: quantity,
      action: action,
      dateTime: dateTime,
    );
  }
}
