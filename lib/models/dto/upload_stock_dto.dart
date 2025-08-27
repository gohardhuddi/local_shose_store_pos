// ----------------- helpers -----------------
T? pick<T>(Map m, List keys) {
  for (final k in keys) {
    if (m.containsKey(k) && m[k] != null) return m[k] as T?;
  }
  return null;
}

bool toBool(dynamic v) {
  if (v is bool) return v;
  if (v is num) return v != 0;
  if (v is String) return v == '1' || v.toLowerCase() == 'true';
  return false;
}

double? toDoubleOrNull(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}

double toDoubleOrZero(dynamic v) => toDoubleOrNull(v) ?? 0.0;

// ----------------- models -----------------
class VariantDto {
  final String productVariantId;
  final String productId;
  final double? sizeEu;
  final String? colorName;
  final String? colorHex;
  final String? sku;
  final int? quantity;
  final double purchasePrice;
  final double? salePrice;

  VariantDto({
    required this.productVariantId,
    required this.productId,
    this.sizeEu,
    this.colorName,
    this.colorHex,
    this.sku,
    this.quantity,
    this.purchasePrice = 0.0,
    this.salePrice,
  });

  factory VariantDto.fromFlexible(Map v, {required String productId}) {
    return VariantDto(
      productVariantId:
          (pick<Object>(v, ['product_variant_id', 'productVariantId', 'id']) ??
                  '')
              .toString(),
      productId: productId,
      sizeEu: toDoubleOrNull(pick(v, ['size_eu'])),
      colorName: pick<String>(v, ['color_name']),
      colorHex: pick<String>(v, ['color_hex']),
      sku: pick<String>(v, ['sku']),
      quantity: (pick<num>(v, ['quantity']))?.toInt(),
      purchasePrice: toDoubleOrZero(pick(v, ['purchase_price'])),
      salePrice: toDoubleOrNull(pick(v, ['sale_price'])),
    );
  }

  Map<String, dynamic> toJson() => {
    'productVariantId': productVariantId,
    'productId': productId,
    'sizeEu': sizeEu,
    'colorName': colorName,
    'colorHex': colorHex,
    'sku': sku,
    'quantity': quantity,
    'purchasePrice': purchasePrice,
    'salePrice': salePrice,
  };
}

class ProductDto {
  final String productId;
  final String brand;
  final String articleCode;
  final String articleName;
  final String notes;
  final bool isActive;
  final List<VariantDto> variants;

  ProductDto({
    required this.productId,
    this.brand = '',
    this.articleCode = '',
    this.articleName = '',
    this.notes = '',
    this.isActive = true,
    this.variants = const <VariantDto>[],
  });

  factory ProductDto.fromFlexible(Map p, List<Map> allVariants) {
    final pid = (pick<Object>(p, ['id', 'product_id', 'productId']) ?? '')
        .toString();

    // gather matching variants for this product
    final vlist = allVariants
        .where((v) {
          final vpid = (pick<Object>(v, ['product_id', 'productId']) ?? '')
              .toString();
          return vpid == pid;
        })
        .map((v) => VariantDto.fromFlexible(v, productId: pid))
        .toList();

    return ProductDto(
      productId: pid,
      brand: (pick<Object>(p, ['brand']) ?? '').toString(),
      articleCode: (pick<Object>(p, ['article_code', 'articleCode']) ?? '')
          .toString(),
      articleName: (pick<Object>(p, ['article_name', 'articleName']) ?? '')
          .toString(),
      notes: (pick<Object>(p, ['notes']) ?? '').toString(),
      isActive: toBool(pick<Object>(p, ['is_active', 'isActive']) ?? 1),
      variants: vlist,
    );
  }

  Map<String, dynamic> toJson() => {
    'productId': productId,
    'brand': brand,
    'articleCode': articleCode,
    'articleName': articleName,
    'notes': notes,
    'isActive': isActive,
    'variants': variants.map((v) => v.toJson()).toList(),
  };

  /// Static builder that accepts your two lists and returns typed products.
  static List<ProductDto> buildFromLists({
    required List products,
    required List variants,
  }) {
    final pList = products.whereType<Map>().toList(growable: false);
    final vList = variants.whereType<Map>().toList(growable: false);
    return pList
        .map((p) => ProductDto.fromFlexible(p, vList))
        .toList(growable: false);
  }
}
