import 'package:floor/floor.dart';

@Entity(
  tableName: 'sales',
  indices: [
    Index(value: ['date_time']),
    Index(value: ['created_by']),
  ],
)
class Sale {
  @primaryKey
  @ColumnInfo(name: 'sale_id')
  final String saleId;

  @ColumnInfo(name: 'date_time')
  final String dateTime;

  @ColumnInfo(name: 'customer_id')
  final String? customerId;

  @ColumnInfo(name: 'total_amount')
  final double totalAmount;

  @ColumnInfo(name: 'discount_amount')
  final double discountAmount;

  @ColumnInfo(name: 'final_amount')
  final double finalAmount;

  @ColumnInfo(name: 'payment_type')
  final String paymentType;

  @ColumnInfo(name: 'amount_paid')
  final double amountPaid;

  @ColumnInfo(name: 'change_returned')
  final double changeReturned;

  @ColumnInfo(name: 'created_by')
  final String createdBy;

  // ✅ New audit fields
  @ColumnInfo(name: 'created_at')
  final String createdAt;

  @ColumnInfo(name: 'updated_at')
  final String? updatedAt;

  // ✅ Sync flag (0 = not synced, 1 = synced)
  @ColumnInfo(name: 'is_synced')
  final int isSynced;

  const Sale({
    required this.saleId,
    required this.dateTime,
    this.customerId,
    required this.totalAmount,
    required this.discountAmount,
    required this.finalAmount,
    required this.paymentType,
    required this.amountPaid,
    required this.changeReturned,
    required this.createdBy,
    required this.createdAt,
    this.updatedAt,
    required this.isSynced,
  });

  Sale copyWith({
    String? saleId,
    String? dateTime,
    String? customerId,
    double? totalAmount,
    double? discountAmount,
    double? finalAmount,
    String? paymentType,
    double? amountPaid,
    double? changeReturned,
    String? createdBy,
    String? createdAt,
    String? updatedAt,
    int? isSynced,
  }) {
    return Sale(
      saleId: saleId ?? this.saleId,
      dateTime: dateTime ?? this.dateTime,
      customerId: customerId ?? this.customerId,
      totalAmount: totalAmount ?? this.totalAmount,
      discountAmount: discountAmount ?? this.discountAmount,
      finalAmount: finalAmount ?? this.finalAmount,
      paymentType: paymentType ?? this.paymentType,
      amountPaid: amountPaid ?? this.amountPaid,
      changeReturned: changeReturned ?? this.changeReturned,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}
