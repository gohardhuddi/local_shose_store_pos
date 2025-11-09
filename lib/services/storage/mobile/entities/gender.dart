import 'package:floor/floor.dart';

@Entity(
  tableName: 'genders',
  indices: [
    Index(value: ['gender_name'], unique: true),
  ],
)
class Gender {
  @primaryKey
  @ColumnInfo(name: 'gender_id')
  final String genderId; // UUID or custom string ID

  @ColumnInfo(name: 'gender_name')
  final String genderName; // e.g. Men, Women, Boys, Girls, Unisex

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

  const Gender({
    required this.genderId,
    required this.genderName,
    required this.isActive,
    required this.createdAt,
    this.updatedAt,
    required this.isSynced,
  });

  Gender copyWith({
    String? genderId,
    String? genderName,
    int? isActive,
    String? createdAt,
    String? updatedAt,
    int? isSynced,
  }) {
    return Gender(
      genderId: genderId ?? this.genderId,
      genderName: genderName ?? this.genderName,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}
