import 'package:local_shoes_store_pos/services/sales/sales_service_remote.dart';

import '../models/cart_model.dart';
import '../models/dto/get_all_sales_with_lines_model.dart';
import '../models/dto/sales_summery_query.dart';
import '../services/sales/sales_service_local.dart';

class SalesRepository {
  final SalesServiceRemote _salesServiceRemote;
  final SaleServiceLocal _salesServiceLocal;

  SalesRepository(this._salesServiceRemote, this._salesServiceLocal);

  Future<String> addSalesToDB({
    required List<CartItemModel> cartItems,
    required String totalAmount,
    required String paymentType,
    required String amountPaid,
    required String changeReturned,
    required String createdBy,
    required bool isSynced,
  }) {
    return _salesServiceLocal.addSalesToDbService(
      cartItems: cartItems,
      totalAmount: totalAmount,
      paymentType: paymentType,
      amountPaid: amountPaid,
      changeReturned: changeReturned,
      createdBy: createdBy,
      isSynced: isSynced,
    );
  }

  Future<SalesSummaryQuery?> getSalesSummary({
    required String startDate,
    required String endDate,
  }) async {
    // Get raw query result from your local service/DAO
    final result = await _salesServiceLocal.getSalesSummaryFromDb(
      startDate: startDate,
      endDate: endDate,
    );

    // If result is empty, return null
    if (result.isEmpty) return null;

    // Map the first row to SalesSummaryQuery
    return SalesSummaryQuery.fromMap(result.first);
  }

  Future<List<SaleWithLines>> getAllSalesWithLines() async {
    final rows = await _salesServiceLocal.getAllSalesWithLines();
    return rows.map((row) => SaleWithLines.fromJson(row)).toList();
  }
}
