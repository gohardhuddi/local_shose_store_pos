import 'package:floor/floor.dart';

@Entity(
  tableName: 'inventory_movements',

  indices: [
    Index(value: ['product_variant_id']),
  ],
)
class InventoryMovement {
  @primaryKey
  @ColumnInfo(name: 'movement_id')
  final String movementId;

  @ColumnInfo(name: 'product_variant_id')
  final String productVariantId;

  final int quantity; // CHECK (quantity > 0)

  /// one of: purchase_in, sale_out, return_in, return_out, transfer_in,
  /// transfer_out, adjustment_pos, adjustment_neg, damage, stocktake_correction
  final String action;

  @ColumnInfo(name: 'date_time')
  final String dateTime; // ISO-8601

  @ColumnInfo(name: 'is_synced')
  final int isSynced;

  const InventoryMovement({
    required this.movementId,
    required this.productVariantId,
    required this.quantity,
    required this.action,
    required this.dateTime,
    required this.isSynced,
  });
}
