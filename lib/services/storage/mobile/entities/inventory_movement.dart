import 'package:floor/floor.dart';
import 'product_variants.dart';

@Entity(
  tableName: 'inventory_movements',
  foreignKeys: [
    ForeignKey(
      childColumns: ['product_variant_id'],
      parentColumns: ['product_variant_id'],
      entity: ProductVariant,
      onDelete: ForeignKeyAction.cascade,
    ),
  ],
  indices: [
    Index(value: ['product_variant_id']),
  ],
)
class InventoryMovement {
  @primaryKey
  @ColumnInfo(name: 'movement_id')
  final String movementId;

  @ColumnInfo(name: 'product_variant_id')
  final int productVariantId;

  final int quantity; // > 0

  final String action; // 'add' | 'subtract'

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
