import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stream_transform/stream_transform.dart';
import 'package:uuid/uuid.dart';

import '../../models/stock_model.dart';
import '../../repository/add_stock_repository.dart';
import 'add_stock_events.dart';
import 'add_stock_states.dart'; // for debounce

EventTransformer<T> debounce<T>(Duration d) =>
    (events, mapper) => events.debounce(d).switchMap(mapper);

class AddStockBloc extends Bloc<AddStockEvents, AddStockStates> {
  final AddStockRepository _addStockRepo;
  List<StockModel> _all = const [];

  AddStockBloc(this._addStockRepo) : super(AddStockInitialState()) {
    on<AddStockToDB>(_onAddStockToDB);
    on<EditStockVariant>(_onEditVariant);
    on<GetStockFromDB>(_onGetAllStock);
    on<GetUnSyncedStockFromDB>(_onGetAllUnsyncedStock);
    on<DeleteVariantByIdEvent>(_onDeleteVariantById);
    on<SearchQueryChanged>(
      _onSearchChanged,
      transformer: debounce(const Duration(milliseconds: 220)),
    );
  }

  Future<void> _onAddStockToDB(
    AddStockToDB event,
    Emitter<AddStockStates> emit,
  ) async {
    emit(AddStockLoadingState());
    await _addStockRepo.addStockToDBRepo(
      brand: event.brand,
      articleCode: event.articleCode,
      articleName: event.articleName,
      size: event.size,
      color: event.color,
      productCodeSku: event.productCodeSku,
      quantity: event.quantity,
      purchasePrice: event.purchasePrice,
      suggestedSalePrice: event.suggestedSalePrice,
      isEdit: event.isEdit,
    );

    // Optionally reload list here if your UI expects fresh data:
    // await _reloadStock(emit);

    emit(AddStockSuccessState());
  }

  Future<void> _onEditVariant(
    EditStockVariant event,
    Emitter<AddStockStates> emit,
  ) async {
    emit(AddStockLoadingState());

    // Let DB layer handle movement logging based on quantity delta.
    final movementId = const Uuid().v4();
    await _addStockRepo.editVariantRepo(
      size: event.size,
      color: event.color,
      productCodeSku: event.productCodeSku,
      purchasePrice: event.purchasePrice,
      suggestedSalePrice: event.suggestedSalePrice,
      productID: event.productID,
      variantID: event.variantID,
      // If you want to set quantity exactly to event.quantity:
      newQuantity: event.quantity, // ← triggers movement if changed
      movementId: movementId, // ← idempotency
      dateTimeIso: DateTime.now().toIso8601String(),
      isSynced: false,
    );

    // No need to call addInventoryMovementRepo manually anymore.

    // Optionally reload list:
    // await _reloadStock(emit);

    emit(AddStockSuccessState());
  }

  Future<void> _onGetAllStock(
    GetStockFromDB e,
    Emitter<AddStockStates> emit,
  ) async {
    emit(AddStockLoadingState());
    final json = await _addStockRepo.getAllStockRepo();
    _all = StockModel.listFromJsonString(json);
    emit(GetStockFromDBSuccessState(stockList: _all, query: ''));
  }

  Future<void> _onGetAllUnsyncedStock(
    GetUnSyncedStockFromDB e,
    Emitter<AddStockStates> emit,
  ) async {
    emit(AddStockLoadingState());
    final unSynced = await _addStockRepo.getUnSyncPayloadRepo();
    print(jsonEncode(unSynced));
    var mapedList = mapUnsyncedToBackend(unSynced);
    var result = _addStockRepo.syncProductsToBackend(mapedList);
    //now we will need to update products and variants from sync=0 to sync =1
    //but we need to update DTO response to add variant ids
    print(result);
  }

  Future<void> _onDeleteVariantById(
    DeleteVariantByIdEvent event,
    Emitter<AddStockStates> emit,
  ) async {
    emit(AddStockLoadingState());
    await _addStockRepo.deleteVariantById(event.variantID);

    // Optionally reload list:
    // await _reloadStock(emit);

    emit(DeleteVariantByIdSuccessState());
  }

  Future<void> _onSearchChanged(
    SearchQueryChanged e,
    Emitter<AddStockStates> emit,
  ) async {
    var temp;
    if (e.query.isNotEmpty) {
      final terms = _tokenize(e.query);
      final filtered = terms.isEmpty
          ? _all
          : _all.where((p) => _matchesProduct(p, terms)).toList();
      temp = filtered;
    } else {
      temp = _all;
    }
    emit(GetStockFromDBSuccessState(stockList: temp, query: e.query));
  }

  // Handy if you want to refresh the list after add/edit/delete
  Future<void> _reloadStock(Emitter<AddStockStates> emit) async {
    final json = await _addStockRepo.getAllStockRepo();
    _all = StockModel.listFromJsonString(json);
    emit(GetStockFromDBSuccessState(stockList: _all, query: ''));
  }

  List<String> _tokenize(String q) => q
      .toLowerCase()
      .trim()
      .split(RegExp(r'\s+'))
      .where((t) => t.isNotEmpty)
      .toList();

  bool _matchesProduct(StockModel p, List<String> terms) {
    final buf = StringBuffer()
      ..write((p.brand ?? '').toLowerCase())
      ..write(' ')
      ..write((p.articleCode ?? '').toLowerCase())
      ..write(' ')
      ..write((p.articleName ?? '').toLowerCase());
    for (final v in p.variants) {
      buf
        ..write(' ')
        ..write((v.sku ?? '').toLowerCase())
        ..write(' ')
        ..write((v.colorName ?? '').toLowerCase())
        ..write(' ')
        ..write('${v.size ?? ''}');
    }
    final hay = buf.toString();
    return terms.every(hay.contains);
  }

  /// data maping
  // mapper_unsynced_to_backend.dart

  /// Normalizes the unsynced payload (products + variants) into your backend shape.
  /// Input example matches what you printed from the app.
  List<Map<String, dynamic>> mapUnsyncedToBackend(
    Map<String, dynamic> unsynced,
  ) {
    final products = (unsynced['products'] as List? ?? const [])
        .cast<Map>()
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    final variants = (unsynced['variants'] as List? ?? const [])
        .cast<Map>()
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    // Group variants by product_id
    final Map<String, List<Map<String, dynamic>>> variantsByProductId = {};
    for (final v in variants) {
      final pid = (v['product_id'] ?? v['productId'] ?? '').toString();
      (variantsByProductId[pid] ??= <Map<String, dynamic>>[]).add(v);
    }

    // Map each product + its variants to backend shape
    final List<Map<String, dynamic>> out = [];
    for (final p in products) {
      final pid = (p['id'] ?? p['product_id'] ?? p['productId'] ?? '')
          .toString();
      final vlist = variantsByProductId[pid] ?? const <Map<String, dynamic>>[];

      final mappedVariants = vlist.map((v) {
        return {
          'productVariantId':
              (v['product_variant_id'] ?? v['productVariantId'] ?? v['id'])
                  .toString(),
          'productId': pid,
          'sizeEu': v['size_eu'],
          'colorName': v['color_name'],
          'colorHex': v['color_hex'],
          'sku': v['sku'],
          'quantity': v['quantity'],
          'purchasePrice': (v['purchase_price'] as num?)?.toDouble() ?? 0.0,
          'salePrice': (v['sale_price'] as num?)?.toDouble(),
        };
      }).toList();

      out.add({
        'productId': pid,
        'brand': (p['brand'] ?? '').toString(),
        'articleCode': (p['article_code'] ?? p['articleCode'] ?? '').toString(),
        'articleName': (p['article_name'] ?? p['articleName'] ?? '').toString(),
        'notes': (p['notes'] ?? '').toString(),
        'isActive': _toBool(p['is_active'] ?? p['isActive'] ?? 1),
        'variants': mappedVariants,
      });
    }

    return out;
  }

  bool _toBool(dynamic v) {
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) return v == '1' || v.toLowerCase() == 'true';
    return false;
  }
}
