import 'package:floor/floor.dart';
import 'package:local_shoes_store_pos/services/storage/mobile/entities/product_variants.dart';
import 'package:local_shoes_store_pos/services/storage/mobile/entities/sale.dart';

@Entity(
  tableName: 'sale_lines',
  foreignKeys: [
    ForeignKey(
      childColumns: ['sale_id'],
      parentColumns: ['sale_id'],
      entity: Sale,
      onDelete: ForeignKeyAction.cascade,
    ),
    ForeignKey(
      childColumns: ['variant_id'],
      parentColumns: ['product_variant_id'],
      entity: ProductVariant,
      onDelete: ForeignKeyAction.restrict,
    ),
  ],
  indices: [
    Index(value: ['sale_id']),
    Index(value: ['variant_id']),
  ],
)
class SaleLine {
  @primaryKey
  @ColumnInfo(name: 'sale_line_id')
  final String saleLineId;

  @ColumnInfo(name: 'sale_id')
  final String saleId;

  // ✅ Changed from int → String
  @ColumnInfo(name: 'variant_id')
  final String variantId;

  final int qty;

  // ✅ This is your *sale price per unit*, not purchase price
  @ColumnInfo(name: 'unit_price')
  final double unitPrice;

  @ColumnInfo(name: 'line_total')
  final double lineTotal;

  // ✅ Added audit fields
  @ColumnInfo(name: 'created_at')
  final String createdAt;

  @ColumnInfo(name: 'updated_at')
  final String? updatedAt;

  // ✅ Sync flag (0 = not synced, 1 = synced)
  @ColumnInfo(name: 'is_synced')
  final int isSynced;

  const SaleLine({
    required this.saleLineId,
    required this.saleId,
    required this.variantId,
    required this.qty,
    required this.unitPrice,
    required this.lineTotal,
    required this.createdAt,
    this.updatedAt,
    required this.isSynced,
  });

  SaleLine copyWith({
    String? saleLineId,
    String? saleId,
    String? variantId,
    int? qty,
    double? unitPrice,
    double? lineTotal,
    String? createdAt,
    String? updatedAt,
    int? isSynced,
  }) {
    return SaleLine(
      saleLineId: saleLineId ?? this.saleLineId,
      saleId: saleId ?? this.saleId,
      variantId: variantId ?? this.variantId,
      qty: qty ?? this.qty,
      unitPrice: unitPrice ?? this.unitPrice,
      lineTotal: lineTotal ?? this.lineTotal,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}
