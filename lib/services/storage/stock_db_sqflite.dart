import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'stock_db.dart';

class StockDbSqflite implements StockDb {
  Database? _db;
  Database get db => _db!;

  @override
  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, 'shoe_pos.db');
    _db = await openDatabase(
      path,
      version: 1,
      onConfigure: (d) async => await d.execute('PRAGMA foreign_keys = ON;'),
      onCreate: (d, v) async {
        await d.execute('''
CREATE TABLE products (
  product_id     INTEGER PRIMARY KEY AUTOINCREMENT,
  brand          TEXT NOT NULL,
  article_code   TEXT NOT NULL UNIQUE,
  article_name   TEXT,
  notes          TEXT,
  is_active      INTEGER NOT NULL DEFAULT 1,
  created_at     TEXT NOT NULL,
  updated_at     TEXT NOT NULL
);
''');

        await d.execute('''
CREATE TABLE product_variants (
  product_variant_id INTEGER PRIMARY KEY AUTOINCREMENT,
  product_id         INTEGER NOT NULL,
  size_eu            INTEGER NOT NULL,
  color_name         TEXT NOT NULL,
  color_hex          TEXT,
  sku                TEXT NOT NULL UNIQUE,
  quantity           INTEGER NOT NULL DEFAULT 0,
  purchase_price     REAL NOT NULL DEFAULT 0,
  sale_price         REAL,
  is_active          INTEGER NOT NULL DEFAULT 1,
  is_synced          INTEGER NOT NULL DEFAULT 0,
  created_at         TEXT NOT NULL,
  updated_at         TEXT NOT NULL,
  FOREIGN KEY(product_id) REFERENCES products(product_id) ON DELETE CASCADE
);
''');

        await d.execute(
          'CREATE INDEX idx_variants_product ON product_variants(product_id);',
        );
        await d.execute(
          'CREATE INDEX idx_variants_sku ON product_variants(sku);',
        );
      },
    );
  }

  @override
  Future<String> upsertProduct({
    required String brand,
    required String articleCode,
    String? articleName,
  }) async {
    final now = DateTime.now().toIso8601String();
    final existing = await db.query(
      'products',
      columns: ['product_id'],
      where: 'article_code = ?',
      whereArgs: [articleCode],
      limit: 1,
    );

    if (existing.isNotEmpty) {
      final id = existing.first['product_id'].toString();
      await db.update(
        'products',
        {
          'brand': brand,
          'article_name': articleName,
          'updated_at': now,
          'is_active': 1,
        },
        where: 'product_id = ?',
        whereArgs: [id],
      );
      return id;
    }

    final id = await db.insert('products', {
      'brand': brand,
      'article_code': articleCode,
      'article_name': articleName,
      'is_active': 1,
      'created_at': now,
      'updated_at': now,
    });
    return id.toString();
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

    final existing = await db.query(
      'product_variants',
      columns: ['product_variant_id'],
      where: 'sku = ?',
      whereArgs: [sku],
      limit: 1,
    );

    if (existing.isNotEmpty) {
      final id = existing.first['product_variant_id'].toString();
      await db.update(
        'product_variants',
        {
          'product_id': int.parse(productId),
          'size_eu': sizeEu,
          'color_name': colorName,
          'color_hex': colorHex,
          'quantity': quantity,
          'purchase_price': purchasePrice,
          'sale_price': salePrice,
          'updated_at': now,
          'is_active': 1,
          'is_synced': 0,
        },
        where: 'product_variant_id = ?',
        whereArgs: [id],
      );
      return id;
    }

    final id = await db.insert('product_variants', {
      'product_id': int.parse(productId),
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
    return id.toString();
  }

  @override
  Future<List<Map<String, dynamic>>> getAllProducts() async {
    return await db.query('products');
  }

  @override
  Future<List<Map<String, dynamic>>> getAllVariants() async {
    return await db.query('product_variants');
  }
}
