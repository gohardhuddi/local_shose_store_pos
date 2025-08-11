import 'dart:convert';

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
        'is_active': 1, // ensure active when edited
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
    bool? isEdit,
  }) async {
    final now = DateTime.now().toIso8601String();

    return await _db.transaction((txn) async {
      final existing = await _variants.findFirst(
        txn,
        finder: Finder(filter: Filter.equals('sku', sku)),
      );

      String pidStr = productId; // stored as string in variants
      if (existing != null) {
        final existingData = existing.value as Map<String, dynamic>;
        final currentQty = (existingData['quantity'] as int?) ?? 0;

        await _variants.record(existing.key).update(txn, {
          'product_id': pidStr,
          'size_eu': sizeEu,
          'color_name': colorName,
          'color_hex': colorHex,
          'quantity': isEdit == true ? quantity : currentQty + quantity,
          'purchase_price': purchasePrice,
          'sale_price': salePrice,
          'updated_at': now,
          'is_active': 1, // treat upsert as (re)activation
          'is_synced': 0,
        });

        // Reactivate/ensure product based on active variants
        await _recomputeProductActive(txn, pidStr);
        return existing.key.toString();
      }

      final key = await _variants.add(txn, {
        'product_id': pidStr,
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

      // New active variant -> ensure product is active
      await _recomputeProductActive(txn, pidStr);
      return key.toString();
    });
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

  @override
  Future<String> getAllStock() async {
    // 1) read all products & variants (one pass each)
    final productRecords = await _products.find(
      _db,
      finder: Finder(
        sortOrders: [SortOrder('article_code')],
        filter: Filter.equals('is_active', 1), // only active products
      ),
    );

    final variantRecords = await _variants.find(
      _db,
      finder: Finder(
        sortOrders: [SortOrder('sku')],
        filter: Filter.equals('is_active', 1), // only active variants
      ),
    );

    // 2) group variants by product_id (avoid N+1 lookups)
    final variantsByPid =
        <String, List<RecordSnapshot<int, Map<String, Object?>>>>{};
    for (final v in variantRecords) {
      final pid = (v.value['product_id'] ?? '').toString();
      (variantsByPid[pid] ??= <RecordSnapshot<int, Map<String, Object?>>>[])
          .add(v);
    }

    // 3) build products with attached variants + totals
    final List<Map<String, dynamic>> result = [];
    for (final p in productRecords) {
      final pid = p.key.toString(); // product_id is the Sembast key
      final pv = variantsByPid[pid] ?? const [];

      int totalQty = 0;
      final variants = <Map<String, dynamic>>[];

      for (final r in pv) {
        final v = r.value;
        final vQty = (v['quantity'] as int?) ?? 0;
        totalQty += vQty;

        variants.add({
          'variantId': r.key.toString(),
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

    // already sorted by article_code via Finder; keep JSON stable
    return jsonEncode(result);
  }

  /// Delete a variant:
  /// - hard == false: soft delete -> is_active = 0 (+ is_deleted flag, timestamps)
  /// - hard == true : remove row
  /// After either path, we recompute product.is_active based on active variants left.
  @override
  Future<bool> deleteVariantById(String variantId, {bool hard = false}) async {
    final key = int.tryParse(variantId);
    if (key == null) return false;

    return await _db.transaction((txn) async {
      final snap = await _variants.record(key).getSnapshot(txn);
      if (snap == null) return false;

      final now = DateTime.now().toIso8601String();
      final pidStr = (snap.value['product_id'] ?? '').toString();

      if (hard) {
        await _variants.record(key).delete(txn);
      } else {
        await _variants.record(key).update(txn, {
          'is_deleted': 1,
          'is_active': 0,
          'deleted_at': now,
          'updated_at': now,
          'is_synced': 0,
        });
      }

      // After the change, recompute product active/soft-delete as needed
      await _recomputeProductActive(txn, pidStr);
      return true;
    });
  }

  // -------------------------
  // Helpers (Sembast has no triggers)
  // -------------------------

  /// Set product.is_active based on whether any ACTIVE variants remain.
  /// - If at least one active variant exists: ensure product is_active = 1
  /// - If none: soft-delete product (is_active = 0)
  Future<void> _recomputeProductActive(
    DatabaseClient txn,
    String productIdStr,
  ) async {
    final now = DateTime.now().toIso8601String();

    // ✅ Sembast's count() uses `filter:` (not `finder:`)
    final activeCount = await _variants.count(
      txn,
      filter: Filter.and([
        Filter.equals('product_id', productIdStr),
        Filter.equals('is_active', 1),
      ]),
    );

    final pid = int.tryParse(productIdStr);
    if (pid == null) return; // productId not parseable -> skip

    final rec = _products.record(pid);

    if (activeCount > 0) {
      await rec.update(txn, {'is_active': 1, 'updated_at': now});
    } else {
      await rec.update(txn, {'is_active': 0, 'updated_at': now});
    }
  }
}
