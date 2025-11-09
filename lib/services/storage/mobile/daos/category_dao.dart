import 'package:floor/floor.dart';

import '../entities/category.dart';

@dao
abstract class CategoryDao {
  @insert
  Future<void> insertCategory(Category c);

  @update
  Future<int> updateCategory(Category c);

  @delete
  Future<void> deleteCategory(Category c);

  @Query('SELECT * FROM categories WHERE category_id = :id LIMIT 1')
  Future<Category?> findById(String id);

  @Query('SELECT * FROM categories WHERE category_name = :name LIMIT 1')
  Future<Category?> findByName(String name);

  @Query('SELECT * FROM categories')
  Future<List<Category>> all();

  @Query('SELECT * FROM categories WHERE is_active = 1')
  Future<List<Category>> findActive();

  @Query('SELECT * FROM categories WHERE is_synced = 0')
  Future<List<Category>> findUnsynced();

  @Query('UPDATE categories SET is_synced = 1 WHERE category_id = :id')
  Future<void> markSynced(String id);

  @Query(
    'UPDATE categories SET is_active = :active, updated_at = :updatedAt WHERE category_id = :id',
  )
  Future<void> setActive(String id, int active, String updatedAt);
}
