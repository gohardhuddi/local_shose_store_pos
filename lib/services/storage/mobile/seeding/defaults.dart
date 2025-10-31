import '../app_database.dart';
import '../entities/category.dart';
import '../entities/gender.dart';

Future<void> seedDefaultData(AppDatabase db) async {
  final now = DateTime.now().toIso8601String();

  // Check if categories exist
  final existingCategories = await db.categoryDao.all();
  if (existingCategories.isEmpty) {
    final defaultCategories = ["Jogger", "Sandal", "Flat", "Chapel", "Shoes"]
        .map((name) {
          return Category(
            categoryId: DateTime.now().microsecondsSinceEpoch.toString() + name,
            categoryName: name,
            isActive: 1,
            createdAt: now,
            updatedAt: now,
            isSynced: 0,
          );
        })
        .toList();
    for (final c in defaultCategories) {
      await db.categoryDao.insertCategory(c);
    }
  }

  // Check if genders exist
  final existingGenders = await db.genderDao.all();
  if (existingGenders.isEmpty) {
    final defaultGenders = ["Men", "Women", "Boys", "Girls", "Unisex"].map((
      name,
    ) {
      return Gender(
        genderId: DateTime.now().microsecondsSinceEpoch.toString() + name,
        genderName: name,
        isActive: 1,
        createdAt: now,
        updatedAt: now,
        isSynced: 0,
      );
    }).toList();
    for (final g in defaultGenders) {
      await db.genderDao.insertGender(g);
    }
  }
}
