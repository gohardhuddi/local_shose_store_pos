import 'package:floor/floor.dart';

import 'category.dart';
import 'gender.dart';

@Entity(
  tableName: 'products',
  indices: [
    Index(value: ['article_code'], unique: true),
    Index(value: ['category_id']),
    Index(value: ['gender_id']),
  ],
  foreignKeys: [
    ForeignKey(
      childColumns: ['category_id'],
      parentColumns: ['category_id'],
      entity: Category, // <-- make sure to import your Category entity
      onDelete: ForeignKeyAction.setNull,
    ),
    ForeignKey(
      childColumns: ['gender_id'],
      parentColumns: ['gender_id'],
      entity: Gender, // <-- import Gender entity
      onDelete: ForeignKeyAction.setNull,
    ),
  ],
)
class Product {
  @primaryKey
  @ColumnInfo(name: 'product_id')
  final String? id;

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

  // ✅ New category & gender references
  @ColumnInfo(name: 'category_id')
  final String? categoryId;

  @ColumnInfo(name: 'gender_id')
  final String? genderId;

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
    this.categoryId,
    this.genderId,
  });

  Product copyWith({
    String? id,
    String? brand,
    String? articleCode,
    String? articleName,
    String? notes,
    int? isActive,
    int? isSynced,
    String? createdAt,
    String? updatedAt,
    String? categoryId,
    String? genderId,
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
      categoryId: categoryId ?? this.categoryId,
      genderId: genderId ?? this.genderId,
    );
  }
}
