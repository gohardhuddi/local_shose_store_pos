import 'package:floor/floor.dart';

import '../entities/products.dart';

@dao
abstract class ProductDao {
  @insert
  Future<int> insertProduct(Product p);

  @update
  Future<int> updateProduct(Product p);

  @Query('SELECT * FROM products WHERE article_code = :articleCode LIMIT 1')
  Future<Product?> findByArticleCode(String articleCode);

  @Query('SELECT * FROM products')
  Future<List<Product>> all();

  @Query('SELECT * FROM products WHERE is_synced = 0')
  Future<List<Product>> findUnsynced();

  @Query('UPDATE products SET is_synced = 1 WHERE product_id = :id')
  Future<void> markSynced(int id);

  @Query(
    'UPDATE products SET is_active = :active, updated_at = :updatedAt WHERE product_id = :id',
  )
  Future<void> setActive(String id, int active, String updatedAt);
}
