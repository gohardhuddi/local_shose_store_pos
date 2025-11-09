import 'package:local_shoes_store_pos/services/return_service/retun_service_local.dart';

import '../models/cart_model.dart';

class ReturnRepository {
  final ReturnServiceLocal _returnServiceLocal;

  ReturnRepository(this._returnServiceLocal);

  Future<String> addReturn({
    required String saleId,
    required List<CartItemModel> items,
    required double totalRefund,
    String? reason,
    String? createdBy,
    bool isSynced = false,
  }) async {
    return _returnServiceLocal.addReturnService(
      saleId: saleId,
      items: items,
      totalRefund: totalRefund,
      reason: reason,
      createdBy: createdBy,
      isSynced: isSynced,
    );
  }
}
