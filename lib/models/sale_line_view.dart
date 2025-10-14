import '../../services/storage/mobile/entities/sale_line.dart';

class SaleLineView {
  final SaleLine line;
  final String sku;

  SaleLineView({required this.line, required this.sku});

  factory SaleLineView.fromJson(Map<String, dynamic> json, String saleId) {
    final saleLine = SaleLine(
      saleLineId: json['saleLineId']?.toString() ?? '',
      saleId: saleId,
      variantId: json['variantId']?.toString() ?? '',
      qty: (json['qty'] as num?)?.toInt() ?? 0,
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0.0,
      lineTotal: (json['lineTotal'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['createdAt']?.toString() ?? '',
      isSynced: (json['isSynced'] as int?) ?? 0,
    );

    return SaleLineView(line: saleLine, sku: json['sku']?.toString() ?? '');
  }
}
