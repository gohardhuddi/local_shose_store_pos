import 'package:floor/floor.dart';

import 'sale.dart';

@Entity(
  tableName: 'returns',
  foreignKeys: [
    ForeignKey(
      childColumns: ['sale_id'],
      parentColumns: ['sale_id'],
      entity: Sale,
      onDelete: ForeignKeyAction.cascade,
    ),
  ],
)
class ReturnEntity {
  @primaryKey
  @ColumnInfo(name: 'return_id')
  final String returnId;

  @ColumnInfo(name: 'sale_id')
  final String saleId;

  @ColumnInfo(name: 'date_time')
  final String dateTime;

  @ColumnInfo(name: 'total_refund')
  final double totalRefund;

  final String? reason;
  final String? createdBy;

  @ColumnInfo(name: 'is_synced')
  final int isSynced;

  @ColumnInfo(name: 'created_at')
  final String createdAt;

  @ColumnInfo(name: 'updated_at')
  final String updatedAt;

  const ReturnEntity({
    required this.returnId,
    required this.saleId,
    required this.dateTime,
    required this.totalRefund,
    this.reason,
    this.createdBy,
    required this.isSynced,
    required this.createdAt,
    required this.updatedAt,
  });
}
