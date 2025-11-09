import 'package:floor/floor.dart';

import '../entities/products.dart';

@dao
abstract class ProductDao {
  // Insert a new product
  @insert
  Future<void> insertProduct(Product p);

  // Update an existing product
  @update
  Future<int> updateProduct(Product p);

  // Find a product by its unique article code
  @Query('SELECT * FROM products WHERE article_code = :articleCode LIMIT 1')
  Future<Product?> findByArticleCode(String articleCode);

  // Get all products
  @Query('SELECT * FROM products')
  Future<List<Product>> all();

  // Get all unsynced products
  @Query('SELECT * FROM products WHERE is_synced = 0')
  Future<List<Product>> findUnsynced();

  // ✅ Correct type: product_id is String, not int
  @Query('UPDATE products SET is_synced = 1 WHERE product_id = :id')
  Future<void> markSynced(String id);

  // Set product active/inactive
  @Query(
    'UPDATE products SET is_active = :active, updated_at = :updatedAt WHERE product_id = :id',
  )
  Future<void> setActive(String id, int active, String updatedAt);

  // 🔍 Optional filters (useful for shoe store UI filters)
  @Query('SELECT * FROM products WHERE category_id = :categoryId')
  Future<List<Product>> findByCategory(String categoryId);

  @Query('SELECT * FROM products WHERE gender_id = :genderId')
  Future<List<Product>> findByGender(String genderId);
}
