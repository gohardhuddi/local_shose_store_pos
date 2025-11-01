import 'dart:convert';

import '../../services/storage/mobile/entities/sale.dart';
import '../sale_line_view.dart';

class SaleWithLines {
  final Sale sale;
  final List<SaleLineView> lines;

  SaleWithLines({required this.sale, required this.lines});

  factory SaleWithLines.fromJson(Map<String, dynamic> json) {
    final sale = Sale(
      saleId: json['saleId']?.toString() ?? '',
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0.0,
      finalAmount: (json['finalAmount'] as num?)?.toDouble() ?? 0.0,
      paymentType: json['paymentType']?.toString() ?? '',
      amountPaid: (json['amountPaid'] as num?)?.toDouble() ?? 0.0,
      changeReturned: (json['changeReturned'] as num?)?.toDouble() ?? 0.0,
      createdBy: json['createdBy']?.toString() ?? '',
      isSynced: (json['isSynced'] as int?) ?? 0,
      dateTime: json['dateTime']?.toString() ?? '',
      createdAt: json['createdAt']?.toString() ?? '',
      saleType: 'sale',
    );

    final dynamic saleLinesRaw = json['saleLines'];
    final List<SaleLineView> lines = [];

    if (saleLinesRaw == null) {
      // No lines
    } else if (saleLinesRaw is List) {
      // ✅ Already a list from local DB
      for (final l in saleLinesRaw) {
        lines.add(SaleLineView.fromJson(l, sale.saleId));
      }
    } else if (saleLinesRaw is String && saleLinesRaw.isNotEmpty) {
      // ✅ A JSON string (remote API or stored JSON)
      try {
        final decoded = jsonDecode(saleLinesRaw) as List;
        for (final l in decoded) {
          lines.add(SaleLineView.fromJson(l, sale.saleId));
        }
      } catch (e) {
        print('⚠️ Failed to decode saleLines JSON: $e');
      }
    } else {
      print('⚠️ Unknown saleLines type: ${saleLinesRaw.runtimeType}');
    }

    return SaleWithLines(sale: sale, lines: lines);
  }
}
