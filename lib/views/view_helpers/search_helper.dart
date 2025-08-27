import 'package:local_shoes_store_pos/models/stock_model.dart';

class SearchHelper {
  /// Tokenizes search query into individual terms
  static List<String> tokenize(String query) {
    return query
        .toLowerCase()
        .trim()
        .split(RegExp(r'\s+'))
        .where((term) => term.isNotEmpty)
        .toList();
  }

  /// Filters stock list based on search query
  static List<StockModel> filterStock(List<StockModel> stockList, String query) {
    if (query.isEmpty) {
      return stockList;
    }

    final terms = tokenize(query);
    if (terms.isEmpty) {
      return stockList;
    }

    return stockList.where((product) => _matchesProduct(product, terms)).toList();
  }

  /// Checks if a product matches all search terms
  static bool _matchesProduct(StockModel product, List<String> terms) {
    final searchableText = StringBuffer()
      ..write((product.brand ?? '').toLowerCase())
      ..write(' ')
      ..write((product.articleCode ?? '').toLowerCase())
      ..write(' ')
      ..write((product.articleName ?? '').toLowerCase());

    // Add variant information to searchable text
    for (final variant in product.variants) {
      searchableText
        ..write(' ')
        ..write((variant.sku ?? '').toLowerCase())
        ..write(' ')
        ..write((variant.colorName ?? '').toLowerCase())
        ..write(' ')
        ..write('${variant.size ?? ''}');
    }

    final haystack = searchableText.toString();
    return terms.every((term) => haystack.contains(term));
  }
}

