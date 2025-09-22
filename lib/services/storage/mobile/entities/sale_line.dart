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

  @ColumnInfo(name: 'variant_id')
  final int variantId;

  final int qty;

  @ColumnInfo(name: 'unit_price')
  final double unitPrice;

  @ColumnInfo(name: 'line_total')
  final double lineTotal;

  const SaleLine({
    required this.saleLineId,
    required this.saleId,
    required this.variantId,
    required this.qty,
    required this.unitPrice,
    required this.lineTotal,
  });

  SaleLine copyWith({
    String? saleLineId,
    String? saleId,
    int? variantId,
    int? qty,
    double? unitPrice,
    double? lineTotal,
  }) {
    return SaleLine(
      saleLineId: saleLineId ?? this.saleLineId,
      saleId: saleId ?? this.saleId,
      variantId: variantId ?? this.variantId,
      qty: qty ?? this.qty,
      unitPrice: unitPrice ?? this.unitPrice,
      lineTotal: lineTotal ?? this.lineTotal,
    );
  }
}
