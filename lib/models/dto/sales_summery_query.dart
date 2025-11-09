class SalesSummaryQuery {
  final double totalSales;
  final int totalOrders;
  final int itemsSold;

  SalesSummaryQuery(this.totalSales, this.totalOrders, this.itemsSold);

  /// Factory method to create from raw query result
  factory SalesSummaryQuery.fromMap(Map<String, Object?> map) {
    return SalesSummaryQuery(
      (map['total_sales'] as num?)?.toDouble() ?? 0.0,
      (map['total_orders'] as num?)?.toInt() ?? 0,
      (map['items_sold'] as num?)?.toInt() ?? 0,
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
