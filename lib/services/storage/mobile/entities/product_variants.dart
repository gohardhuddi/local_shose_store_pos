import 'package:floor/floor.dart';

import 'products.dart';

@Entity(
  tableName: 'product_variants',
  foreignKeys: [
    ForeignKey(
      childColumns: ['product_id'],
      parentColumns: ['product_id'],
      entity: Product,
      onDelete: ForeignKeyAction.cascade,
    ),
  ],
  indices: [
    Index(value: ['product_id']),
    Index(value: ['product_id', 'is_active']),
    Index(value: ['sku'], unique: true),
  ],
)
class ProductVariant {
  @primaryKey
  @ColumnInfo(name: 'product_variant_id')
  final String? id;

  @ColumnInfo(name: 'product_id')
  final String productId;

  @ColumnInfo(name: 'size_eu')
  final int sizeEu;

  @ColumnInfo(name: 'color_name')
  final String colorName;

  @ColumnInfo(name: 'color_hex')
  final String? colorHex;

  final String sku;

  final int quantity;

  @ColumnInfo(name: 'purchase_price')
  final double purchasePrice;

  @ColumnInfo(name: 'sale_price')
  final double? salePrice;

  @ColumnInfo(name: 'is_active')
  final int isActive;

  @ColumnInfo(name: 'is_synced')
  final int isSynced;

  @ColumnInfo(name: 'created_at')
  final String createdAt;

  @ColumnInfo(name: 'updated_at')
  final String updatedAt;

  const ProductVariant({
    this.id,
    required this.productId,
    required this.sizeEu,
    required this.colorName,
    this.colorHex,
    required this.sku,
    required this.quantity,
    required this.purchasePrice,
    this.salePrice,
    required this.isActive,
    required this.isSynced,
    required this.createdAt,
    required this.updatedAt,
  });

  ProductVariant copyWith({
    String? id,
    String? productId,
    int? sizeEu,
    String? colorName,
    String? colorHex,
    String? sku,
    int? quantity,
    double? purchasePrice,
    double? salePrice,
    int? isActive,
    int? isSynced,
    String? createdAt,
    String? updatedAt,
  }) {
    return ProductVariant(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      sizeEu: sizeEu ?? this.sizeEu,
      colorName: colorName ?? this.colorName,
      colorHex: colorHex ?? this.colorHex,
      sku: sku ?? this.sku,
      quantity: quantity ?? this.quantity,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      salePrice: salePrice ?? this.salePrice,
      isActive: isActive ?? this.isActive,
      isSynced: isSynced ?? this.isSynced,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
