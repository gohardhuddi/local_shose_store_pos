import '../../main.dart';
import '../../models/cart_model.dart';

class ReturnServiceLocal {
  Future<String> addReturnService({
    required String saleId,
    required List<CartItemModel> items,
    required double totalRefund,
    String? reason,
    String? createdBy,
    bool isSynced = false,
  }) async {
    return stockDb.performReturnTransaction(
      saleId: saleId,
      returnedItems: items,
      totalRefund: totalRefund,
      reason: reason,
      createdBy: createdBy,
      isSynced: isSynced,
    );
  }

  Future<String> getAllReturnService({
    required String saleId,
    required List<CartItemModel> items,
    required double totalRefund,
    String? reason,
    String? createdBy,
    bool isSynced = false,
  }) async {
    return stockDb.performReturnTransaction(
      saleId: saleId,
      returnedItems: items,
      totalRefund: totalRefund,
      reason: reason,
      createdBy: createdBy,
      isSynced: isSynced,
    );
  }
}
