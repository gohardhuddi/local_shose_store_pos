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
    print(rows);

    final Map<String, Map<String, dynamic>> grouped = {};

    for (final row in rows) {
      final saleId = row['saleId'].toString();

      if (!grouped.containsKey(saleId)) {
        grouped[saleId] = {
          'saleId': row['saleId'],
          'totalAmount': row['totalAmount'],
          'discountAmount': row['discountAmount'],
          'finalAmount': row['finalAmount'],
          'paymentType': row['paymentType'],
          'amountPaid': row['amountPaid'],
          'changeReturned': row['changeReturned'],
          'createdBy': row['createdBy'],
          'isSynced': row['isSynced'],
          'dateTime': row['dateTime'],
          'createdAt': row['createdAt'],
          // CORRECT: initialize saleLines as REAL LIST
          'saleLines': [],
        };
      }

      grouped[saleId]!['saleLines'].add({
        'saleLineId': row['saleLineId'],
        'variantId': row['variantId'],
        'sku': row['sku'],
        'brand': row['brand'],
        'articleCode': row['articleCode'],
        'sizeEu': row['sizeEu'],
        'colorName': row['colorName'],
        'qty': row['qty'],
        'unitPrice': row['unitPrice'],
        'lineTotal': row['lineTotal'],
      });
    }

    return grouped.values.map((g) => SaleWithLines.fromJson(g)).toList();
  }

  Future<List<SaleWithLines>> getSalesByDateRange({
    required String startDate,
    required String endDate,
  }) async {
    final rows = await _salesServiceLocal.getSalesByDateRange(
      startDate: startDate,
      endDate: endDate,
    );
    return rows.map((row) => SaleWithLines.fromJson(row)).toList();
  }
}
