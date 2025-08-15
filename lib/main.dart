import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:local_shoes_store_pos/controller/add_stock_bloc/add_stock_bloc.dart';
import 'package:local_shoes_store_pos/repository/add_stock_repository.dart';
import 'package:local_shoes_store_pos/services/add_stock_service_local.dart';
import 'package:local_shoes_store_pos/views/theme_bloc/theme_bloc.dart';
import 'package:local_shoes_store_pos/views/view_helpers/theme.dart';

import 'helper/routes.dart';
import 'services/storage/stock_db.dart';
import 'services/storage/stock_db_factory.dart';

late final StockDb stockDb;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  WidgetsFlutterBinding.ensureInitialized();
  stockDb = StockDbFactory.create();
  await stockDb.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [SystemUiOverlay.bottom, SystemUiOverlay.top],
    );

    return RepositoryProvider(
      create: (context) => AddStockRepository(StockServiceLocal()),
      child: MultiBlocProvider(
        providers: [
          BlocProvider<ThemeBloc>(create: (context) => ThemeBloc()),
          BlocProvider<AddStockBloc>(
            create: (context) =>
                AddStockBloc(context.read<AddStockRepository>()),
          ),
          // Add more BlocProviders here when needed
        ],
        child: BlocBuilder<ThemeBloc, ThemeMode>(
          builder: (BuildContext context, state) {
            return MaterialApp(
              // scaffoldMessengerKey: Global().snackBarKey,
              debugShowCheckedModeBanner: false,
              theme: lightTheme,
              darkTheme: darkTheme,
              themeMode: state,
              initialRoute: "/",
              routes: routes,
            );
          },
        ),
      ),
    );
  }
}
