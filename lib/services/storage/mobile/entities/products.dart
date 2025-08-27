import 'package:floor/floor.dart';

@Entity(
  tableName: 'products',
  indices: [
    Index(value: ['article_code'], unique: true),
  ],
)
class Product {
  @primaryKey
  @ColumnInfo(name: 'product_id')
  final int? id;

  final String brand;

  @ColumnInfo(name: 'article_code')
  final String articleCode;

  @ColumnInfo(name: 'article_name')
  final String? articleName;

  final String? notes;

  @ColumnInfo(name: 'is_active')
  final int isActive;

  @ColumnInfo(name: 'is_synced')
  final int isSynced;

  @ColumnInfo(name: 'created_at')
  final String createdAt;

  @ColumnInfo(name: 'updated_at')
  final String updatedAt;

  const Product({
    this.id,
    required this.brand,
    required this.articleCode,
    this.articleName,
    this.notes,
    required this.isActive,
    required this.isSynced,
    required this.createdAt,
    required this.updatedAt,
  });

  Product copyWith({
    int? id,
    String? brand,
    String? articleCode,
    String? articleName,
    String? notes,
    int? isActive,
    int? isSynced,
    String? createdAt,
    String? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      brand: brand ?? this.brand,
      articleCode: articleCode ?? this.articleCode,
      articleName: articleName ?? this.articleName,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      isSynced: isSynced ?? this.isSynced,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
