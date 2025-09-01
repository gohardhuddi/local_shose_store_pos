import 'package:floor/floor.dart';

import '../entities/product_variants.dart';

@dao
abstract class ProductVariantDao {
  @insert
  Future<int> insertVariant(ProductVariant v);

  @update
  Future<int> updateVariant(ProductVariant v);

  @Query(
    'SELECT * FROM product_variants WHERE product_variant_id = :id LIMIT 1',
  )
  Future<ProductVariant?> findById(int id);

  @Query('SELECT * FROM product_variants WHERE product_variant_id = :id')
  Future<List<ProductVariant>> findByVariantId(int id);

  @Query('SELECT * FROM product_variants WHERE sku = :sku LIMIT 1')
  Future<ProductVariant?> findBySku(String sku);

  @Query(
    'SELECT COUNT(*) FROM product_variants WHERE product_id = :productId AND is_active = 1',
  )
  Future<int?> countActiveByProductId(int productId);

  @Query(
    'UPDATE product_variants SET is_synced = 1 WHERE product_variant_id = :id',
  )
  Future<void> markSynced(int id);

  @Query(
    'UPDATE product_variants SET is_active = :active, updated_at = :updatedAt, is_synced = 0 WHERE product_variant_id = :id',
  )
  Future<void> setActive(int id, int active, String updatedAt);

  @Query(
    'UPDATE product_variants SET is_active = 0, updated_at = :updatedAt, is_synced = 0 WHERE product_variant_id = :id',
  )
  Future<void> softDelete(int id, String updatedAt);

  @Query('DELETE FROM product_variants WHERE product_variant_id = :id')
  Future<void> deleteById(int id);

  @Query('SELECT * FROM product_variants WHERE is_synced = 0')
  Future<List<ProductVariant>> findUnsynced();

  @Query('SELECT * FROM product_variants')
  Future<List<ProductVariant>> all();

  @Query('SELECT * FROM product_variants WHERE product_id = :productId')
  Future<List<ProductVariant>> findByProductId(int productId);
  // Look up by SKU (case-insensitive) — no extra column needed
  @Query('SELECT * FROM product_variants WHERE lower(sku) = :skuLower LIMIT 1')
  Future<List<ProductVariant>> findBySkuLower(String skuLower);
}
