import 'package:floor/floor.dart';

@Entity(
  tableName: 'categories',
  indices: [
    Index(value: ['category_name'], unique: true),
  ],
)
class Category {
  @primaryKey
  @ColumnInfo(name: 'category_id')
  final String categoryId; // UUID or custom string ID

  @ColumnInfo(name: 'category_name')
  final String categoryName; // e.g. Jogger, Sandal, Flat

  @ColumnInfo(name: 'is_active')
  final int isActive; // 1 = active, 0 = inactive

  // ✅ Audit fields
  @ColumnInfo(name: 'created_at')
  final String createdAt;

  @ColumnInfo(name: 'updated_at')
  final String? updatedAt;

  // ✅ Sync flag (0 = not synced, 1 = synced)
  @ColumnInfo(name: 'is_synced')
  final int isSynced;

  const Category({
    required this.categoryId,
    required this.categoryName,
    required this.isActive,
    required this.createdAt,
    this.updatedAt,
    required this.isSynced,
  });

  Category copyWith({
    String? categoryId,
    String? categoryName,
    int? isActive,
    String? createdAt,
    String? updatedAt,
    int? isSynced,
  }) {
    return Category(
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}
