import 'dart:convert';

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
      version: 4, // bumped to 4 for inventory_movement table
      onConfigure: (d) async => await d.execute('PRAGMA foreign_keys = ON;'),
      onCreate: (d, v) async {
        await d.execute('''
CREATE TABLE inventory_movements (
  id           INTEGER PRIMARY KEY AUTOINCREMENT,
  movement_id  TEXT NOT NULL UNIQUE,
  sku          TEXT NOT NULL,
  quantity     INTEGER NOT NULL,
  action       TEXT NOT NULL, -- 'add' or 'subtract'
  date_time    TEXT NOT NULL,
  is_synced    INTEGER NOT NULL DEFAULT 0
);
''');
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

        await d.execute('''
CREATE TABLE inventory_movement (
  movement_id TEXT PRIMARY KEY,
  sku TEXT NOT NULL,
  quantity INTEGER NOT NULL,
  action TEXT NOT NULL CHECK (action IN ('add', 'subtract')),
  date_time TEXT NOT NULL,
  is_synced INTEGER NOT NULL DEFAULT 0
);
''');

        await d.execute(
          'CREATE INDEX idx_variants_product ON product_variants(product_id);',
        );
        await d.execute(
          'CREATE INDEX idx_variants_sku ON product_variants(sku);',
        );

        await _createVariantCleanupTriggers(d);
      },
      onUpgrade: (d, oldV, newV) async {
        if (oldV < 2) {
          await _createVariantCleanupTriggers(d);
        }
        if (oldV < 3) {
          await _createVariantCleanupTriggers(d);
        }
        if (oldV < 4) {
          await d.execute('''
CREATE TABLE IF NOT EXISTS inventory_movement (
  movement_id TEXT PRIMARY KEY,
  sku TEXT NOT NULL,
  quantity INTEGER NOT NULL,
  action TEXT NOT NULL CHECK (action IN ('add', 'subtract')),
  date_time TEXT NOT NULL,
  is_synced INTEGER NOT NULL DEFAULT 0
);
''');
        }
      },
    );
  }

  Future<void> _createVariantCleanupTriggers(Database d) async {
    await d.execute(
      'CREATE INDEX IF NOT EXISTS idx_variants_product_active ON product_variants(product_id, is_active);',
    );

    await d.execute('''
CREATE TRIGGER IF NOT EXISTS trg_variant_after_delete_softdelete_product
AFTER DELETE ON product_variants
BEGIN
  UPDATE products
     SET is_active = 0,
         updated_at = strftime('%Y-%m-%dT%H:%M:%fZ','now')
   WHERE products.product_id = OLD.product_id
     AND is_active <> 0
     AND NOT EXISTS (
       SELECT 1 FROM product_variants v
        WHERE v.product_id = OLD.product_id
          AND v.is_active = 1
     );
END;
''');

    await d.execute('''
CREATE TRIGGER IF NOT EXISTS trg_variant_after_softdelete_softdelete_product
AFTER UPDATE OF is_active ON product_variants
WHEN NEW.is_active = 0 AND OLD.is_active <> 0
BEGIN
  UPDATE products
     SET is_active = 0,
         updated_at = strftime('%Y-%m-%dT%H:%M:%fZ','now')
   WHERE products.product_id = NEW.product_id
     AND is_active <> 0
     AND NOT EXISTS (
       SELECT 1 FROM product_variants v
        WHERE v.product_id = NEW.product_id
          AND v.is_active = 1
     );
END;
''');

    await d.execute('''
CREATE TRIGGER IF NOT EXISTS trg_variant_after_insert_reactivate_product
AFTER INSERT ON product_variants
WHEN NEW.is_active = 1
BEGIN
  UPDATE products
     SET is_active = 1,
         updated_at = strftime('%Y-%m-%dT%H:%M:%fZ','now')
   WHERE products.product_id = NEW.product_id
     AND is_active <> 1;
END;
''');

    await d.execute('''
CREATE TRIGGER IF NOT EXISTS trg_variant_after_reactivate_product
AFTER UPDATE OF is_active ON product_variants
WHEN NEW.is_active = 1 AND OLD.is_active <> 1
BEGIN
  UPDATE products
     SET is_active = 1,
         updated_at = strftime('%Y-%m-%dT%H:%M:%fZ','now')
   WHERE products.product_id = NEW.product_id
     AND is_active <> 1;
END;
''');
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
    required int quantity, // still required but ignored in DB
    required double purchasePrice,
    double? salePrice,
    bool? isEdit, // if true -> replace qty, else add (ignored now)
  }) async {
    final now = DateTime.now().toIso8601String();

    return await db.transaction((txn) async {
      final existing = await txn.query(
        'product_variants',
        columns: ['product_variant_id'],
        where: 'sku = ?',
        whereArgs: [sku],
        limit: 1,
      );

      if (existing.isNotEmpty) {
        final id = existing.first['product_variant_id'].toString();

        await txn.rawUpdate(
          '''
      UPDATE product_variants
         SET product_id     = ?,
             size_eu        = ?,
             color_name     = ?,
             color_hex      = ?,
             quantity       = ?,  -- hardcoded to 0
             purchase_price = ?,
             sale_price     = ?,
             updated_at     = ?,
             is_active      = 1,
             is_synced      = 0
       WHERE product_variant_id = ?
      ''',
          [
            int.parse(productId),
            sizeEu,
            colorName,
            colorHex,
            0, // 👈 hardcoded quantity = 0
            purchasePrice,
            salePrice,
            now,
            id,
          ],
        );
        return id;
      }

      // Not found -> insert
      final newId = await txn.insert('product_variants', {
        'product_id': int.parse(productId),
        'size_eu': sizeEu,
        'color_name': colorName,
        'color_hex': colorHex,
        'sku': sku,
        'quantity': 0, // 👈 hardcoded quantity = 0
        'purchase_price': purchasePrice,
        'sale_price': salePrice,
        'created_at': now,
        'updated_at': now,
        'is_active': 1,
        'is_synced': 0,
      });
      return newId.toString();
    });
  }

  @override
  Future<List<Map<String, dynamic>>> getAllProducts() async {
    return await db.query('products');
  }

  @override
  Future<List<Map<String, dynamic>>> getAllVariants() async {
    return await db.query('product_variants');
  }

  @override
  Future<String> getAllStock() async {
    final now = DateTime.now().toIso8601String();

    return await db.transaction((txn) async {
      // 1) soft-deactivate products that have zero ACTIVE variants
      await txn.rawUpdate(
        '''
      UPDATE products AS p
         SET is_active = 0,
             updated_at = ?
       WHERE is_active <> 0
         AND NOT EXISTS (
           SELECT 1
             FROM product_variants v
            WHERE v.product_id = p.product_id
              AND v.is_active = 1
         )
    ''',
        [now],
      );

      // 2) query ONLY active products with at least one ACTIVE variant
      final rows = await txn.rawQuery('''
      SELECT
        p.product_id         AS p_id,
        p.brand              AS p_brand,
        p.article_code       AS p_code,
        p.article_name       AS p_name,
        p.is_active          AS p_active,
        p.created_at         AS p_created,
        p.updated_at         AS p_updated,

        v.product_variant_id AS v_id,
        v.sku                AS v_sku,
        v.size_eu            AS v_size,
        v.color_name         AS v_color_name,
        v.color_hex          AS v_color_hex,
        v.quantity           AS v_qty,
        v.purchase_price     AS v_purchase,
        v.sale_price         AS v_sale,
        v.is_active          AS v_active,
        v.is_synced          AS v_synced,
        v.created_at         AS v_created,
        v.updated_at         AS v_updated
      FROM products p
      JOIN product_variants v
        ON v.product_id = p.product_id
       AND v.is_active = 1
      WHERE p.is_active = 1
      ORDER BY p.article_code ASC, v.sku ASC
    ''');

      // 3) group by product, attach variants
      final byId = <String, Map<String, dynamic>>{};
      for (final r in rows) {
        final pid = r['p_id'].toString();
        final product = byId.putIfAbsent(
          pid,
          () => {
            'productId': pid,
            'brand': (r['p_brand'] ?? '').toString(),
            'articleCode': (r['p_code'] ?? '').toString(),
            'articleName': (r['p_name'] ?? '').toString(),
            'isActive': true, // filtered above
            'createdAt': r['p_created'],
            'updatedAt': r['p_updated'],
            'totalQty': 0,
            'variantCount': 0,
            'variants': <Map<String, dynamic>>[],
          },
        );

        final vQty = (r['v_qty'] as int?) ?? 0;
        final variant = {
          'variantId': r['v_id'].toString(),
          'sku': (r['v_sku'] ?? '').toString(),
          'size': r['v_size'],
          'colorName': (r['v_color_name'] ?? '').toString(),
          'colorHex': r['v_color_hex'],
          'qty': vQty,
          'purchasePrice': (r['v_purchase'] as num?)?.toDouble(),
          'salePrice': (r['v_sale'] as num?)?.toDouble(),
          'isActive': true, // filtered above
          'isSynced': (r['v_synced'] ?? 0) == 1,
          'createdAt': r['v_created'],
          'updatedAt': r['v_updated'],
        };

        (product['variants'] as List).add(variant);
        product['totalQty'] = (product['totalQty'] as int) + vQty;
        product['variantCount'] = (product['variantCount'] as int) + 1;
      }

      final list = byId.values.toList()
        ..sort(
          (a, b) => (a['articleCode'] as String).compareTo(
            b['articleCode'] as String,
          ),
        );

      return jsonEncode(list);
    });
  }

  /// Delete a variant by its primary key.
  /// - hard == false: Soft delete (is_active = 0, updated_at, is_synced = 0).
  /// - hard == true : Hard delete (row removed).
  /// Triggers will soft-delete the product when the last ACTIVE variant is gone.
  @override
  Future<bool> deleteVariantById(String variantId, {bool hard = false}) async {
    final key = int.tryParse(variantId);
    if (key == null) return false;

    if (hard) {
      final deleted = await db.delete(
        'product_variants',
        where: 'product_variant_id = ?',
        whereArgs: [key],
      );
      return deleted > 0;
    } else {
      final now = DateTime.now().toIso8601String();
      final updated = await db.update(
        'product_variants',
        {'is_active': 0, 'updated_at': now, 'is_synced': 0},
        where: 'product_variant_id = ?',
        whereArgs: [key],
      );
      return updated > 0;
    }
  }

  // Add inventory movement
  Future<String> addInventoryMovement({
    required String movementId,
    required String sku,
    required int quantity,
    required String action, // 'add' or 'subtract'
    required String dateTime,
    bool isSynced = false,
  }) async {
    final id = await db.insert('inventory_movements', {
      'movement_id': movementId,
      'sku': sku,
      'quantity': quantity,
      'action': action,
      'date_time': dateTime,
      'is_synced': isSynced ? 1 : 0,
    });
    return id.toString();
  }

  // Get unsynced inventory movements
  Future<List<Map<String, dynamic>>> getUnsyncedInventoryMovements() async {
    return await db.query(
      'inventory_movements',
      where: 'is_synced = ?',
      whereArgs: [0],
    );
  }

  // Mark a movement as synced
  Future<bool> markInventoryMovementSynced(String movementId) async {
    final updated = await db.update(
      'inventory_movements',
      {'is_synced': 1},
      where: 'movement_id = ?',
      whereArgs: [movementId],
    );
    return updated > 0;
  }
}
