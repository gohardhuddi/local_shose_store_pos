import 'package:sembast_web/sembast_web.dart';

import 'stock_db.dart';

class StockDbWeb implements StockDb {
  late final Database _db;
  final _products = intMapStoreFactory.store('products');
  final _variants = intMapStoreFactory.store('product_variants');

  @override
  Future<void> init() async {
    final factory = databaseFactoryWeb; // IndexedDB
    _db = await factory.openDatabase('shoe_pos_web.db');
  }

  @override
  Future<String> upsertProduct({
    required String brand,
    required String articleCode,
    String? articleName,
  }) async {
    final finder = Finder(filter: Filter.equals('article_code', articleCode));
    final now = DateTime.now().toIso8601String();

    final existing = await _products.findFirst(_db, finder: finder);
    if (existing != null) {
      await _products.record(existing.key).update(_db, {
        'brand': brand,
        'article_name': articleName,
        'updated_at': now,
        'is_active': 1,
      });
      return existing.key.toString();
    }

    final key = await _products.add(_db, {
      'brand': brand,
      'article_code': articleCode,
      'article_name': articleName,
      'is_active': 1,
      'created_at': now,
      'updated_at': now,
    });
    return key.toString();
  }

  @override
  Future<String> upsertVariant({
    required String productId,
    required int sizeEu,
    required String colorName,
    String? colorHex,
    required String sku,
    required int quantity,
    required double purchasePrice,
    double? salePrice,
  }) async {
    final now = DateTime.now().toIso8601String();

    final existing = await _variants.findFirst(
      _db,
      finder: Finder(filter: Filter.equals('sku', sku)),
    );

    if (existing != null) {
      await _variants.record(existing.key).update(_db, {
        'product_id': productId,
        'size_eu': sizeEu,
        'color_name': colorName,
        'color_hex': colorHex,
        'quantity': quantity,
        'purchase_price': purchasePrice,
        'sale_price': salePrice,
        'updated_at': now,
        'is_active': 1,
        'is_synced': 0,
      });
      return existing.key.toString();
    }

    final key = await _variants.add(_db, {
      'product_id': productId,
      'size_eu': sizeEu,
      'color_name': colorName,
      'color_hex': colorHex,
      'sku': sku,
      'quantity': quantity,
      'purchase_price': purchasePrice,
      'sale_price': salePrice,
      'created_at': now,
      'updated_at': now,
      'is_active': 1,
      'is_synced': 0,
    });
    return key.toString();
  }

  @override
  Future<List<Map<String, dynamic>>> getAllProducts() async {
    final records = await _products.find(_db);
    return records.map((r) => {'id': r.key, ...r.value}).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> getAllVariants() async {
    final records = await _variants.find(_db);
    return records.map((r) => {'id': r.key, ...r.value}).toList();
  }
}
