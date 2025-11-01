import 'dart:async';

import 'package:floor/floor.dart';
import 'package:local_shoes_store_pos/services/storage/mobile/daos/return_dao.dart';
import 'package:local_shoes_store_pos/services/storage/mobile/daos/returnline-dao.dart';
import 'package:local_shoes_store_pos/services/storage/mobile/seeding/defaults.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

import 'daos/category_dao.dart';
import 'daos/gender_dao.dart';
import 'daos/movement_dao.dart';
import 'daos/product_dao.dart';
import 'daos/sale_dao.dart';
import 'daos/sale_line_dao.dart';
import 'daos/variant_dao.dart';
import 'entities/category.dart';
import 'entities/gender.dart';
import 'entities/inventory_movement.dart';
import 'entities/product_variants.dart';
import 'entities/products.dart';
import 'entities/return_entity.dart';
import 'entities/return_line.dart';
import 'entities/sale.dart';
import 'entities/sale_line.dart';

part 'app_database.g.dart';

// NOTE: Version 8 because we migrate inventory_movements to store SKU (TEXT) with FK to product_variants(sku)
@Database(
  version: 12,
  entities: [
    Product,
    ProductVariant,
    InventoryMovement,
    Sale,
    SaleLine,
    Category,
    Gender,
    ReturnEntity, // ✅ Added
    ReturnLine, // ✅ Added
  ],
)
abstract class AppDatabase extends FloorDatabase {
  ProductDao get productDao;
  ProductVariantDao get variantDao;
  InventoryMovementDao get movementDao;
  SaleDao get saleDao;
  SaleLineDao get saleLineDao;
  CategoryDao get categoryDao;
  GenderDao get genderDao;
  ReturnDao get returnDao;
  ReturnLineDao get returnLineDao;
  @transaction
  Future<void> insertReturnAndLines(
    ReturnEntity ret,
    List<ReturnLine> lines,
  ) async {
    await returnDao.insertReturn(ret);
    for (final line in lines) {
      await returnLineDao.insertReturnLine(line);
    }
  }
}

Future<AppDatabase> openMobileDb(String path) async {
  final db = await $FloorAppDatabase.databaseBuilder(path).addMigrations([
    migration1to6,
    migration7to8,
    migration8to9,
    migration9to10,
    migration10to11,
    migration11to12,
  ]).build();

  // ✅ Seed defaults if needed
  await seedDefaultData(db);

  return db;
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
final migration8to9 = Migration(8, 9, (db) async {
  await db.execute('PRAGMA foreign_keys = ON;');

  await db.execute('''
CREATE TABLE IF NOT EXISTS sales (
  sale_id          TEXT PRIMARY KEY,
  date_time        TEXT NOT NULL,
  customer_id      TEXT,
  total_amount     REAL NOT NULL,
  discount_amount  REAL NOT NULL,
  final_amount     REAL NOT NULL,
  payment_type     TEXT NOT NULL,
  amount_paid      REAL NOT NULL,
  change_returned  REAL NOT NULL,
  created_by       TEXT NOT NULL,
  is_synced        INTEGER NOT NULL DEFAULT 0
);
''');

  await db.execute('''
CREATE TABLE IF NOT EXISTS sale_lines (
  sale_line_id   TEXT PRIMARY KEY,
  sale_id        TEXT NOT NULL,
  variant_id     INTEGER NOT NULL,
  qty            INTEGER NOT NULL,
  unit_price     REAL NOT NULL,
  line_total     REAL NOT NULL,
  FOREIGN KEY(sale_id) REFERENCES sales(sale_id) ON DELETE CASCADE,
  FOREIGN KEY(variant_id) REFERENCES product_variants(product_variant_id) ON DELETE RESTRICT
);
''');

  await db.execute(
    'CREATE INDEX IF NOT EXISTS idx_sale_lines_sale_id ON sale_lines(sale_id);',
  );
});
final migration9to10 = Migration(9, 10, (sqflite.DatabaseExecutor db) async {
  await db.execute('PRAGMA foreign_keys = OFF;');

  // 1) Rename old products table
  await db.execute('ALTER TABLE products RENAME TO products_old;');

  // 2) Create new products table with TEXT PK
  await db.execute('''
CREATE TABLE products (
  product_id     TEXT PRIMARY KEY,
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

  // 3) Copy over old data, casting integer IDs to TEXT
  await db.execute('''
INSERT INTO products (
  product_id, brand, article_code, article_name, notes,
  is_active, is_synced, created_at, updated_at
)
SELECT
  CAST(product_id AS TEXT),
  brand, article_code, article_name, notes,
  is_active, is_synced, created_at, updated_at
FROM products_old;
''');

  // 4) Drop old table
  await db.execute('DROP TABLE products_old;');

  await db.execute('PRAGMA foreign_keys = ON;');
});
final migration10to11 = Migration(10, 11, (db) async {
  await db.execute('PRAGMA foreign_keys = OFF;');

  // 1) Rename old table
  await db.execute(
    'ALTER TABLE product_variants RENAME TO product_variants_old;',
  );

  // 2) Create new table with TEXT keys
  await db.execute('''
CREATE TABLE product_variants (
  product_variant_id TEXT PRIMARY KEY,
  product_id         TEXT NOT NULL,
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

  // 3) Copy old data, casting IDs to TEXT
  await db.execute('''
INSERT INTO product_variants (
  product_variant_id, product_id, size_eu, color_name, color_hex,
  sku, quantity, purchase_price, sale_price, is_active, is_synced, created_at, updated_at
)
SELECT
  CAST(product_variant_id AS TEXT),
  CAST(product_id AS TEXT),
  size_eu, color_name, color_hex,
  sku, quantity, purchase_price, sale_price, is_active, is_synced, created_at, updated_at
FROM product_variants_old;
''');

  // 4) Drop old table
  await db.execute('DROP TABLE product_variants_old;');

  await db.execute('PRAGMA foreign_keys = ON;');
});
final migration11to12 = Migration(11, 12, (db) async {
  await db.execute('PRAGMA foreign_keys = ON;');

  // Categories
  await db.execute('''
  CREATE TABLE IF NOT EXISTS categories (
    category_id TEXT PRIMARY KEY,
    category_name TEXT NOT NULL UNIQUE,
    is_active INTEGER NOT NULL DEFAULT 1,
    created_at TEXT NOT NULL,
    updated_at TEXT,
    is_synced INTEGER NOT NULL DEFAULT 0
  );
  ''');

  // Genders
  await db.execute('''
  CREATE TABLE IF NOT EXISTS genders (
    gender_id TEXT PRIMARY KEY,
    gender_name TEXT NOT NULL UNIQUE,
    is_active INTEGER NOT NULL DEFAULT 1,
    created_at TEXT NOT NULL,
    updated_at TEXT,
    is_synced INTEGER NOT NULL DEFAULT 0
  );
  ''');

  // Update products table to include foreign keys
  await db.execute('ALTER TABLE products ADD COLUMN category_id TEXT;');
  await db.execute('ALTER TABLE products ADD COLUMN gender_id TEXT;');

  // Optional indexes
  await db.execute(
    'CREATE INDEX IF NOT EXISTS idx_products_category_id ON products(category_id);',
  );
  await db.execute(
    'CREATE INDEX IF NOT EXISTS idx_products_gender_id ON products(gender_id);',
  );
});
