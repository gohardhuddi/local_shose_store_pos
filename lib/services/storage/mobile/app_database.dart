import 'dart:async';

import 'package:floor/floor.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

import 'daos/movement_dao.dart';
import 'daos/product_dao.dart';
import 'daos/variant_dao.dart';
import 'entities/inventory_movement.dart';
import 'entities/products.dart';
import 'entities/product_variants.dart';

part 'app_database.g.dart';

@Database(version: 6, entities: [Product, ProductVariant, InventoryMovement])
abstract class AppDatabase extends FloorDatabase {
  ProductDao get productDao;
  ProductVariantDao get variantDao;
  InventoryMovementDao get movementDao;
}

Future<AppDatabase> openMobileDb(String path) {
  return $FloorAppDatabase
      .databaseBuilder(path)
      .addMigrations([migration1to6])
      .build();
}

// Migration from version 1 to 6
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
)''');

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
)''');

  await db.execute(
    'CREATE INDEX IF NOT EXISTS idx_variants_product ON product_variants(product_id);',
  );
  await db.execute(
    'CREATE INDEX IF NOT EXISTS idx_variants_active ON product_variants(product_id, is_active);',
  );

  await db.execute('''
CREATE TABLE IF NOT EXISTS inventory_movements (
  movement_id        TEXT PRIMARY KEY,
  product_variant_id INTEGER NOT NULL,
  quantity           INTEGER NOT NULL CHECK (quantity > 0),
  action             TEXT NOT NULL CHECK (action IN ('add','subtract')),
  date_time          TEXT NOT NULL,
  is_synced          INTEGER NOT NULL DEFAULT 0,
  FOREIGN KEY(product_variant_id) REFERENCES product_variants(product_variant_id) ON DELETE CASCADE
)''');

  await db.execute(
    'CREATE INDEX IF NOT EXISTS idx_movements_variant ON inventory_movements(product_variant_id);',
  );
});
