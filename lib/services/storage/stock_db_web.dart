// stock_db_web.dart
// Battle-ready with clear add/get/edit stock flows.
// - SKU-based dedupe per product (re-adding same SKU bumps quantity, no duplicate variants)
// - Normalizes SKU to `sku_normalized`
// - Keeps movement history consistent and idempotent
// - Adds addStock(), subtractStock(), editStock(), and getStockJson() helpers

import 'dart:convert';

import 'package:sembast_web/sembast_web.dart';
import 'package:uuid/uuid.dart';

import '../../models/stock_model.dart';
import 'stock_db.dart';

class StockDbWeb implements StockDb {
  late final Database _db;

  // Stores
  final _products = stringMapStoreFactory.store('products');
  final _variants = stringMapStoreFactory.store('product_variants');
  final _movements = stringMapStoreFactory.store('inventory_movements');

  // -------------------------
  // Lifecycle
  // -------------------------
  @override
  Future<void> init() async {
    final factory = databaseFactoryWeb;
    _db = await factory.openDatabase('shoe_pos_web.db');
  }

  // -------------------------
  // Helpers (SKU normalization & lookup)
  // -------------------------
  String _normalizeSku(String sku) => sku.trim().toLowerCase();

  Future<RecordSnapshot<String, Map<String, Object?>>?>
  _findVariantByProductAndSku(
    DatabaseClient txn,
    String productId,
    String skuNormalized,
  ) {
    return _variants.findFirst(
      txn,
      finder: Finder(
        filter: Filter.and([
          Filter.equals('product_id', productId),
          Filter.equals('sku_normalized', skuNormalized),
          // ignore soft-deleted variants
          Filter.or([
            Filter.equals('is_deleted', 0),
            Filter.notEquals('is_deleted', 1),
          ]),
        ]),
      ),
    );
  }

  // -------------------------
  // Movements (core primitive)
  // -------------------------
  /// Core primitive to apply a stock movement to a variant.
  /// - Idempotent by `movementId` (re-using the same id won't double-apply).
  /// - `action` must be 'add' or 'subtract'.
  // Allowed canonical movement types kept in one place
  static const kAllowedActions = <String>{
    'purchase_in',
    'sale_out',
    'return_in',
    'return_out',
    'transfer_in',
    'transfer_out',
    'adjustment_pos',
    'adjustment_neg',
    'damage',
    'stocktake_correction',
  };
  String _normalizeActionEnumStyle(String action) {
    var raw = action.trim();

    // Handle enum-style values: "stockmovementtype.purchasein"
    if (raw.startsWith('StockMovementType.')) {
      raw = raw.replaceFirst('StockMovementType.', '');
    }

    // Convert camelCase to snake_case
    // purchaseIn -> purchase_in
    var rawModified = raw.replaceAllMapped(
      RegExp(r'([a-z])([A-Z])'),
      (m) => '${m[1]}_${m[2]}'.toLowerCase(),
    );

    if (kAllowedActions.contains(rawModified)) {
      return raw;
    }

    throw ArgumentError.value(
      action,
      'action',
      'Must be one of: ${kAllowedActions.join(", ")}',
    );
  }

  @override
  Future<String> addInventoryMovement({
    required String movementId,
    required String productVariantId, // variant id
    required int quantity,
    required String action, // must be one of kAllowedActions
    required String dateTime,
    bool isSynced = false,
  }) async {
    // 0) Validate
    final normalizedAction = _normalizeActionEnumStyle(action);
    if (quantity <= 0) {
      throw ArgumentError.value(quantity, 'quantity', 'Must be > 0');
    }

    // Only write to movements (still idempotent)
    return _db.transaction((txn) async {
      // 1) Idempotency
      final existing = await _movements.findFirst(
        txn,
        finder: Finder(filter: Filter.equals('movement_id', movementId)),
      );
      if (existing != null) return existing.key.toString();

      // 2) Optional: ensure variant exists (read-only). Remove if not needed.
      final variantRec = await _variants.findFirst(
        txn,
        finder: Finder(
          filter: Filter.equals(
            'sku_normalized',
            productVariantId.toLowerCase(),
          ),
        ),
      );
      if (variantRec == null) {
        throw StateError('Variant not found: $productVariantId');
      }

      // 3) Write ONLY to movements table
      await _movements.record(movementId).put(txn, {
        'movement_id': movementId,
        'product_variant_id': productVariantId,
        'quantity': quantity,
        'action': normalizedAction,
        'date_time': dateTime,
        'is_synced': isSynced ? 1 : 0,
      });

      return movementId;
    });
  }

  /// Convenience: strictly increase quantity (movement = add)
  @override
  Future<String> addStock({
    required String movementId,
    required String productVariantId,
    required int quantity, // > 0
    String? dateTimeIso,
    bool isSynced = false,
  }) async {
    return addInventoryMovement(
      movementId: movementId,
      productVariantId: productVariantId,
      quantity: quantity,
      action: 'add',
      dateTime: dateTimeIso ?? DateTime.now().toIso8601String(),
      isSynced: isSynced,
    );
  }

  /// Convenience: strictly decrease quantity (movement = subtract)
  @override
  Future<String> subtractStock({
    required String movementId,
    required String productVariantId,
    required int quantity, // > 0
    String? dateTimeIso,
    bool isSynced = false,
  }) async {
    return addInventoryMovement(
      movementId: movementId,
      productVariantId: productVariantId,
      quantity: quantity,
      action: 'subtract',
      dateTime: dateTimeIso ?? DateTime.now().toIso8601String(),
      isSynced: isSynced,
    );
  }

  /// Get movements not yet synced upstream
  @override
  Future<List<Map<String, dynamic>>> getUnsyncedMovements() async {
    final records = await _movements.find(
      _db,
      finder: Finder(filter: Filter.equals('is_synced', 0)),
    );
    return records
        .map((r) => {'id': r.key, ...Map<String, dynamic>.from(r.value)})
        .toList();
  }

  /// Mark a movement synced via its movement_id
  @override
  Future<void> markMovementSynced(String movementId) async {
    final record = await _movements.findFirst(
      _db,
      finder: Finder(filter: Filter.equals('movement_id', movementId)),
    );
    if (record != null) {
      await _movements.record(record.key).update(_db, {'is_synced': 1});
    }
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
    final finder = Finder(filter: Filter.equals('article_code', articleCode));
    final now = DateTime.now().toIso8601String();
    final uuid = Uuid();

    final existing = await _products.findFirst(_db, finder: finder);
    if (existing != null) {
      await _products.record(existing.key).update(_db, {
        'brand': brand,
        'article_name': articleName,
        'updated_at': now,
        'is_active': 1,
        'is_synced': 0,
      });
      return existing.key.toString();
    }

    final productId = uuid.v4();
    await _products.record(productId).put(_db, {
      'brand': brand,
      'article_code': articleCode,
      'article_name': articleName,
      'is_active': 1,
      'created_at': now,
      'updated_at': now,
      'is_synced': 0,
    });
    return productId;
  }

  // -------------------------
  // Variants (create/update) with SKU-based dedupe per product
  // -------------------------
  @override
  Future<String> upsertVariant({
    required String productId,
    String? variantID,
    required int sizeEu,
    required String colorName,
    String? colorHex,
    required String sku,
    required int quantity,
    required double purchasePrice,
    double? salePrice,
    bool? isEdit,
  }) async {
    final now = DateTime.now().toIso8601String();
    final uuid = Uuid();
    final skuNorm = _normalizeSku(sku);

    return await _db.transaction((txn) async {
      // If variantID is provided, update that exact record.
      if (variantID != null && variantID.isNotEmpty) {
        final existing = await _variants.findFirst(
          txn,
          finder: Finder(
            filter: Filter.equals('product_variant_id', variantID),
          ),
        );

        if (existing != null) {
          final existingData = Map<String, Object?>.from(existing.value);
          final currentQty = (existingData['quantity'] as int?) ?? 0;

          await _variants.record(existing.key).update(txn, {
            'product_id': productId,
            'size_eu': sizeEu,
            'color_name': colorName,
            'color_hex': colorHex,
            'sku': sku,
            'sku_normalized': skuNorm,
            'quantity': isEdit == true ? quantity : currentQty + quantity,
            'purchase_price': purchasePrice,
            'sale_price': salePrice,
            'updated_at': now,
            'is_active': 1,
            'is_synced': 0,
          });

          await _recomputeProductActive(txn, productId);
          return existing.key.toString();
        }
        // If not found, fall-through to creation/merge.
      }

      // No variantID (or not found): enforce uniqueness by (productId, sku_normalized)
      final sameSku = await _findVariantByProductAndSku(
        txn,
        productId,
        skuNorm,
      );
      if (sameSku != null) {
        // Merge: add to quantity (or set exact if isEdit)
        final v = Map<String, Object?>.from(sameSku.value);
        final currentQty = (v['quantity'] as int?) ?? 0;

        await _variants.record(sameSku.key).update(txn, {
          'product_id': productId,
          'size_eu': sizeEu,
          'color_name': colorName,
          'color_hex': colorHex,
          'sku': sku,
          'sku_normalized': skuNorm,
          'quantity': isEdit == true ? quantity : currentQty + quantity,
          'purchase_price': purchasePrice,
          'sale_price': salePrice,
          'updated_at': now,
          'is_active': 1,
          'is_synced': 0,
        });

        await _recomputeProductActive(txn, productId);
        return sameSku.key.toString();
      }

      // Create a brand new variant
      final variantGuid = uuid.v4();
      await _variants.record(variantGuid).put(txn, {
        'product_variant_id': variantGuid,
        'product_id': productId,
        'size_eu': sizeEu,
        'color_name': colorName,
        'color_hex': colorHex,
        'sku': sku,
        'sku_normalized': skuNorm,
        'quantity': quantity,
        'purchase_price': purchasePrice,
        'sale_price': salePrice,
        'created_at': now,
        'updated_at': now,
        'is_active': 1,
        'is_synced': 0,
      });

      await _recomputeProductActive(txn, productId);
      return variantGuid;
    });
  }

  // -------------------------
  // Edit Variant + Quantity (with movement logging)
  // -------------------------
  /// Edit metadata (size/color/sku/prices) and/or set quantity to an exact value.
  /// If quantity changes, a movement is recorded with the delta.
  @override
  Future<void> editStock({
    required String productVariantId,
    String? productId, // if you allow moving variants across products
    int? sizeEu,
    String? colorName,
    String? colorHex,
    String? sku,
    double? purchasePrice,
    double? salePrice,
    int? newQuantity, // if null -> quantity unchanged
    String? movementId, // provide for idempotency when quantity changes
    String? dateTimeIso,
    bool isSynced = false,
  }) async {
    final now = DateTime.now().toIso8601String();
    final movementTime = dateTimeIso ?? now;

    await _db.transaction((txn) async {
      // 1) Load existing variant
      final existing = await _variants.findFirst(
        txn,
        finder: Finder(
          filter: Filter.equals('product_variant_id', productVariantId),
        ),
      );
      if (existing == null) {
        throw StateError('Variant not found: $productVariantId');
      }
      final data = Map<String, dynamic>.from(existing.value);
      final currentQty = (data['quantity'] as int?) ?? 0;

      // 2) Compute delta if newQuantity provided
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

      // 3) Prepare update map (only changed fields)
      final updateMap = <String, Object?>{
        if (productId != null) 'product_id': productId,
        if (sizeEu != null) 'size_eu': sizeEu,
        if (colorName != null) 'color_name': colorName,
        if (colorHex != null) 'color_hex': colorHex,
        if (sku != null) ...{'sku': sku, 'sku_normalized': _normalizeSku(sku)},
        if (purchasePrice != null) 'purchase_price': purchasePrice,
        if (salePrice != null) 'sale_price': salePrice,
        if (newQuantity != null) 'quantity': newQuantity,
        'updated_at': now,
        'is_synced': 0,
        'is_active': 1,
      };

      // 4) Update variant
      await _variants.record(existing.key).update(txn, updateMap);

      // 5) If quantity changed, write a movement with the delta
      if (delta != null && delta != 0) {
        final id = movementId ?? const Uuid().v4();
        final action = delta > 0 ? 'add' : 'subtract';
        final magnitude = delta.abs();

        // idempotency check (in case UI retries)
        final prior = await _movements.findFirst(
          txn,
          finder: Finder(filter: Filter.equals('movement_id', id)),
        );
        if (prior == null) {
          await _movements.record(id).put(txn, {
            'movement_id': id,
            'product_variant_id': productVariantId,
            'quantity': magnitude,
            'action': action,
            'date_time': movementTime,
            'is_synced': isSynced ? 1 : 0,
          });
        }
      }

      // 6) Keep product's active state in sync
      final pidForRecompute = (updateMap['product_id'] ?? data['product_id'])
          ?.toString();
      if (pidForRecompute != null) {
        await _recomputeProductActive(txn, pidForRecompute);
      }
    });
  }

  // -------------------------
  // Queries / Reporting
  // -------------------------
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

  /// Alias for your existing stock snapshot
  Future<String> getStockJson() => getAllStock();

  @override
  Future<String> getAllStock() async {
    final productRecords = await _products.find(
      _db,
      finder: Finder(
        sortOrders: [SortOrder('article_code')],
        filter: Filter.equals('is_active', 1),
      ),
    );

    final variantRecords = await _variants.find(
      _db,
      finder: Finder(
        sortOrders: [SortOrder('sku')],
        filter: Filter.equals('is_active', 1),
      ),
    );

    final variantsByPid =
        <String, List<RecordSnapshot<String, Map<String, Object?>>>>{};
    for (final v in variantRecords) {
      final pid = (v.value['product_id'] ?? '').toString();
      (variantsByPid[pid] ??= []).add(v);
    }

    final List<Map<String, dynamic>> result = [];
    for (final p in productRecords) {
      final pid = p.key;
      final pv = variantsByPid[pid] ?? const [];

      int totalQty = 0;
      final variants = <Map<String, dynamic>>[];

      for (final r in pv) {
        final v = r.value;
        final vQty = (v['quantity'] as int?) ?? 0;
        totalQty += vQty;

        variants.add({
          'variantId': r.key,
          'sku': (v['sku'] ?? '').toString(),
          'size': v['size_eu'],
          'colorName': (v['color_name'] ?? '').toString(),
          'colorHex': v['color_hex'],
          'qty': vQty,
          'purchasePrice': (v['purchase_price'] as num?)?.toDouble(),
          'salePrice': (v['sale_price'] as num?)?.toDouble(),
          'isActive': ((v['is_active'] ?? 1) as int) == 1,
          'isSynced': ((v['is_synced'] ?? 0) as int) == 1,
          'createdAt': v['created_at'],
          'updatedAt': v['updated_at'],
        });
      }

      result.add({
        'productId': pid,
        'brand': (p.value['brand'] ?? '').toString(),
        'articleCode': (p.value['article_code'] ?? '').toString(),
        'articleName': (p.value['article_name'] ?? '').toString(),
        'isActive': ((p.value['is_active'] ?? 1) as int) == 1,
        'createdAt': p.value['created_at'],
        'updatedAt': p.value['updated_at'],
        'totalQty': totalQty,
        'variantCount': variants.length,
        'variants': variants,
      });
    }

    return jsonEncode(result);
  }

  // -------------------------
  // Deletes
  // -------------------------
  @override
  Future<bool> deleteVariantById(String variantId, {bool hard = false}) async {
    return await _db.transaction((txn) async {
      final snap = await _variants.record(variantId).getSnapshot(txn);
      if (snap == null) return false;

      final now = DateTime.now().toIso8601String();
      final pidStr = (snap.value['product_id'] ?? '').toString();

      if (hard) {
        await _variants.record(variantId).delete(txn);
      } else {
        await _variants.record(variantId).update(txn, {
          'is_deleted': 1,
          'is_active': 0,
          'deleted_at': now,
          'updated_at': now,
          'is_synced': 0,
        });
      }

      await _recomputeProductActive(txn, pidStr);
      return true;
    });
  }

  // -------------------------
  // Internal helpers
  // -------------------------
  Future<void> _recomputeProductActive(
    DatabaseClient txn,
    String productIdStr,
  ) async {
    final now = DateTime.now().toIso8601String();

    final activeCount = await _variants.count(
      txn,
      filter: Filter.and([
        Filter.equals('product_id', productIdStr),
        Filter.equals('is_active', 1),
      ]),
    );

    final rec = _products.record(productIdStr);

    if (activeCount > 0) {
      await rec.update(txn, {'is_active': 1, 'updated_at': now});
    } else {
      await rec.update(txn, {'is_active': 0, 'updated_at': now});
    }
  }

  /// Variants where is_synced == 0 (optionally only active)
  Future<List<Map<String, dynamic>>> getUnsyncedVariants({
    bool onlyActive = true,
  }) async {
    final filter = onlyActive
        ? Filter.and([
            Filter.equals('is_synced', 0),
            Filter.equals('is_active', 1),
          ])
        : Filter.equals('is_synced', 0);

    final records = await _variants.find(_db, finder: Finder(filter: filter));
    return records
        .map((r) => {'id': r.key, ...Map<String, dynamic>.from(r.value)})
        .toList();
  }

  /// Products where is_synced == 0 (optionally only active)
  Future<List<Map<String, dynamic>>> getUnsyncedProducts({
    bool onlyActive = true,
  }) async {
    final filter = onlyActive
        ? Filter.and([
            Filter.equals('is_synced', 0),
            Filter.equals('is_active', 1),
          ])
        : Filter.equals('is_synced', 0);

    final records = await _products.find(_db, finder: Finder(filter: filter));
    return records
        .map((r) => {'id': r.key, ...Map<String, dynamic>.from(r.value)})
        .toList();
  }

  /// Mark a product synced by its productId (record key)
  Future<void> markProductSynced(String productId) async {
    await _products.record(productId).update(_db, {'is_synced': 1});
  }

  /// Mark a variant synced by its productVariantId (we search by field for safety)
  Future<void> markVariantSynced(String productVariantId) async {
    final record = await _variants.findFirst(
      _db,
      finder: Finder(
        filter: Filter.equals('product_variant_id', productVariantId),
      ),
    );
    if (record != null) {
      await _variants.record(record.key).update(_db, {'is_synced': 1});
    }
  }

  // -------------------------
  // 🔧 Match StockDb's abstract signature exactly
  // -------------------------
  @override
  Future<Map<String, List<Map<String, dynamic>>>> getUnsyncedPayload() async {
    final products = await getUnsyncedProducts(onlyActive: false);
    final variants = await getUnsyncedVariants(onlyActive: false);
    final movements = await getUnsyncedMovements();

    // Ensure precise typing on return
    return <String, List<Map<String, dynamic>>>{
      'products': products.map((e) => Map<String, dynamic>.from(e)).toList(),
      'variants': variants.map((e) => Map<String, dynamic>.from(e)).toList(),
      'movements': movements.map((e) => Map<String, dynamic>.from(e)).toList(),
    };
  }

  // -------------------------
  // One-time maintenance (optional)
  // -------------------------
  /// Backfill `sku_normalized` for existing rows.
  Future<void> backfillSkuNormalized() async {
    await _db.transaction((txn) async {
      final records = await _variants.find(txn);
      for (final r in records) {
        final v = Map<String, Object?>.from(r.value);
        final rawSku = (v['sku'] ?? '').toString();
        final norm = _normalizeSku(rawSku);
        if (v['sku_normalized'] != norm) {
          await _variants.record(r.key).update(txn, {
            'sku_normalized': norm,
            'updated_at': DateTime.now().toIso8601String(),
            'is_synced': 0,
          });
        }
      }
    });
  }

  @override
  Future<String> addSale({
    required String totalAmount,
    required String paymentType,
    required String amountPaid,
    required String changeReturned,
    required String createdBy,
    required bool isSynced,
  }) {
    // TODO: implement addSale
    throw UnimplementedError();
  }
}
