import 'dart:convert';

import 'package:sembast_web/sembast_web.dart';
import 'package:uuid/uuid.dart';

import 'stock_db.dart';

class StockDbWeb implements StockDb {
  late final Database _db;
  final _products = stringMapStoreFactory.store('products');
  final _variants = stringMapStoreFactory.store('product_variants');
  final _movements = stringMapStoreFactory.store('inventory_movements');

  @override
  Future<void> init() async {
    final factory = databaseFactoryWeb;
    _db = await factory.openDatabase('shoe_pos_web.db');
  }

  Future<String> addInventoryMovement({
    required String movementId,
    required String sku,
    required int quantity,
    required String action,
    required String dateTime,
    bool isSynced = false,
  }) async {
    final existing = await _movements.findFirst(
      _db,
      finder: Finder(filter: Filter.equals('movement_id', movementId)),
    );

    if (existing != null) {
      return existing.key.toString();
    }

    final key = movementId; // Use movementId as record key (UUID)
    await _movements.record(key).put(_db, {
      'movement_id': movementId,
      'sku': sku,
      'quantity': quantity,
      'action': action,
      'date_time': dateTime,
      'is_synced': isSynced ? 1 : 0,
    });

    return key;
  }

  Future<List<Map<String, dynamic>>> getUnsyncedMovements() async {
    final records = await _movements.find(
      _db,
      finder: Finder(filter: Filter.equals('is_synced', 0)),
    );
    return records.map((r) => {'id': r.key, ...r.value}).toList();
  }

  Future<void> markMovementSynced(String movementId) async {
    final record = await _movements.findFirst(
      _db,
      finder: Finder(filter: Filter.equals('movement_id', movementId)),
    );
    if (record != null) {
      await _movements.record(record.key).update(_db, {'is_synced': 1});
    }
  }

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
    });
    return productId;
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
    final uuid = Uuid();

    return await _db.transaction((txn) async {
      final existing = await _variants.findFirst(
        txn,
        finder: Finder(filter: Filter.equals('sku', sku)),
      );

      if (existing != null) {
        final existingData = existing.value;
        final currentQty = (existingData['quantity'] as int?) ?? 0;

        await _variants.record(existing.key).update(txn, {
          'product_id': productId,
          'size_eu': sizeEu,
          'color_name': colorName,
          'color_hex': colorHex,
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

      final variantGuid = uuid.v4();
      await _variants.record(variantGuid).put(txn, {
        'product_variant_id': variantGuid,
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

      await _recomputeProductActive(txn, productId);
      return variantGuid;
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
}
