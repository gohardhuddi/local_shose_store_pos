import 'package:flutter/foundation.dart' show kIsWeb;

import 'stock_db.dart';
import 'stock_db_sqflite.dart';
import 'stock_db_web.dart';

class StockDbFactory {
  static StockDb create() {
    if (kIsWeb) {
      return StockDbWeb();
    } else {
      return StockDbSqflite();
    }
  }
}
