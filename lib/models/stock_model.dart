import 'dart:convert';

class StockModel {
  final String productId;
  final String brand;
  final String articleCode;
  final String articleName;
  final bool isActive;
  final String createdAt;
  final String updatedAt;
  final int totalQty;
  final int variantCount;
  final List<VariantModel> variants;

  StockModel({
    required this.productId,
    required this.brand,
    required this.articleCode,
    required this.articleName,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    required this.totalQty,
    required this.variantCount,
    required this.variants,
  });

  factory StockModel.fromJson(Map<String, dynamic> json) {
    return StockModel(
      productId: json['productId'] ?? '',
      brand: json['brand'] ?? '',
      articleCode: json['articleCode'] ?? '',
      articleName: json['articleName'] ?? '',
      isActive: json['isActive'] ?? false,
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
      totalQty: json['totalQty'] ?? 0,
      variantCount: json['variantCount'] ?? 0,
      variants: (json['variants'] as List<dynamic>? ?? [])
          .map((v) => VariantModel.fromJson(v))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'productId': productId,
    'brand': brand,
    'articleCode': articleCode,
    'articleName': articleName,
    'isActive': isActive,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
    'totalQty': totalQty,
    'variantCount': variantCount,
    'variants': variants.map((v) => v.toJson()).toList(),
  };

  /// Parse a JSON array string into a list of StockModel
  static List<StockModel> listFromJsonString(String jsonString) {
    final decoded = jsonDecode(jsonString);
    if (decoded is List) {
      return decoded.map((e) => StockModel.fromJson(e)).toList();
    }
    return [];
  }
}

class VariantModel {
  final String variantId;
  final String sku;
  final int size;
  final String colorName;
  final String? colorHex;
  final int qty;
  final double purchasePrice;
  final double salePrice;
  final bool isActive;
  final bool isSynced;
  final String createdAt;
  final String updatedAt;

  VariantModel({
    required this.variantId,
    required this.sku,
    required this.size,
    required this.colorName,
    this.colorHex,
    required this.qty,
    required this.purchasePrice,
    required this.salePrice,
    required this.isActive,
    required this.isSynced,
    required this.createdAt,
    required this.updatedAt,
  });

  factory VariantModel.fromJson(Map<String, dynamic> json) {
    return VariantModel(
      variantId: json['variantId'] ?? '',
      sku: json['sku'] ?? '',
      size: json['size'] ?? 0,
      colorName: json['colorName'] ?? '',
      colorHex: json['colorHex'],
      qty: json['qty'] ?? 0,
      purchasePrice: (json['purchasePrice'] as num?)?.toDouble() ?? 0.0,
      salePrice: (json['salePrice'] as num?)?.toDouble() ?? 0.0,
      isActive: json['isActive'] ?? false,
      isSynced: json['isSynced'] ?? false,
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'variantId': variantId,
    'sku': sku,
    'size': size,
    'colorName': colorName,
    'colorHex': colorHex,
    'qty': qty,
    'purchasePrice': purchasePrice,
    'salePrice': salePrice,
    'isActive': isActive,
    'isSynced': isSynced,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };
}
