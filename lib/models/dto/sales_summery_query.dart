class SalesSummaryQuery {
  final double totalSales;
  final int totalOrders;
  final int itemsSold;

  SalesSummaryQuery(this.totalSales, this.totalOrders, this.itemsSold);

  /// Factory method to create from raw query result
  factory SalesSummaryQuery.fromMap(Map<String, Object?> map) {
    return SalesSummaryQuery(
      (map['totalSales'] as num?)?.toDouble() ?? 0.0,
      (map['totalOrders'] as num?)?.toInt() ?? 0,
      (map['itemsSold'] as num?)?.toInt() ?? 0,
    );
  }

  /// Optional: convert to map (like toJson)
  Map<String, dynamic> toMap() {
    return {
      'totalSales': totalSales,
      'totalOrders': totalOrders,
      'itemsSold': itemsSold,
    };
  }
}
