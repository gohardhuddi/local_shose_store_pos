import '../app_database.dart';
import '../entities/category.dart';
import '../entities/gender.dart';

Future<void> seedDefaultData(AppDatabase db) async {
  final now = DateTime.now().toIso8601String();

  // 🟢 Seed default categories
  final existingCategories = await db.categoryDao.all();
  if (existingCategories.isEmpty) {
    // Use fixed UUIDs to avoid duplicates across restarts
    final defaultCategories = <String, String>{
      'Jogger': '00000000-0000-0000-0000-000000000001',
      'Sandal': '00000000-0000-0000-0000-000000000002',
      'Flat': '00000000-0000-0000-0000-000000000003',
      'Chapel': '00000000-0000-0000-0000-000000000004',
      'Shoes': '00000000-0000-0000-0000-000000000005',
    };

    for (final entry in defaultCategories.entries) {
      await db.categoryDao.insertCategory(
        Category(
          categoryId: entry.value,
          categoryName: entry.key,
          isActive: 1,
          createdAt: now,
          updatedAt: now,
          isSynced: 0,
        ),
      );
    }
    print("✅ Default categories seeded (${defaultCategories.length})");
  } else {
    print("ℹ️ Categories already exist, skipping seeding.");
  }

  // 🟣 Seed default genders
  final existingGenders = await db.genderDao.all();
  if (existingGenders.isEmpty) {
    final defaultGenders = <String, String>{
      'Male': '11111111-1111-1111-1111-111111111111',
      'Female': '22222222-2222-2222-2222-222222222222',
      'Boy': '33333333-3333-3333-3333-333333333333',
      'Girl': '44444444-4444-4444-4444-444444444444',
      'Unisex': '55555555-5555-5555-5555-555555555555',
      'Kids': '66666666-6666-6666-6666-666666666666',
    };

    for (final entry in defaultGenders.entries) {
      await db.genderDao.insertGender(
        Gender(
          genderId: entry.value,
          genderName: entry.key,
          isActive: 1,
          createdAt: now,
          updatedAt: now,
          isSynced: 0,
        ),
      );
    }
    print("✅ Default genders seeded (${defaultGenders.length})");
  } else {
    print("ℹ️ Genders already exist, skipping seeding.");
  }
}
