import 'package:flutter/cupertino.dart';
import 'package:local_shoes_store_pos/views/home_screen.dart';

import '../views/add_stock_screen.dart';
import '../views/view_stock_screen.dart';

final Map<String, WidgetBuilder> routes = {
  '/addStockScreen': (context) => const AddStockScreen(),
  '/viewStockScreen': (context) => const ViewStockScreen(),
  '/': (context) => const HomeScreen(),
};
