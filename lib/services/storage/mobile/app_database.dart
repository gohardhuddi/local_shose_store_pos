import 'dart:async';

import 'package:floor/floor.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

import 'daos/movement_dao.dart';
import 'daos/product_dao.dart';
import 'daos/variant_dao.dart';
import 'entities/inventory_movement.dart';
import 'entities/product_variants.dart';
import 'entities/products.dart';

part 'app_database.g.dart';

// NOTE: Version 8 because we migrate inventory_movements to store SKU (TEXT) with FK to product_variants(sku)
@Database(version: 8, entities: [Product, ProductVariant, InventoryMovement])
abstract class AppDatabase extends FloorDatabase {
  ProductDao get productDao;
  ProductVariantDao get variantDao;
  InventoryMovementDao get movementDao;
}

Future<AppDatabase> openMobileDb(String path) {
  return $FloorAppDatabase.databaseBuilder(path).addMigrations([
    migration1to6,
    migration7to8, // migrate to SKU-based FK
  ]).build();
}

/// ----------------------------
/// 1 -> 6 bootstrap schema
/// ----------------------------
final migration1to6 = Migration(1, 6, (sqflite.DatabaseExecutor db) async {
  await db.execute('PRAGMA foreign_keys = ON;');

  await db.execute('''
CREATE TABLE IF NOT EXISTS products (
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

  await db.execute(
    'CREATE INDEX IF NOT EXISTS idx_products_article_code ON products(article_code);',
  );

  await db.execute('''
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

  await db.execute(
    'CREATE INDEX IF NOT EXISTS idx_variants_product ON product_variants(product_id);',
  );
  await db.execute(
    'CREATE INDEX IF NOT EXISTS idx_variants_active ON product_variants(product_id, is_active);',
  );

  // Original ID-based movements table (pre-8)
  await db.execute('''
CREATE TABLE IF NOT EXISTS inventory_movements (
  movement_id        TEXT PRIMARY KEY,
  product_variant_id INTEGER NOT NULL,
  quantity           INTEGER NOT NULL CHECK (quantity > 0),
  action             TEXT NOT NULL CHECK (
    action IN (
      'purchase_in',
      'sale_out',
      'return_in',
      'return_out',
      'transfer_in',
      'transfer_out',
      'adjustment_pos',
      'adjustment_neg',
      'damage',
      'stocktake_correction'
    )
  ),
  date_time          TEXT NOT NULL,
  is_synced          INTEGER NOT NULL DEFAULT 0,
  FOREIGN KEY(product_variant_id) REFERENCES product_variants(product_variant_id) ON DELETE CASCADE
);
''');

  await db.execute(
    'CREATE INDEX IF NOT EXISTS idx_movements_variant ON inventory_movements(product_variant_id);',
  );
});

/// ----------------------------
/// 7 -> 8: switch movements to SKU-based FK
/// ----------------------------
final migration7to8 = Migration(7, 8, (sqflite.DatabaseExecutor db) async {
  // Temporarily disable FKs while we transform the table
  await db.execute('PRAGMA foreign_keys = OFF;');

  // 1) Create new table keyed by SKU (TEXT) with a proper FK to product_variants(sku)
  await db.execute('''
CREATE TABLE inventory_movements_new (
  movement_id          TEXT PRIMARY KEY,
  product_variant_sku  TEXT NOT NULL,
  quantity             INTEGER NOT NULL CHECK (quantity > 0),
  action               TEXT NOT NULL CHECK (
    action IN (
      'purchase_in',
      'sale_out',
      'return_in',
      'return_out',
      'transfer_in',
      'transfer_out',
      'adjustment_pos',
      'adjustment_neg',
      'damage',
      'stocktake_correction'
    )
  ),
  date_time            TEXT NOT NULL,
  is_synced            INTEGER NOT NULL DEFAULT 0,
  FOREIGN KEY(product_variant_sku) REFERENCES product_variants(sku) ON DELETE CASCADE
);
''');

  // 2) Copy all existing rows, resolving SKU via JOIN on old integer FK
  await db.execute('''
INSERT INTO inventory_movements_new (
  movement_id, product_variant_sku, quantity, action, date_time, is_synced
)
SELECT
  m.movement_id,
  v.sku AS product_variant_sku,
  m.quantity,
  m.action,
  m.date_time,
  m.is_synced
FROM inventory_movements m
JOIN product_variants v
  ON v.product_variant_id = m.product_variant_id;
''');

  // 3) Replace old table with the new one
  await db.execute('DROP TABLE inventory_movements;');
  await db.execute(
    'ALTER TABLE inventory_movements_new RENAME TO inventory_movements;',
  );

  // 4) Index for fast lookups by SKU
  await db.execute(
    'CREATE INDEX IF NOT EXISTS idx_movements_variant_sku ON inventory_movements(product_variant_sku);',
  );

  // Re-enable FK enforcement
  await db.execute('PRAGMA foreign_keys = ON;');
});
