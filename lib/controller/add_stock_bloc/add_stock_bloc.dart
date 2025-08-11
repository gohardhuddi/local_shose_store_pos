import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stream_transform/stream_transform.dart';

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
    on<GetStockFromDB>(_onGetAllStock);
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
    final productId = await _addStockRepo.addStockToDBRepo(
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
    if (productId.isNotEmpty) {
      emit(AddStockSuccessState());
    }
  }

  Future<void> _onGetAllStock(
    GetStockFromDB e,
    Emitter<AddStockStates> emit,
  ) async {
    emit(AddStockLoadingState());
    final json = await _addStockRepo.getAllStockRepo();
    print(json);
    _all = StockModel.listFromJsonString(json);

    emit(GetStockFromDBSuccessState(stockList: _all, query: ''));
  }

  Future<void> _onDeleteVariantById(
    DeleteVariantByIdEvent event,
    Emitter<AddStockStates> emit,
  ) async {
    emit(AddStockLoadingState());
    await _addStockRepo.deleteVariantById(event.variantID);

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
}
