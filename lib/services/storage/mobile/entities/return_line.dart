import 'package:floor/floor.dart';

import 'product_variants.dart';
import 'return_entity.dart';

@Entity(
  tableName: 'return_lines',
  foreignKeys: [
    ForeignKey(
      childColumns: ['return_id'],
      parentColumns: ['return_id'],
      entity: ReturnEntity,
      onDelete: ForeignKeyAction.cascade,
    ),
    ForeignKey(
      childColumns: ['variant_id'],
      parentColumns: ['product_variant_id'],
      entity: ProductVariant,
      onDelete: ForeignKeyAction.noAction,
    ),
  ],
)
class ReturnLine {
  @primaryKey
  @ColumnInfo(name: 'return_line_id')
  final String returnLineId;

  @ColumnInfo(name: 'return_id')
  final String returnId;

  @ColumnInfo(name: 'variant_id')
  final String variantId;

  final int qty;

  @ColumnInfo(name: 'unit_price')
  final double unitPrice;

  @ColumnInfo(name: 'refund_amount')
  final double refundAmount;

  @ColumnInfo(name: 'is_synced')
  final int isSynced;

  @ColumnInfo(name: 'created_at')
  final String createdAt;

  @ColumnInfo(name: 'updated_at')
  final String updatedAt;

  const ReturnLine({
    required this.returnLineId,
    required this.returnId,
    required this.variantId,
    required this.qty,
    required this.unitPrice,
    required this.refundAmount,
    required this.isSynced,
    required this.createdAt,
    required this.updatedAt,
  });
}
