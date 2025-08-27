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
      version: 6, // v6 adds products.is_synced
      onConfigure: (d) async => await d.execute('PRAGMA foreign_keys = ON;'),
      onCreate: (d, v) async {
        // ---- Core tables
        await d.execute('''
CREATE TABLE products (
  product_id     INTEGER PRIMARY KEY AUTOINCREMENT,
  brand          TEXT NOT NULL,
  article_code   TEXT NOT NULL UNIQUE,
  article_name   TEXT,
  notes          TEXT,
  is_active      INTEGER NOT NULL DEFAULT 1,
  is_synced      INTEGER NOT NULL DEFAULT 0,
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

        // ---- Single source of truth for movements (by variant id)
        await d.execute('''
CREATE TABLE inventory_movements (
  movement_id        TEXT PRIMARY KEY,
  product_variant_id INTEGER NOT NULL,
  quantity           INTEGER NOT NULL CHECK (quantity > 0),
  action             TEXT NOT NULL CHECK (action IN ('add','subtract')),
  date_time          TEXT NOT NULL,
  is_synced          INTEGER NOT NULL DEFAULT 0,
  FOREIGN KEY(product_variant_id) REFERENCES product_variants(product_variant_id) ON DELETE CASCADE
);
''');

        // ---- Indexes
        await d.execute(
          'CREATE INDEX idx_variants_product ON product_variants(product_id);',
        );
        await d.execute(
          'CREATE INDEX idx_variants_active ON product_variants(product_id, is_active);',
        );
        await d.execute(
          'CREATE INDEX idx_movements_variant ON inventory_movements(product_variant_id);',
        );

        await _createVariantCleanupTriggers(d);
      },
      onUpgrade: (d, oldV, newV) async {
        // Ensure base tables exist
        await d.execute('''
CREATE TABLE IF NOT EXISTS products (
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
CREATE TABLE IF NOT EXISTS product_variants (
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

        // v5 introduced corrected movements schema
        if (oldV < 5) {
          await d.execute('''
CREATE TABLE IF NOT EXISTS inventory_movements (
  movement_id        TEXT PRIMARY KEY,
  product_variant_id INTEGER NOT NULL,
  quantity           INTEGER NOT NULL CHECK (quantity > 0),
  action             TEXT NOT NULL CHECK (action IN ('add','subtract')),
  date_time          TEXT NOT NULL,
  is_synced          INTEGER NOT NULL DEFAULT 0,
  FOREIGN KEY(product_variant_id) REFERENCES product_variants(product_variant_id) ON DELETE CASCADE
);
''');
          await d.execute(
            'CREATE INDEX IF NOT EXISTS idx_movements_variant ON inventory_movements(product_variant_id);',
          );
        }

        // v6 adds products.is_synced
        if (oldV < 6) {
          // Only add if not present. SQLite lacks easy IF NOT EXISTS for columns,
          // but ALTER will fail harmlessly if column already exists in our controlled versions.
          await d.execute(
            "ALTER TABLE products ADD COLUMN is_synced INTEGER NOT NULL DEFAULT 0;",
          );
        }

        await d.execute(
          'CREATE INDEX IF NOT EXISTS idx_variants_product ON product_variants(product_id);',
        );
        await d.execute(
          'CREATE INDEX IF NOT EXISTS idx_variants_active ON product_variants(product_id, is_active);',
        );

        await _createVariantCleanupTriggers(d);
      },
    );
  }

  Future<void> _createVariantCleanupTriggers(Database d) async {
    // When last active variant for a product disappears, deactivate product
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

  // -------------------------
  // Products
  // -------------------------
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
          'is_synced': 0, // mark dirty on update
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
      'is_synced': 0, // track sync state on create
      'created_at': now,
      'updated_at': now,
    });
    return id.toString();
  }

  // -------------------------
  // Variants (create/update)
  // -------------------------
  @override
  Future<String> upsertVariant({
    required String productId,
    String? variantID, // when provided, update by this PK; else insert
    required int sizeEu,
    required String colorName,
    String? colorHex,
    required String sku, // unique
    required int quantity,
    required double purchasePrice,
    double? salePrice,
    bool? isEdit, // if true: set quantity exactly; else add to current
  }) async {
    final now = DateTime.now().toIso8601String();

    return await db.transaction((txn) async {
      Map<String, Object?>? row;
      String? existingId;

      if (variantID != null) {
        final q = await txn.query(
          'product_variants',
          where: 'product_variant_id = ?',
          whereArgs: [int.tryParse(variantID)],
          limit: 1,
        );
        if (q.isNotEmpty) {
          row = q.first;
          existingId = row['product_variant_id'].toString();
        }
      } else {
        final q = await txn.query(
          'product_variants',
          where: 'sku = ?',
          whereArgs: [sku],
          limit: 1,
        );
        if (q.isNotEmpty) {
          row = q.first;
          existingId = row['product_variant_id'].toString();
        }
      }

      if (existingId != null) {
        // Update existing
        final currentQty = (row?['quantity'] as int?) ?? 0;
        final nextQty = (isEdit == true) ? quantity : (currentQty + quantity);

        await txn.update(
          'product_variants',
          {
            'product_id': int.parse(productId),
            'size_eu': sizeEu,
            'color_name': colorName,
            'color_hex': colorHex,
            'sku': sku,
            'quantity': nextQty,
            'purchase_price': purchasePrice,
            'sale_price': salePrice,
            'updated_at': now,
            'is_active': 1,
            'is_synced': 0,
          },
          where: 'product_variant_id = ?',
          whereArgs: [int.parse(existingId)],
        );

        await _recomputeProductActiveTx(txn, productId);
        return existingId;
      }

      // Insert new
      final newId = await txn.insert('product_variants', {
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

      await _recomputeProductActiveTx(txn, productId);
      return newId.toString();
    });
  }

  // -------------------------
  // Movements (core primitive + helpers)
  // -------------------------

  /// Core primitive identical to Web version: apply a movement (idempotent).
  Future<String> addInventoryMovement({
    required String movementId,
    required String productVariantId, // variant PK (stringified int)
    required int quantity,
    required String action, // 'add' or 'subtract'
    required String dateTime,
    bool isSynced = false,
  }) async {
    final normalizedAction = action.toLowerCase().trim();
    final isAdd = normalizedAction == 'add';
    final isSubtract = normalizedAction == 'subtract';
    if (!isAdd && !isSubtract) {
      throw ArgumentError.value(
        action,
        'action',
        'Must be "add" or "subtract"',
      );
    }
    if (quantity <= 0) {
      throw ArgumentError.value(quantity, 'quantity', 'Must be > 0');
    }

    return await db.transaction((txn) async {
      // 1) idempotency
      final prior = await txn.query(
        'inventory_movements',
        columns: ['movement_id'],
        where: 'movement_id = ?',
        whereArgs: [movementId],
        limit: 1,
      );
      if (prior.isNotEmpty) return movementId;

      // 2) load variant
      final vid = int.tryParse(productVariantId);
      if (vid == null) throw ArgumentError('Invalid productVariantId');
      final v = await txn.query(
        'product_variants',
        where: 'product_variant_id = ?',
        whereArgs: [vid],
        limit: 1,
      );
      if (v.isEmpty) throw StateError('Variant not found: $productVariantId');

      final currentQty = (v.first['quantity'] as int?) ?? 0;
      final delta = isAdd ? quantity : -quantity;
      final newQty = currentQty + delta;
      if (newQty < 0) {
        throw StateError(
          'Insufficient stock for variant $productVariantId: current=$currentQty, subtract=$quantity',
        );
      }

      // 3) update variant
      final now = DateTime.now().toIso8601String();
      await txn.update(
        'product_variants',
        {'quantity': newQty, 'updated_at': now, 'is_synced': 0},
        where: 'product_variant_id = ?',
        whereArgs: [vid],
      );

      // 4) write movement
      await txn.insert('inventory_movements', {
        'movement_id': movementId,
        'product_variant_id': vid,
        'quantity': quantity,
        'action': isAdd ? 'add' : 'subtract',
        'date_time': dateTime,
        'is_synced': isSynced ? 1 : 0,
      });

      // 5) recompute product active
      final pid = (v.first['product_id'] ?? '').toString();
      if (pid.isNotEmpty) {
        await _recomputeProductActiveTx(txn, pid);
      }

      return movementId;
    });
  }

  /// Increase quantity (records a movement).
  Future<String> addStock({
    required String movementId,
    required String productVariantId,
    required int quantity,
    String? dateTimeIso,
    bool isSynced = false,
  }) {
    return addInventoryMovement(
      movementId: movementId,
      productVariantId: productVariantId,
      quantity: quantity,
      action: 'add',
      dateTime: dateTimeIso ?? DateTime.now().toIso8601String(),
      isSynced: isSynced,
    );
  }

  /// Decrease quantity (records a movement).
  Future<String> subtractStock({
    required String movementId,
    required String productVariantId,
    required int quantity,
    String? dateTimeIso,
    bool isSynced = false,
  }) {
    return addInventoryMovement(
      movementId: movementId,
      productVariantId: productVariantId,
      quantity: quantity,
      action: 'subtract',
      dateTime: dateTimeIso ?? DateTime.now().toIso8601String(),
      isSynced: isSynced,
    );
  }

  /// Edit metadata and/or set quantity exactly; logs movement if qty changed.
  Future<void> editStock({
    required String productVariantId,
    String? productId,
    int? sizeEu,
    String? colorName,
    String? colorHex,
    String? sku,
    double? purchasePrice,
    double? salePrice,
    int? newQuantity,
    String? movementId,
    String? dateTimeIso,
    bool isSynced = false,
  }) async {
    final now = DateTime.now().toIso8601String();
    final when = dateTimeIso ?? now;

    await db.transaction((txn) async {
      final vid = int.tryParse(productVariantId);
      if (vid == null) throw ArgumentError('Invalid productVariantId');

      final q = await txn.query(
        'product_variants',
        where: 'product_variant_id = ?',
        whereArgs: [vid],
        limit: 1,
      );
      if (q.isEmpty) throw StateError('Variant not found: $productVariantId');

      final data = q.first;
      final currentQty = (data['quantity'] as int?) ?? 0;

      int? delta;
      if (newQuantity != null) {
        if (newQuantity < 0) {
          throw ArgumentError.value(newQuantity, 'newQuantity', 'Must be >= 0');
        }
        delta = newQuantity - currentQty;
        if (currentQty + delta < 0) {
          throw StateError('Resulting quantity would be negative');
        }
      }

      final update = <String, Object?>{
        if (productId != null) 'product_id': int.parse(productId),
        if (sizeEu != null) 'size_eu': sizeEu,
        if (colorName != null) 'color_name': colorName,
        if (colorHex != null) 'color_hex': colorHex,
        if (sku != null) 'sku': sku,
        if (purchasePrice != null) 'purchase_price': purchasePrice,
        if (salePrice != null) 'sale_price': salePrice,
        if (newQuantity != null) 'quantity': newQuantity,
        'updated_at': now,
        'is_synced': 0,
        'is_active': 1,
      };

      await txn.update(
        'product_variants',
        update,
        where: 'product_variant_id = ?',
        whereArgs: [vid],
      );

      if (delta != null && delta != 0) {
        final id =
            movementId ?? DateTime.now().microsecondsSinceEpoch.toString();
        final action = delta > 0 ? 'add' : 'subtract';
        final magnitude = delta.abs();

        final prior = await txn.query(
          'inventory_movements',
          columns: ['movement_id'],
          where: 'movement_id = ?',
          whereArgs: [id],
          limit: 1,
        );
        if (prior.isEmpty) {
          await txn.insert('inventory_movements', {
            'movement_id': id,
            'product_variant_id': vid,
            'quantity': magnitude,
            'action': action,
            'date_time': when,
            'is_synced': isSynced ? 1 : 0,
          });
        }
      }

      final pidForRecompute = (update['product_id'] ?? data['product_id'])
          .toString();
      await _recomputeProductActiveTx(txn, pidForRecompute);
    });
  }

  // ---- Movement sync helpers
  Future<List<Map<String, dynamic>>> getUnsyncedMovements() async {
    return await db.query('inventory_movements', where: 'is_synced = 0');
    // returns: movement_id, product_variant_id, quantity, action, date_time, is_synced
  }

  Future<void> markMovementSynced(String movementId) async {
    await db.update(
      'inventory_movements',
      {'is_synced': 1},
      where: 'movement_id = ?',
      whereArgs: [movementId],
    );
  }

  // ---- Product/Variant sync helpers (parity with Web)
  Future<List<Map<String, dynamic>>> getUnsyncedProducts({
    bool onlyActive = true,
  }) async {
    if (onlyActive) {
      return await db.query(
        'products',
        where: 'is_synced = 0 AND is_active = 1',
      );
    }
    return await db.query('products', where: 'is_synced = 0');
  }

  Future<List<Map<String, dynamic>>> getUnsyncedVariants({
    bool onlyActive = true,
  }) async {
    if (onlyActive) {
      return await db.query(
        'product_variants',
        where: 'is_synced = 0 AND is_active = 1',
      );
    }
    return await db.query('product_variants', where: 'is_synced = 0');
  }

  Future<void> markProductSynced(String productId) async {
    final pid = int.tryParse(productId);
    if (pid == null) throw ArgumentError('Invalid productId');
    await db.update(
      'products',
      {'is_synced': 1},
      where: 'product_id = ?',
      whereArgs: [pid],
    );
  }

  Future<void> markVariantSynced(String productVariantId) async {
    final vid = int.tryParse(productVariantId);
    if (vid == null) throw ArgumentError('Invalid productVariantId');
    await db.update(
      'product_variants',
      {'is_synced': 1},
      where: 'product_variant_id = ?',
      whereArgs: [vid],
    );
  }

  /// Bundle everything unsynced: products, variants, movements.
  Future<Map<String, dynamic>> getUnsyncedPayload({
    bool onlyActive = false,
  }) async {
    final products = await getUnsyncedProducts(onlyActive: onlyActive);
    final variants = await getUnsyncedVariants(onlyActive: onlyActive);
    final movements = await getUnsyncedMovements();
    return {'products': products, 'variants': variants, 'movements': movements};
  }

  // -------------------------
  // Queries / Reporting
  // -------------------------
  @override
  Future<List<Map<String, dynamic>>> getAllProducts() async {
    return await db.query('products');
  }

  @override
  Future<List<Map<String, dynamic>>> getAllVariants() async {
    return await db.query('product_variants');
  }

  /// Alias to match the Web API shape
  Future<String> getStockJson() => getAllStock();

  @override
  Future<String> getAllStock() async {
    final rows = await db.rawQuery('''
      SELECT
        p.product_id         AS p_id,
        p.brand              AS p_brand,
        p.article_code       AS p_code,
        p.article_name       AS p_name,
        p.is_active          AS p_active,
        p.is_synced          AS p_synced,
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
          'isActive': (r['p_active'] ?? 1) == 1,
          'isSynced': (r['p_synced'] ?? 0) == 1,
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
        'isActive': (r['v_active'] ?? 1) == 1,
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
        (a, b) =>
            (a['articleCode'] as String).compareTo(b['articleCode'] as String),
      );

    return jsonEncode(list);
  }

  // -------------------------
  // Deletes
  // -------------------------
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

  // -------------------------
  // Internal helpers
  // -------------------------
  Future<void> _recomputeProductActiveTx(
    Transaction txn,
    String productIdStr,
  ) async {
    final pid = int.tryParse(productIdStr);
    if (pid == null) return;

    final cnt =
        Sqflite.firstIntValue(
          await txn.rawQuery(
            'SELECT COUNT(*) FROM product_variants WHERE product_id = ? AND is_active = 1',
            [pid],
          ),
        ) ??
        0;

    final now = DateTime.now().toIso8601String();
    await txn.update(
      'products',
      {'is_active': cnt > 0 ? 1 : 0, 'updated_at': now},
      where: 'product_id = ?',
      whereArgs: [pid],
    );
  }

  Future<void> _recomputeProductActive(String productIdStr) async {
    await db.transaction(
      (txn) async => _recomputeProductActiveTx(txn, productIdStr),
    );
  }
}
