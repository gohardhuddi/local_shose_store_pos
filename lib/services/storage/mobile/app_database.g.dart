// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// **************************************************************************
// FloorGenerator
// **************************************************************************

abstract class $AppDatabaseBuilderContract {
  /// Adds migrations to the builder.
  $AppDatabaseBuilderContract addMigrations(List<Migration> migrations);

  /// Adds a database [Callback] to the builder.
  $AppDatabaseBuilderContract addCallback(Callback callback);

  /// Creates the database and initializes it.
  Future<AppDatabase> build();
}

// ignore: avoid_classes_with_only_static_members
class $FloorAppDatabase {
  /// Creates a database builder for a persistent database.
  /// Once a database is built, you should keep a reference to it and re-use it.
  static $AppDatabaseBuilderContract databaseBuilder(String name) =>
      _$AppDatabaseBuilder(name);

  /// Creates a database builder for an in memory database.
  /// Information stored in an in memory database disappears when the process is killed.
  /// Once a database is built, you should keep a reference to it and re-use it.
  static $AppDatabaseBuilderContract inMemoryDatabaseBuilder() =>
      _$AppDatabaseBuilder(null);
}

class _$AppDatabaseBuilder implements $AppDatabaseBuilderContract {
  _$AppDatabaseBuilder(this.name);

  final String? name;

  final List<Migration> _migrations = [];

  Callback? _callback;

  @override
  $AppDatabaseBuilderContract addMigrations(List<Migration> migrations) {
    _migrations.addAll(migrations);
    return this;
  }

  @override
  $AppDatabaseBuilderContract addCallback(Callback callback) {
    _callback = callback;
    return this;
  }

  @override
  Future<AppDatabase> build() async {
    final path = name != null
        ? await sqfliteDatabaseFactory.getDatabasePath(name!)
        : ':memory:';
    final database = _$AppDatabase();
    database.database = await database.open(
      path,
      _migrations,
      _callback,
    );
    return database;
  }
}

class _$AppDatabase extends AppDatabase {
  _$AppDatabase([StreamController<String>? listener]) {
    changeListener = listener ?? StreamController<String>.broadcast();
  }

  ProductDao? _productDaoInstance;

  ProductVariantDao? _variantDaoInstance;

  InventoryMovementDao? _movementDaoInstance;

  SaleDao? _saleDaoInstance;

  SaleLineDao? _saleLineDaoInstance;

  Future<sqflite.Database> open(
    String path,
    List<Migration> migrations, [
    Callback? callback,
  ]) async {
    final databaseOptions = sqflite.OpenDatabaseOptions(
      version: 11,
      onConfigure: (database) async {
        await database.execute('PRAGMA foreign_keys = ON');
        await callback?.onConfigure?.call(database);
      },
      onOpen: (database) async {
        await callback?.onOpen?.call(database);
      },
      onUpgrade: (database, startVersion, endVersion) async {
        await MigrationAdapter.runMigrations(
            database, startVersion, endVersion, migrations);

        await callback?.onUpgrade?.call(database, startVersion, endVersion);
      },
      onCreate: (database, version) async {
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `products` (`product_id` TEXT, `brand` TEXT NOT NULL, `article_code` TEXT NOT NULL, `article_name` TEXT, `notes` TEXT, `is_active` INTEGER NOT NULL, `is_synced` INTEGER NOT NULL, `created_at` TEXT NOT NULL, `updated_at` TEXT NOT NULL, PRIMARY KEY (`product_id`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `product_variants` (`product_variant_id` TEXT, `product_id` TEXT NOT NULL, `size_eu` INTEGER NOT NULL, `color_name` TEXT NOT NULL, `color_hex` TEXT, `sku` TEXT NOT NULL, `quantity` INTEGER NOT NULL, `purchase_price` REAL NOT NULL, `sale_price` REAL, `is_active` INTEGER NOT NULL, `is_synced` INTEGER NOT NULL, `created_at` TEXT NOT NULL, `updated_at` TEXT NOT NULL, FOREIGN KEY (`product_id`) REFERENCES `products` (`product_id`) ON UPDATE NO ACTION ON DELETE CASCADE, PRIMARY KEY (`product_variant_id`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `inventory_movements` (`movement_id` TEXT NOT NULL, `product_variant_id` TEXT NOT NULL, `quantity` INTEGER NOT NULL, `action` TEXT NOT NULL, `date_time` TEXT NOT NULL, `is_synced` INTEGER NOT NULL, PRIMARY KEY (`movement_id`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `sales` (`sale_id` TEXT NOT NULL, `date_time` TEXT NOT NULL, `customer_id` TEXT, `total_amount` REAL NOT NULL, `discount_amount` REAL NOT NULL, `final_amount` REAL NOT NULL, `payment_type` TEXT NOT NULL, `amount_paid` REAL NOT NULL, `change_returned` REAL NOT NULL, `created_by` TEXT NOT NULL, `created_at` TEXT NOT NULL, `updated_at` TEXT, `is_synced` INTEGER NOT NULL, PRIMARY KEY (`sale_id`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `sale_lines` (`sale_line_id` TEXT NOT NULL, `sale_id` TEXT NOT NULL, `variant_id` TEXT NOT NULL, `qty` INTEGER NOT NULL, `unit_price` REAL NOT NULL, `line_total` REAL NOT NULL, `created_at` TEXT NOT NULL, `updated_at` TEXT, `is_synced` INTEGER NOT NULL, FOREIGN KEY (`sale_id`) REFERENCES `sales` (`sale_id`) ON UPDATE NO ACTION ON DELETE CASCADE, FOREIGN KEY (`variant_id`) REFERENCES `product_variants` (`product_variant_id`) ON UPDATE NO ACTION ON DELETE RESTRICT, PRIMARY KEY (`sale_line_id`))');
        await database.execute(
            'CREATE UNIQUE INDEX `index_products_article_code` ON `products` (`article_code`)');
        await database.execute(
            'CREATE INDEX `index_product_variants_product_id` ON `product_variants` (`product_id`)');
        await database.execute(
            'CREATE INDEX `index_product_variants_product_id_is_active` ON `product_variants` (`product_id`, `is_active`)');
        await database.execute(
            'CREATE UNIQUE INDEX `index_product_variants_sku` ON `product_variants` (`sku`)');
        await database.execute(
            'CREATE INDEX `index_inventory_movements_product_variant_id` ON `inventory_movements` (`product_variant_id`)');
        await database.execute(
            'CREATE INDEX `index_sales_date_time` ON `sales` (`date_time`)');
        await database.execute(
            'CREATE INDEX `index_sales_created_by` ON `sales` (`created_by`)');
        await database.execute(
            'CREATE INDEX `index_sale_lines_sale_id` ON `sale_lines` (`sale_id`)');
        await database.execute(
            'CREATE INDEX `index_sale_lines_variant_id` ON `sale_lines` (`variant_id`)');

        await callback?.onCreate?.call(database, version);
      },
    );
    return sqfliteDatabaseFactory.openDatabase(path, options: databaseOptions);
  }

  @override
  ProductDao get productDao {
    return _productDaoInstance ??= _$ProductDao(database, changeListener);
  }

  @override
  ProductVariantDao get variantDao {
    return _variantDaoInstance ??=
        _$ProductVariantDao(database, changeListener);
  }

  @override
  InventoryMovementDao get movementDao {
    return _movementDaoInstance ??=
        _$InventoryMovementDao(database, changeListener);
  }

  @override
  SaleDao get saleDao {
    return _saleDaoInstance ??= _$SaleDao(database, changeListener);
  }

  @override
  SaleLineDao get saleLineDao {
    return _saleLineDaoInstance ??= _$SaleLineDao(database, changeListener);
  }
}

class _$ProductDao extends ProductDao {
  _$ProductDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _productInsertionAdapter = InsertionAdapter(
            database,
            'products',
            (Product item) => <String, Object?>{
                  'product_id': item.id,
                  'brand': item.brand,
                  'article_code': item.articleCode,
                  'article_name': item.articleName,
                  'notes': item.notes,
                  'is_active': item.isActive,
                  'is_synced': item.isSynced,
                  'created_at': item.createdAt,
                  'updated_at': item.updatedAt
                }),
        _productUpdateAdapter = UpdateAdapter(
            database,
            'products',
            ['product_id'],
            (Product item) => <String, Object?>{
                  'product_id': item.id,
                  'brand': item.brand,
                  'article_code': item.articleCode,
                  'article_name': item.articleName,
                  'notes': item.notes,
                  'is_active': item.isActive,
                  'is_synced': item.isSynced,
                  'created_at': item.createdAt,
                  'updated_at': item.updatedAt
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<Product> _productInsertionAdapter;

  final UpdateAdapter<Product> _productUpdateAdapter;

  @override
  Future<Product?> findByArticleCode(String articleCode) async {
    return _queryAdapter.query(
        'SELECT * FROM products WHERE article_code = ?1 LIMIT 1',
        mapper: (Map<String, Object?> row) => Product(
            id: row['product_id'] as String?,
            brand: row['brand'] as String,
            articleCode: row['article_code'] as String,
            articleName: row['article_name'] as String?,
            notes: row['notes'] as String?,
            isActive: row['is_active'] as int,
            isSynced: row['is_synced'] as int,
            createdAt: row['created_at'] as String,
            updatedAt: row['updated_at'] as String),
        arguments: [articleCode]);
  }

  @override
  Future<List<Product>> all() async {
    return _queryAdapter.queryList('SELECT * FROM products',
        mapper: (Map<String, Object?> row) => Product(
            id: row['product_id'] as String?,
            brand: row['brand'] as String,
            articleCode: row['article_code'] as String,
            articleName: row['article_name'] as String?,
            notes: row['notes'] as String?,
            isActive: row['is_active'] as int,
            isSynced: row['is_synced'] as int,
            createdAt: row['created_at'] as String,
            updatedAt: row['updated_at'] as String));
  }

  @override
  Future<List<Product>> findUnsynced() async {
    return _queryAdapter.queryList('SELECT * FROM products WHERE is_synced = 0',
        mapper: (Map<String, Object?> row) => Product(
            id: row['product_id'] as String?,
            brand: row['brand'] as String,
            articleCode: row['article_code'] as String,
            articleName: row['article_name'] as String?,
            notes: row['notes'] as String?,
            isActive: row['is_active'] as int,
            isSynced: row['is_synced'] as int,
            createdAt: row['created_at'] as String,
            updatedAt: row['updated_at'] as String));
  }

  @override
  Future<void> markSynced(int id) async {
    await _queryAdapter.queryNoReturn(
        'UPDATE products SET is_synced = 1 WHERE product_id = ?1',
        arguments: [id]);
  }

  @override
  Future<void> setActive(
    String id,
    int active,
    String updatedAt,
  ) async {
    await _queryAdapter.queryNoReturn(
        'UPDATE products SET is_active = ?2, updated_at = ?3 WHERE product_id = ?1',
        arguments: [id, active, updatedAt]);
  }

  @override
  Future<int> insertProduct(Product p) {
    return _productInsertionAdapter.insertAndReturnId(
        p, OnConflictStrategy.abort);
  }

  @override
  Future<int> updateProduct(Product p) {
    return _productUpdateAdapter.updateAndReturnChangedRows(
        p, OnConflictStrategy.abort);
  }
}

class _$ProductVariantDao extends ProductVariantDao {
  _$ProductVariantDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _productVariantInsertionAdapter = InsertionAdapter(
            database,
            'product_variants',
            (ProductVariant item) => <String, Object?>{
                  'product_variant_id': item.id,
                  'product_id': item.productId,
                  'size_eu': item.sizeEu,
                  'color_name': item.colorName,
                  'color_hex': item.colorHex,
                  'sku': item.sku,
                  'quantity': item.quantity,
                  'purchase_price': item.purchasePrice,
                  'sale_price': item.salePrice,
                  'is_active': item.isActive,
                  'is_synced': item.isSynced,
                  'created_at': item.createdAt,
                  'updated_at': item.updatedAt
                }),
        _productVariantUpdateAdapter = UpdateAdapter(
            database,
            'product_variants',
            ['product_variant_id'],
            (ProductVariant item) => <String, Object?>{
                  'product_variant_id': item.id,
                  'product_id': item.productId,
                  'size_eu': item.sizeEu,
                  'color_name': item.colorName,
                  'color_hex': item.colorHex,
                  'sku': item.sku,
                  'quantity': item.quantity,
                  'purchase_price': item.purchasePrice,
                  'sale_price': item.salePrice,
                  'is_active': item.isActive,
                  'is_synced': item.isSynced,
                  'created_at': item.createdAt,
                  'updated_at': item.updatedAt
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<ProductVariant> _productVariantInsertionAdapter;

  final UpdateAdapter<ProductVariant> _productVariantUpdateAdapter;

  @override
  Future<ProductVariant?> findById(String id) async {
    return _queryAdapter.query(
        'SELECT * FROM product_variants WHERE product_variant_id = ?1 LIMIT 1',
        mapper: (Map<String, Object?> row) => ProductVariant(
            id: row['product_variant_id'] as String?,
            productId: row['product_id'] as String,
            sizeEu: row['size_eu'] as int,
            colorName: row['color_name'] as String,
            colorHex: row['color_hex'] as String?,
            sku: row['sku'] as String,
            quantity: row['quantity'] as int,
            purchasePrice: row['purchase_price'] as double,
            salePrice: row['sale_price'] as double?,
            isActive: row['is_active'] as int,
            isSynced: row['is_synced'] as int,
            createdAt: row['created_at'] as String,
            updatedAt: row['updated_at'] as String),
        arguments: [id]);
  }

  @override
  Future<List<ProductVariant>> findByVariantId(String id) async {
    return _queryAdapter.queryList(
        'SELECT * FROM product_variants WHERE product_variant_id = ?1',
        mapper: (Map<String, Object?> row) => ProductVariant(
            id: row['product_variant_id'] as String?,
            productId: row['product_id'] as String,
            sizeEu: row['size_eu'] as int,
            colorName: row['color_name'] as String,
            colorHex: row['color_hex'] as String?,
            sku: row['sku'] as String,
            quantity: row['quantity'] as int,
            purchasePrice: row['purchase_price'] as double,
            salePrice: row['sale_price'] as double?,
            isActive: row['is_active'] as int,
            isSynced: row['is_synced'] as int,
            createdAt: row['created_at'] as String,
            updatedAt: row['updated_at'] as String),
        arguments: [id]);
  }

  @override
  Future<ProductVariant?> findBySku(String sku) async {
    return _queryAdapter.query(
        'SELECT * FROM product_variants WHERE sku = ?1 LIMIT 1',
        mapper: (Map<String, Object?> row) => ProductVariant(
            id: row['product_variant_id'] as String?,
            productId: row['product_id'] as String,
            sizeEu: row['size_eu'] as int,
            colorName: row['color_name'] as String,
            colorHex: row['color_hex'] as String?,
            sku: row['sku'] as String,
            quantity: row['quantity'] as int,
            purchasePrice: row['purchase_price'] as double,
            salePrice: row['sale_price'] as double?,
            isActive: row['is_active'] as int,
            isSynced: row['is_synced'] as int,
            createdAt: row['created_at'] as String,
            updatedAt: row['updated_at'] as String),
        arguments: [sku]);
  }

  @override
  Future<int?> countActiveByProductId(String productId) async {
    return _queryAdapter.query(
        'SELECT COUNT(*) FROM product_variants WHERE product_id = ?1 AND is_active = 1',
        mapper: (Map<String, Object?> row) => row.values.first as int,
        arguments: [productId]);
  }

  @override
  Future<void> markSynced(int id) async {
    await _queryAdapter.queryNoReturn(
        'UPDATE product_variants SET is_synced = 1 WHERE product_variant_id = ?1',
        arguments: [id]);
  }

  @override
  Future<void> setActive(
    String id,
    int active,
    String updatedAt,
  ) async {
    await _queryAdapter.queryNoReturn(
        'UPDATE product_variants SET is_active = ?2, updated_at = ?3, is_synced = 0 WHERE product_variant_id = ?1',
        arguments: [id, active, updatedAt]);
  }

  @override
  Future<void> softDelete(
    String id,
    String updatedAt,
  ) async {
    await _queryAdapter.queryNoReturn(
        'UPDATE product_variants SET is_active = 0, updated_at = ?2, is_synced = 0 WHERE product_variant_id = ?1',
        arguments: [id, updatedAt]);
  }

  @override
  Future<void> deleteById(String id) async {
    await _queryAdapter.queryNoReturn(
        'DELETE FROM product_variants WHERE product_variant_id = ?1',
        arguments: [id]);
  }

  @override
  Future<List<ProductVariant>> findUnsynced() async {
    return _queryAdapter.queryList(
        'SELECT * FROM product_variants WHERE is_synced = 0',
        mapper: (Map<String, Object?> row) => ProductVariant(
            id: row['product_variant_id'] as String?,
            productId: row['product_id'] as String,
            sizeEu: row['size_eu'] as int,
            colorName: row['color_name'] as String,
            colorHex: row['color_hex'] as String?,
            sku: row['sku'] as String,
            quantity: row['quantity'] as int,
            purchasePrice: row['purchase_price'] as double,
            salePrice: row['sale_price'] as double?,
            isActive: row['is_active'] as int,
            isSynced: row['is_synced'] as int,
            createdAt: row['created_at'] as String,
            updatedAt: row['updated_at'] as String));
  }

  @override
  Future<List<ProductVariant>> all() async {
    return _queryAdapter.queryList('SELECT * FROM product_variants',
        mapper: (Map<String, Object?> row) => ProductVariant(
            id: row['product_variant_id'] as String?,
            productId: row['product_id'] as String,
            sizeEu: row['size_eu'] as int,
            colorName: row['color_name'] as String,
            colorHex: row['color_hex'] as String?,
            sku: row['sku'] as String,
            quantity: row['quantity'] as int,
            purchasePrice: row['purchase_price'] as double,
            salePrice: row['sale_price'] as double?,
            isActive: row['is_active'] as int,
            isSynced: row['is_synced'] as int,
            createdAt: row['created_at'] as String,
            updatedAt: row['updated_at'] as String));
  }

  @override
  Future<List<ProductVariant>> findByProductId(String productId) async {
    return _queryAdapter.queryList(
        'SELECT * FROM product_variants WHERE product_id = ?1',
        mapper: (Map<String, Object?> row) => ProductVariant(
            id: row['product_variant_id'] as String?,
            productId: row['product_id'] as String,
            sizeEu: row['size_eu'] as int,
            colorName: row['color_name'] as String,
            colorHex: row['color_hex'] as String?,
            sku: row['sku'] as String,
            quantity: row['quantity'] as int,
            purchasePrice: row['purchase_price'] as double,
            salePrice: row['sale_price'] as double?,
            isActive: row['is_active'] as int,
            isSynced: row['is_synced'] as int,
            createdAt: row['created_at'] as String,
            updatedAt: row['updated_at'] as String),
        arguments: [productId]);
  }

  @override
  Future<List<ProductVariant>> findBySkuLower(String skuLower) async {
    return _queryAdapter.queryList(
        'SELECT * FROM product_variants WHERE lower(sku) = ?1 LIMIT 1',
        mapper: (Map<String, Object?> row) => ProductVariant(
            id: row['product_variant_id'] as String?,
            productId: row['product_id'] as String,
            sizeEu: row['size_eu'] as int,
            colorName: row['color_name'] as String,
            colorHex: row['color_hex'] as String?,
            sku: row['sku'] as String,
            quantity: row['quantity'] as int,
            purchasePrice: row['purchase_price'] as double,
            salePrice: row['sale_price'] as double?,
            isActive: row['is_active'] as int,
            isSynced: row['is_synced'] as int,
            createdAt: row['created_at'] as String,
            updatedAt: row['updated_at'] as String),
        arguments: [skuLower]);
  }

  @override
  Future<int> insertVariant(ProductVariant v) {
    return _productVariantInsertionAdapter.insertAndReturnId(
        v, OnConflictStrategy.abort);
  }

  @override
  Future<int> updateVariant(ProductVariant v) {
    return _productVariantUpdateAdapter.updateAndReturnChangedRows(
        v, OnConflictStrategy.abort);
  }
}

class _$InventoryMovementDao extends InventoryMovementDao {
  _$InventoryMovementDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _inventoryMovementInsertionAdapter = InsertionAdapter(
            database,
            'inventory_movements',
            (InventoryMovement item) => <String, Object?>{
                  'movement_id': item.movementId,
                  'product_variant_id': item.productVariantId,
                  'quantity': item.quantity,
                  'action': item.action,
                  'date_time': item.dateTime,
                  'is_synced': item.isSynced
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<InventoryMovement> _inventoryMovementInsertionAdapter;

  @override
  Future<InventoryMovement?> findByMovementId(String movementId) async {
    return _queryAdapter.query(
        'SELECT * FROM inventory_movements WHERE movement_id = ?1 LIMIT 1',
        mapper: (Map<String, Object?> row) => InventoryMovement(
            movementId: row['movement_id'] as String,
            productVariantId: row['product_variant_id'] as String,
            quantity: row['quantity'] as int,
            action: row['action'] as String,
            dateTime: row['date_time'] as String,
            isSynced: row['is_synced'] as int),
        arguments: [movementId]);
  }

  @override
  Future<String?> findExisting(String id) async {
    return _queryAdapter.query(
        'SELECT movement_id FROM inventory_movements WHERE movement_id = ?1 LIMIT 1',
        mapper: (Map<String, Object?> row) => row.values.first as String,
        arguments: [id]);
  }

  @override
  Future<List<InventoryMovement>> findUnsynced() async {
    return _queryAdapter.queryList(
        'SELECT * FROM inventory_movements WHERE is_synced = 0',
        mapper: (Map<String, Object?> row) => InventoryMovement(
            movementId: row['movement_id'] as String,
            productVariantId: row['product_variant_id'] as String,
            quantity: row['quantity'] as int,
            action: row['action'] as String,
            dateTime: row['date_time'] as String,
            isSynced: row['is_synced'] as int));
  }

  @override
  Future<void> markSynced(String id) async {
    await _queryAdapter.queryNoReturn(
        'UPDATE inventory_movements SET is_synced = 1 WHERE movement_id = ?1',
        arguments: [id]);
  }

  @override
  Future<void> insertMovement(InventoryMovement movement) async {
    await _inventoryMovementInsertionAdapter.insert(
        movement, OnConflictStrategy.abort);
  }
}

class _$SaleDao extends SaleDao {
  _$SaleDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _saleInsertionAdapter = InsertionAdapter(
            database,
            'sales',
            (Sale item) => <String, Object?>{
                  'sale_id': item.saleId,
                  'date_time': item.dateTime,
                  'customer_id': item.customerId,
                  'total_amount': item.totalAmount,
                  'discount_amount': item.discountAmount,
                  'final_amount': item.finalAmount,
                  'payment_type': item.paymentType,
                  'amount_paid': item.amountPaid,
                  'change_returned': item.changeReturned,
                  'created_by': item.createdBy,
                  'created_at': item.createdAt,
                  'updated_at': item.updatedAt,
                  'is_synced': item.isSynced
                }),
        _saleUpdateAdapter = UpdateAdapter(
            database,
            'sales',
            ['sale_id'],
            (Sale item) => <String, Object?>{
                  'sale_id': item.saleId,
                  'date_time': item.dateTime,
                  'customer_id': item.customerId,
                  'total_amount': item.totalAmount,
                  'discount_amount': item.discountAmount,
                  'final_amount': item.finalAmount,
                  'payment_type': item.paymentType,
                  'amount_paid': item.amountPaid,
                  'change_returned': item.changeReturned,
                  'created_by': item.createdBy,
                  'created_at': item.createdAt,
                  'updated_at': item.updatedAt,
                  'is_synced': item.isSynced
                }),
        _saleDeletionAdapter = DeletionAdapter(
            database,
            'sales',
            ['sale_id'],
            (Sale item) => <String, Object?>{
                  'sale_id': item.saleId,
                  'date_time': item.dateTime,
                  'customer_id': item.customerId,
                  'total_amount': item.totalAmount,
                  'discount_amount': item.discountAmount,
                  'final_amount': item.finalAmount,
                  'payment_type': item.paymentType,
                  'amount_paid': item.amountPaid,
                  'change_returned': item.changeReturned,
                  'created_by': item.createdBy,
                  'created_at': item.createdAt,
                  'updated_at': item.updatedAt,
                  'is_synced': item.isSynced
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<Sale> _saleInsertionAdapter;

  final UpdateAdapter<Sale> _saleUpdateAdapter;

  final DeletionAdapter<Sale> _saleDeletionAdapter;

  @override
  Future<List<Sale>> getAllSales() async {
    return _queryAdapter.queryList(
        'SELECT * FROM sales ORDER BY date_time DESC',
        mapper: (Map<String, Object?> row) => Sale(
            saleId: row['sale_id'] as String,
            dateTime: row['date_time'] as String,
            customerId: row['customer_id'] as String?,
            totalAmount: row['total_amount'] as double,
            discountAmount: row['discount_amount'] as double,
            finalAmount: row['final_amount'] as double,
            paymentType: row['payment_type'] as String,
            amountPaid: row['amount_paid'] as double,
            changeReturned: row['change_returned'] as double,
            createdBy: row['created_by'] as String,
            createdAt: row['created_at'] as String,
            updatedAt: row['updated_at'] as String?,
            isSynced: row['is_synced'] as int));
  }

  @override
  Future<Sale?> findSaleById(String id) async {
    return _queryAdapter.query('SELECT * FROM sales WHERE sale_id = ?1',
        mapper: (Map<String, Object?> row) => Sale(
            saleId: row['sale_id'] as String,
            dateTime: row['date_time'] as String,
            customerId: row['customer_id'] as String?,
            totalAmount: row['total_amount'] as double,
            discountAmount: row['discount_amount'] as double,
            finalAmount: row['final_amount'] as double,
            paymentType: row['payment_type'] as String,
            amountPaid: row['amount_paid'] as double,
            changeReturned: row['change_returned'] as double,
            createdBy: row['created_by'] as String,
            createdAt: row['created_at'] as String,
            updatedAt: row['updated_at'] as String?,
            isSynced: row['is_synced'] as int),
        arguments: [id]);
  }

  @override
  Future<void> clearSales() async {
    await _queryAdapter.queryNoReturn('DELETE FROM sales');
  }

  @override
  Future<void> insertSale(Sale sale) async {
    await _saleInsertionAdapter.insert(sale, OnConflictStrategy.replace);
  }

  @override
  Future<void> insertSales(List<Sale> sales) async {
    await _saleInsertionAdapter.insertList(sales, OnConflictStrategy.replace);
  }

  @override
  Future<void> updateSale(Sale sale) async {
    await _saleUpdateAdapter.update(sale, OnConflictStrategy.abort);
  }

  @override
  Future<void> deleteSale(Sale sale) async {
    await _saleDeletionAdapter.delete(sale);
  }
}

class _$SaleLineDao extends SaleLineDao {
  _$SaleLineDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _saleLineInsertionAdapter = InsertionAdapter(
            database,
            'sale_lines',
            (SaleLine item) => <String, Object?>{
                  'sale_line_id': item.saleLineId,
                  'sale_id': item.saleId,
                  'variant_id': item.variantId,
                  'qty': item.qty,
                  'unit_price': item.unitPrice,
                  'line_total': item.lineTotal,
                  'created_at': item.createdAt,
                  'updated_at': item.updatedAt,
                  'is_synced': item.isSynced
                }),
        _saleLineUpdateAdapter = UpdateAdapter(
            database,
            'sale_lines',
            ['sale_line_id'],
            (SaleLine item) => <String, Object?>{
                  'sale_line_id': item.saleLineId,
                  'sale_id': item.saleId,
                  'variant_id': item.variantId,
                  'qty': item.qty,
                  'unit_price': item.unitPrice,
                  'line_total': item.lineTotal,
                  'created_at': item.createdAt,
                  'updated_at': item.updatedAt,
                  'is_synced': item.isSynced
                }),
        _saleLineDeletionAdapter = DeletionAdapter(
            database,
            'sale_lines',
            ['sale_line_id'],
            (SaleLine item) => <String, Object?>{
                  'sale_line_id': item.saleLineId,
                  'sale_id': item.saleId,
                  'variant_id': item.variantId,
                  'qty': item.qty,
                  'unit_price': item.unitPrice,
                  'line_total': item.lineTotal,
                  'created_at': item.createdAt,
                  'updated_at': item.updatedAt,
                  'is_synced': item.isSynced
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<SaleLine> _saleLineInsertionAdapter;

  final UpdateAdapter<SaleLine> _saleLineUpdateAdapter;

  final DeletionAdapter<SaleLine> _saleLineDeletionAdapter;

  @override
  Future<List<SaleLine>> getLinesForSale(String saleId) async {
    return _queryAdapter.queryList(
        'SELECT * FROM sale_lines WHERE sale_id = ?1',
        mapper: (Map<String, Object?> row) => SaleLine(
            saleLineId: row['sale_line_id'] as String,
            saleId: row['sale_id'] as String,
            variantId: row['variant_id'] as String,
            qty: row['qty'] as int,
            unitPrice: row['unit_price'] as double,
            lineTotal: row['line_total'] as double,
            createdAt: row['created_at'] as String,
            updatedAt: row['updated_at'] as String?,
            isSynced: row['is_synced'] as int),
        arguments: [saleId]);
  }

  @override
  Future<SaleLine?> findSaleLineById(String id) async {
    return _queryAdapter.query(
        'SELECT * FROM sale_lines WHERE sale_line_id = ?1',
        mapper: (Map<String, Object?> row) => SaleLine(
            saleLineId: row['sale_line_id'] as String,
            saleId: row['sale_id'] as String,
            variantId: row['variant_id'] as String,
            qty: row['qty'] as int,
            unitPrice: row['unit_price'] as double,
            lineTotal: row['line_total'] as double,
            createdAt: row['created_at'] as String,
            updatedAt: row['updated_at'] as String?,
            isSynced: row['is_synced'] as int),
        arguments: [id]);
  }

  @override
  Future<void> clearLinesForSale(String saleId) async {
    await _queryAdapter.queryNoReturn(
        'DELETE FROM sale_lines WHERE sale_id = ?1',
        arguments: [saleId]);
  }

  @override
  Future<void> insertSaleLine(SaleLine line) async {
    await _saleLineInsertionAdapter.insert(line, OnConflictStrategy.replace);
  }

  @override
  Future<void> insertSaleLines(List<SaleLine> lines) async {
    await _saleLineInsertionAdapter.insertList(
        lines, OnConflictStrategy.replace);
  }

  @override
  Future<void> updateSaleLine(SaleLine line) async {
    await _saleLineUpdateAdapter.update(line, OnConflictStrategy.abort);
  }

  @override
  Future<void> deleteSaleLine(SaleLine line) async {
    await _saleLineDeletionAdapter.delete(line);
  }
}
