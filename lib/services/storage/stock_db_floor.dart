import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:local_shoes_store_pos/helper/constants.dart';
import 'package:local_shoes_store_pos/services/storage/stock_db.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../models/cart_model.dart';
import 'mobile/app_database.dart';
import 'mobile/entities/inventory_movement.dart';
import 'mobile/entities/product_variants.dart';
import 'mobile/entities/products.dart';
import 'mobile/entities/return_entity.dart';
import 'mobile/entities/return_line.dart';
import 'mobile/entities/sale.dart';
import 'mobile/entities/sale_line.dart';

class StockDbFloor implements StockDb {
  AppDatabase? _db;

  AppDatabase get db => _db!;

  @override
  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, CustomStrings.dbname);
    _db = await openMobileDb(path);
    print(path);
  }

  // -------------------------
  // Products
  // -------------------------
  @override
  Future<String> upsertProduct({
    required String brand,
    required String articleCode,
    String? articleName,
    required String category,
    required String gender,
  }) async {
    final now = DateTime.now().toIso8601String();

    // --- Ensure Category Exists ---
    final existingCategory = await db.categoryDao.findById(category.trim());
    String? categoryId = existingCategory?.categoryId;

    // --- Ensure Gender Exists ---
    final existingGender = await db.genderDao.findById(gender.trim());
    String? genderId;

    genderId = existingGender?.genderId;

    // --- Check if Product Already Exists ---
    final existingProduct = await db.productDao.findByArticleCode(articleCode);

    if (existingProduct != null) {
      // Update existing product with new info + category/gender
      final updated = existingProduct.copyWith(
        brand: brand,
        articleName: articleName,
        categoryId: categoryId,
        genderId: genderId,
        updatedAt: now,
        isActive: 1,
        isSynced: 0,
      );
      await db.productDao.updateProduct(updated);
      return existingProduct.id!;
    }

    // --- Create New Product ---
    final newProductID = const Uuid().v4();
    final product = Product(
      id: newProductID,
      brand: brand,
      articleCode: articleCode,
      articleName: articleName,
      isActive: 1,
      isSynced: 0,
      createdAt: now,
      updatedAt: now,
      categoryId: categoryId,
      genderId: genderId,
    );

    await db.productDao.insertProduct(product);
    return newProductID;
  }

  // -------------------------
  // Variants
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

    ProductVariant? existing;
    String? existingId;

    if (variantID != null) {
      // Find by variant ID
      final variants = await db.variantDao.findByVariantId(variantID);
      if (variants.isNotEmpty) {
        existing = variants.first;
        existingId = existing.id.toString();
      }
    } else {
      // Find by SKU
      final variant = await db.variantDao.findBySku(sku);
      if (variant != null) {
        existing = variant;
        existingId = existing.id.toString();
      }
    }

    if (existing != null) {
      // Update existing variant
      final currentQty = existing.quantity;
      final nextQty = (isEdit == true) ? quantity : (currentQty + quantity);

      final updated = existing.copyWith(
        productId: productId,
        sizeEu: sizeEu,
        colorName: colorName,
        colorHex: colorHex,
        sku: sku,
        quantity: nextQty,
        purchasePrice: purchasePrice,
        salePrice: salePrice,
        updatedAt: now,
        isActive: 1,
        isSynced: 0,
      );

      await db.variantDao.updateVariant(updated);
      await _recomputeProductActive(productId);
      return existingId!;
    }

    // Insert new variant
    final newVariantId = const Uuid().v4();
    final variant = ProductVariant(
      id: newVariantId,
      productId: productId,
      sizeEu: sizeEu,
      colorName: colorName,
      colorHex: colorHex,
      sku: sku,
      quantity: quantity,
      purchasePrice: purchasePrice,
      salePrice: salePrice,
      isActive: 1,
      isSynced: 0,
      createdAt: now,
      updatedAt: now,
    );

    final newId = await db.variantDao.insertVariant(variant);
    await _recomputeProductActive(productId);
    return newVariantId;
  }

  // -------------------------
  // Movements (core primitive)
  // -------------------------
  // ---------- Allowed actions & normalizer (enum-style safe) ----------
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
    required String productVariantId, // can be int id OR a SKU like "1-Black-1"
    required int quantity,
    required String action,
    required String dateTime,
    bool isSynced = false,
  }) async {
    // 0) validate
    final normalizedAction = _normalizeActionEnumStyle(action);
    if (quantity <= 0) {
      throw ArgumentError.value(quantity, 'quantity', 'Must be > 0');
    }

    // 1) idempotency
    final prior = await db.movementDao.findByMovementId(movementId);
    if (prior != null) return movementId;

    // 2) resolve variant by ID first; if not an int, treat as SKU

    final skuLower = productVariantId.toLowerCase();
    var bySku = await db.variantDao.findBySkuLower(skuLower);

    if (bySku.isEmpty) {
      throw StateError('Variant not found by SKU: $productVariantId');
    }
    // assuming your ProductVariant PK is product_variant_id
    final resolvedVariantId = bySku.first.sku;

    // 3) write ONLY to movements
    final movement = InventoryMovement(
      movementId: movementId,
      productVariantId: resolvedVariantId,
      quantity: quantity,
      action: normalizedAction,
      dateTime: dateTime,
      isSynced: isSynced ? 1 : 0,
    );
    await db.movementDao.insertMovement(movement);
    return movementId;
  }

  // Movement helpers
  // -------------------------
  @override
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

  @override
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

  @override
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

    final vid = productVariantId;

    final variants = await db.variantDao.findByVariantId(vid);
    if (variants.isEmpty) {
      throw StateError('Variant not found: $productVariantId');
    }

    final variant = variants.first;
    final currentQty = variant.quantity;

    int? delta;
    if (newQuantity != null) {
      if (newQuantity < 0) {
        throw ArgumentError.value(newQuantity, 'newQuantity', 'Must be >= 0');
      }
      delta = (newQuantity - currentQty).toInt();
      if (currentQty + delta < 0) {
        throw StateError('Resulting quantity would be negative');
      }
    }

    final updatedVariant = variant.copyWith(
      productId: productId ?? variant.productId,
      sizeEu: sizeEu ?? variant.sizeEu,
      colorName: colorName ?? variant.colorName,
      colorHex: colorHex ?? variant.colorHex,
      sku: sku ?? variant.sku,
      purchasePrice: purchasePrice ?? variant.purchasePrice,
      salePrice: salePrice ?? variant.salePrice,
      quantity: newQuantity ?? variant.quantity,
      updatedAt: now,
      isSynced: 0,
      isActive: 1,
    );

    await db.variantDao.updateVariant(updatedVariant);

    final pidForRecompute = (productId ?? variant.productId.toString());
    await _recomputeProductActive(pidForRecompute);
  }

  // -------------------------
  // Sync helpers
  // -------------------------
  @override
  Future<List<Map<String, dynamic>>> getUnsyncedMovements() async {
    final movements = await db.movementDao.findUnsynced();
    return movements
        .map(
          (m) => {
            'movement_id': m.movementId,
            'product_variant_id': m.productVariantId,
            'quantity': m.quantity,
            'action': m.action,
            'date_time': m.dateTime,
            'is_synced': m.isSynced,
          },
        )
        .toList();
  }

  @override
  Future<void> markMovementSynced(String movementId) async {
    await db.movementDao.markSynced(movementId);
  }

  @override
  Future<Map<String, dynamic>> getUnsyncedPayload() async {
    final products = await db.productDao.findUnsynced();
    final variants = await db.variantDao.findUnsynced();
    final movements = await db.movementDao.findUnsynced();

    return {
      'products': products
          .map(
            (p) => {
              'product_id': p.id,
              'brand': p.brand,
              'article_code': p.articleCode,
              'article_name': p.articleName,
              'notes': p.notes,
              'is_active': p.isActive,
              'is_synced': p.isSynced,
              'created_at': p.createdAt,
              'updated_at': p.updatedAt,
              'category_id': p.categoryId,
              'gender_id': p.genderId,
            },
          )
          .toList(),
      'variants': variants
          .map(
            (v) => {
              'product_variant_id': v.id,
              'product_id': v.productId,
              'size_eu': v.sizeEu,
              'color_name': v.colorName,
              'color_hex': v.colorHex,
              'sku': v.sku,
              'quantity': v.quantity,
              'purchase_price': v.purchasePrice,
              'sale_price': v.salePrice,
              'is_active': v.isActive,
              'is_synced': v.isSynced,
              'created_at': v.createdAt,
              'updated_at': v.updatedAt,
            },
          )
          .toList(),
      'movements': movements
          .map(
            (m) => {
              'movement_id': m.movementId,
              'product_variant_id': m.productVariantId,
              'quantity': m.quantity,
              'action': m.action,
              'date_time': m.dateTime,
              'is_synced': m.isSynced,
            },
          )
          .toList(),
    };
  }

  // -------------------------
  // Queries / Reporting
  // -------------------------
  @override
  Future<List<Map<String, dynamic>>> getAllProducts() async {
    final products = await db.productDao.all();
    return products
        .map(
          (p) => {
            'product_id': p.id,
            'brand': p.brand,
            'article_code': p.articleCode,
            'article_name': p.articleName,
            'notes': p.notes,
            'is_active': p.isActive,
            'is_synced': p.isSynced,
            'created_at': p.createdAt,
            'updated_at': p.updatedAt,
          },
        )
        .toList();
  }

  @override
  Future<List<Map<String, dynamic>>> getAllVariants() async {
    final variants = await db.variantDao.all();
    return variants
        .map(
          (v) => {
            'product_variant_id': v.id,
            'product_id': v.productId,
            'size_eu': v.sizeEu,
            'color_name': v.colorName,
            'color_hex': v.colorHex,
            'sku': v.sku,
            'quantity': v.quantity,
            'purchase_price': v.purchasePrice,
            'sale_price': v.salePrice,
            'is_active': v.isActive,
            'is_synced': v.isSynced,
            'created_at': v.createdAt,
            'updated_at': v.updatedAt,
          },
        )
        .toList();
  }

  @override
  Future<String> getAllStock() async {
    final products = await db.productDao.all();
    final byId = <String, Map<String, dynamic>>{};

    for (final product in products) {
      if (product.isActive == 1) {
        final variants = await db.variantDao.findByProductId(product.id!);
        final activeVariants = variants.where((v) => v.isActive == 1).toList();

        if (activeVariants.isNotEmpty) {
          final productData = {
            'productId': product.id.toString(),
            'brand': product.brand,
            'articleCode': product.articleCode,
            'articleName': product.articleName,
            'isActive': product.isActive == 1,
            'isSynced': product.isSynced == 1,
            'createdAt': product.createdAt,
            'updatedAt': product.updatedAt,
            'totalQty': 0,
            'variantCount': activeVariants.length,
            'variants': <Map<String, dynamic>>[],
          };

          for (final variant in activeVariants) {
            final variantData = {
              'variantId': variant.id.toString(),
              'sku': variant.sku,
              'size': variant.sizeEu,
              'colorName': variant.colorName,
              'colorHex': variant.colorHex,
              'qty': variant.quantity,
              'purchasePrice': variant.purchasePrice,
              'salePrice': variant.salePrice,
              'isActive': variant.isActive == 1,
              'isSynced': variant.isSynced == 1,
              'createdAt': variant.createdAt,
              'updatedAt': variant.updatedAt,
            };

            (productData['variants'] as List).add(variantData);
            productData['totalQty'] =
                (productData['totalQty'] as int) + variant.quantity;
          }

          byId[product.id.toString()] = productData;
        }
      }
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
    final key = variantId;

    if (hard) {
      await db.variantDao.deleteById(key);
      return true;
    } else {
      final now = DateTime.now().toIso8601String();
      await db.variantDao.setActive(key, 0, now);
      return true;
    }
  }

  // -------------------------
  // Internal helpers
  // -------------------------
  Future<void> _recomputeProductActive(String productIdStr) async {
    final pid = productIdStr;

    final activeCount = await db.variantDao.countActiveByProductId(pid) ?? 0;
    final now = DateTime.now().toIso8601String();
    final isActive = activeCount > 0 ? 1 : 0;

    await db.productDao.setActive(pid, isActive, now);
  }

  @override
  // -------------------------------------------------
  // SALE TRANSACTION: add Sale + SaleLines + Stock updates
  // -------------------------------------------------
  Future<String> performSaleTransaction({
    required List<CartItemModel> cartItems,
    required String totalAmount,
    required String paymentType,
    required String amountPaid,
    required String changeReturned,
    required String createdBy,
    required bool isSynced,
  }) async {
    final now = DateTime.now().toIso8601String();
    final saleId = const Uuid().v4();

    try {
      // Step 1 — Insert Sale
      final sale = Sale(
        saleId: saleId,
        totalAmount: double.parse(totalAmount),
        discountAmount: 0.0,
        finalAmount: double.parse(totalAmount),
        paymentType: paymentType,
        amountPaid: double.parse(amountPaid),
        changeReturned: double.parse(changeReturned),
        createdBy: createdBy,
        isSynced: isSynced ? 1 : 0,
        dateTime: now,
        createdAt: now,
        saleType: "sale",
      );
      await db.saleDao.insertSale(sale);

      // Step 2 — Process Each Cart Item
      for (final item in cartItems) {
        final saleLineId = const Uuid().v4();

        final saleLine = SaleLine(
          saleLineId: saleLineId,
          saleId: saleId,
          variantId: item.variant.variantId,
          qty: item.cartQty,
          unitPrice: item.variant.salePrice,
          lineTotal: item.cartQty * item.variant.salePrice,
          createdAt: now,
          isSynced: isSynced ? 1 : 0,
        );

        await db.saleLineDao.insertSaleLine(saleLine);

        // Update stock quantity
        final variants = await db.variantDao.findByVariantId(
          item.variant.variantId,
        );
        if (variants.isEmpty) {
          throw StateError('Variant not found: ${item.variant.variantId}');
        }

        final variant = variants.first;
        final newQty = variant.quantity - item.cartQty;
        if (newQty < 0) {
          throw StateError(
            'Insufficient stock for SKU ${variant.sku} — '
            'current ${variant.quantity}, trying to sell ${item.cartQty}',
          );
        }

        final updatedVariant = variant.copyWith(
          quantity: newQty,
          updatedAt: now,
          isSynced: 0,
        );
        await db.variantDao.updateVariant(updatedVariant);

        // Log stock movement
        final movement = InventoryMovement(
          movementId: const Uuid().v4(),
          productVariantId: item.variant.variantId,
          quantity: item.cartQty,
          action: 'sale_out',
          dateTime: now,
          isSynced: isSynced ? 1 : 0,
        );
        await db.movementDao.insertMovement(movement);
      }

      return saleId;
    } catch (e) {
      // Optional rollback cleanup if partial data inserted
      try {
        await db.saleDao.clearSales();
        await db.saleLineDao.clearLinesForSale(saleId);
      } catch (_) {}
      rethrow;
    }
  }

  @override
  Future<List<Map<String, Object?>>> getSalesSummery({
    required String startDate,
    required String endDate,
  }) async {
    try {
      final result = await db.database.rawQuery(
        '''
      SELECT
        SUM(
          CASE 
            WHEN s.sale_type = 'return' THEN -ABS(s.final_amount)
            ELSE s.final_amount
          END
        ) AS total_sales,
        COUNT(
          DISTINCT CASE 
            WHEN s.sale_type = 'sale' THEN s.sale_id
          END
        ) AS total_orders,
        SUM(
          CASE
            WHEN s.sale_type = 'return' THEN -ABS(sl.qty)
            ELSE sl.qty
          END
        ) AS items_sold
      FROM sales s
      LEFT JOIN sale_lines sl ON s.sale_id = sl.sale_id
      WHERE date(s.date_time) BETWEEN ? AND ?;
    ''',
        [startDate, endDate],
      );

      debugPrint(result.toString());
      return result;
    } catch (e, st) {
      debugPrint('❌ Sales summary query failed: $e');
      debugPrintStack(stackTrace: st);
      rethrow;
    }
  }

  @override
  Future<List<Map<String, Object?>>> getSalesByDateRange({
    required String startDate,
    required String endDate,
  }) async {
    return await db.database.rawQuery(
      '''
    SELECT 
      s.sale_id AS saleId,
      s.total_amount AS totalAmount,
      s.date_time AS dateTime,
      json_group_array(
        json_object(
          'saleLineId', sl.sale_line_id,
          'variantId', sl.variant_id,
          'sku', v.sku,
          'qty', sl.qty,
          'unitPrice', sl.unit_price,
          'lineTotal', sl.line_total
        )
      ) AS saleLines
    FROM sales s
    LEFT JOIN sale_lines sl ON s.sale_id = sl.sale_id
    LEFT JOIN product_variants v ON v.product_variant_id = sl.variant_id
    WHERE date(s.date_time) BETWEEN ? AND ?
    GROUP BY s.sale_id
    ORDER BY s.date_time DESC;
  ''',
      [startDate, endDate],
    );
  }

  @override
  Future<List<Map<String, Object?>>> getAllSales() async {
    try {
      final result = await db.database.rawQuery('''
      SELECT 
        s.sale_id AS saleId,
        s.total_amount AS totalAmount,
        s.final_amount AS finalAmount,
        s.payment_type AS paymentType,
        s.amount_paid AS amountPaid,
        s.change_returned AS changeReturned,
        s.date_time AS dateTime,
        sl.sale_line_id AS saleLineId,
        sl.variant_id AS variantId,
        v.sku AS sku,
        p.brand AS brand,
        p.article_code AS articleCode,
        v.size_eu AS sizeEu,
        v.color_name AS colorName,
        sl.qty AS qty,
        sl.unit_price AS unitPrice,
        sl.line_total AS lineTotal
      FROM sales s
      LEFT JOIN sale_lines sl ON s.sale_id = sl.sale_id
      LEFT JOIN product_variants v ON v.product_variant_id = sl.variant_id
      LEFT JOIN products p ON p.product_id = v.product_id
      ORDER BY s.date_time DESC;
    ''');

      return result;
    } catch (e, st) {
      debugPrint('❌ getAllSales query failed: $e');
      debugPrintStack(stackTrace: st);
      rethrow;
    }
  }

  @override
  Future<String> performReturnTransaction({
    required String saleId,
    required List<CartItemModel> returnedItems,
    required double totalRefund,
    String? reason,
    String? createdBy,
    bool isSynced = false,
  }) async {
    final now = DateTime.now().toIso8601String();
    final returnId = const Uuid().v4();

    try {
      // STEP 1️⃣ — Insert a "Negative Sale" Record (refund)
      final negativeSaleId = const Uuid().v4();
      final negativeSale = Sale(
        saleId: negativeSaleId,
        totalAmount: -totalRefund,
        // negative to represent refund
        discountAmount: 0.0,
        finalAmount: -totalRefund,
        paymentType: 'refund',
        // or match original sale
        amountPaid: -totalRefund,
        changeReturned: 0,
        createdBy: createdBy ?? "self",
        isSynced: isSynced ? 1 : 0,
        dateTime: now,
        createdAt: now,
        saleType: 'return',
      );
      await db.saleDao.insertSale(negativeSale);

      // STEP 2️⃣ — Add Negative Sale Lines (same as Sale but negative qty/price)
      for (final item in returnedItems) {
        final saleLineId = const Uuid().v4();
        final saleLine = SaleLine(
          saleLineId: saleLineId,
          saleId: negativeSaleId,
          variantId: item.variant.variantId,
          qty: -item.cartQty,
          // negative quantity
          unitPrice: item.variant.salePrice,
          lineTotal: -item.cartQty * item.variant.salePrice,
          createdAt: now,
          isSynced: isSynced ? 1 : 0,
        );
        await db.saleLineDao.insertSaleLine(saleLine);
      }

      // STEP 3️⃣ — Create Return Record
      final returnEntity = ReturnEntity(
        returnId: returnId,
        saleId: saleId,
        dateTime: now,
        totalRefund: totalRefund,
        reason: reason,
        createdBy: createdBy,
        isSynced: isSynced ? 1 : 0,
        createdAt: now,
        updatedAt: now,
      );
      await db.returnDao.insertReturn(returnEntity);

      // STEP 4️⃣ — Create Return Line Entries + Update Inventory
      for (final item in returnedItems) {
        // Insert Return Line
        final returnLine = ReturnLine(
          returnLineId: const Uuid().v4(),
          returnId: returnId,
          variantId: item.variant.variantId,
          qty: item.cartQty,
          unitPrice: item.variant.salePrice,
          refundAmount: item.variant.salePrice * item.cartQty,
          isSynced: isSynced ? 1 : 0,
          createdAt: now,
          updatedAt: now,
        );
        await db.returnLineDao.insertReturnLine(returnLine);

        // Update Inventory (stock IN for returned items)
        final variants = await db.variantDao.findByVariantId(
          item.variant.variantId,
        );
        if (variants.isEmpty) {
          throw StateError('Variant not found: ${item.variant.variantId}');
        }

        final variant = variants.first;
        final newQty = variant.quantity + item.cartQty;

        final updatedVariant = variant.copyWith(
          quantity: newQty,
          updatedAt: now,
          isSynced: 0,
        );
        await db.variantDao.updateVariant(updatedVariant);

        // Log inventory movement
        final movement = InventoryMovement(
          movementId: const Uuid().v4(),
          productVariantId: item.variant.variantId,
          quantity: item.cartQty,
          action: 'return_in',
          // opposite of sale_out
          dateTime: now,
          isSynced: isSynced ? 1 : 0,
        );
        await db.movementDao.insertMovement(movement);
      }

      return returnId;
    } catch (e) {
      // Rollback logic (optional, similar to your sale rollback)
      try {
        await db.saleDao.clearSales();
        await db.saleLineDao.clearLinesForSale(saleId);
      } catch (_) {}
      rethrow;
    }
  }

  @override
  Future getCategoriesAndGenders() async {
    final categories = await db.categoryDao.findActive();
    final genders = await _db?.genderDao.findActive();
    return {"categories": categories, "genders": genders};
  }

  @override
  Future<void> updateSyncedProducts({required List<dynamic> mapedList}) async {
    for (final id in mapedList) {
      await db.productDao.markSynced(id);
    }
    ;
  }
}
