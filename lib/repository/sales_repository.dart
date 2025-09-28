import 'package:local_shoes_store_pos/services/sales/sales_service_remote.dart';

import '../services/sales/sales_service_local.dart';

class SalesRepository {
  final SalesServiceRemote _salesServiceRemote;
  final SaleServiceLocal _salesServiceLocal;

  SalesRepository(this._salesServiceRemote, this._salesServiceLocal);

  Future<String> addSalesToDB({
    required String totalAmount,
    required String paymentType,
    required String amountPaid,
    required String changeReturned,
    required String createdBy,
    required bool isSynced,
  }) {
    return _salesServiceLocal.addSalesToDbService(
      totalAmount: totalAmount,
      paymentType: paymentType,
      amountPaid: amountPaid,
      changeReturned: changeReturned,
      createdBy: createdBy,
      isSynced: isSynced,
    );
  }
}
