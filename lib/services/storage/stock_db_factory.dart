import 'package:flutter/foundation.dart' show kIsWeb;

import 'stock_db.dart';
import 'stock_db_floor.dart';
import 'stock_db_web.dart';

class StockDbFactory {
  static StockDb create() {
    if (kIsWeb) {
      return StockDbWeb();
    } else {
      return StockDbFloor();
    }
  }
}
