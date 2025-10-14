import '../../main.dart';
import '../../models/cart_model.dart';

class SaleServiceLocal {
  Future<String> addSalesToDbService({
    required List<CartItemModel> cartItems,
    required String totalAmount,
    required String paymentType,
    required String amountPaid,
    required String changeReturned,
    required String createdBy,
    required bool isSynced,
  }) async {
    try {
      // ✅ Use the single atomic transaction in StockDb
      final saleID = await stockDb.performSaleTransaction(
        cartItems: cartItems,
        totalAmount: totalAmount,
        paymentType: paymentType,
        amountPaid: amountPaid,
        changeReturned: changeReturned,
        createdBy: createdBy,
        isSynced: isSynced,
      );

      // No need to insert sale lines here — already done inside performSaleTransaction
      return saleID;
    } catch (e, st) {
      // Optional: Log or handle rollback errors gracefully
      print('❌ Sale transaction failed: $e');
      print(st);
      rethrow; // rethrow to let upper layer (like BLoC) show user message
    }
  }

  Future<List<Map<String, Object?>>> getSalesSummaryFromDb({
    required String startDate,
    required String endDate,
  }) async {
    try {
      // ✅ Use the single atomic transaction in StockDb
      final salesSummery = await stockDb.getSalesSummery(
        startDate: startDate,
        endDate: endDate,
      );

      // No need to insert sale lines here — already done inside performSaleTransaction
      return salesSummery;
    } catch (e, st) {
      // Optional: Log or handle rollback errors gracefully
      print('❌ Sale summery failed: $e');
      print(st);
      rethrow; // rethrow to let upper layer (like BLoC) show user message
    }
  }

  Future<List<Map<String, Object?>>> getAllSalesWithLines() async {
    try {
      // ✅ Use the single atomic transaction in StockDb
      final sales = await stockDb.getAllSales();

      // No need to insert sale lines here — already done inside performSaleTransaction
      return sales;
    } catch (e, st) {
      // Optional: Log or handle rollback errors gracefully
      print('❌ Sale summery failed: $e');
      print(st);
      rethrow; // rethrow to let upper layer (like BLoC) show user message
    }
  }
}
