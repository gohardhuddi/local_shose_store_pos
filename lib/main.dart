import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:local_shoes_store_pos/controller/add_stock_bloc/add_stock_bloc.dart';
import 'package:local_shoes_store_pos/controller/connectivity_controller/connectivity_events.dart';
import 'package:local_shoes_store_pos/controller/return_bloc/return_bloc.dart';
import 'package:local_shoes_store_pos/repository/add_stock_repository.dart';
import 'package:local_shoes_store_pos/repository/return_repository.dart';
import 'package:local_shoes_store_pos/repository/sales_repository.dart';
import 'package:local_shoes_store_pos/services/networking/network_service.dart';
import 'package:local_shoes_store_pos/services/return_service/retun_service_local.dart';
import 'package:local_shoes_store_pos/services/sales/sales_service_local.dart';
import 'package:local_shoes_store_pos/services/sales/sales_service_remote.dart';
import 'package:local_shoes_store_pos/services/stock/add_stock_service_local.dart';
import 'package:local_shoes_store_pos/services/stock/add_stock_service_remote.dart';
import 'package:local_shoes_store_pos/views/theme_bloc/theme_bloc.dart';
import 'package:local_shoes_store_pos/views/view_helpers/resueables/connectivity_bar.dart';
import 'package:local_shoes_store_pos/views/view_helpers/theme.dart';

import 'controller/connectivity_controller/connectivity_bloc.dart';
import 'controller/sales_bloc/sales_bloc.dart';
import 'device_info_service.dart';
import 'helper/global.dart';
import 'helper/routes.dart';
import 'services/storage/stock_db.dart';
import 'services/storage/stock_db_factory.dart';

late final StockDb stockDb;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Global.setup();
  stockDb = StockDbFactory.create();
  await stockDb.init();
  final info = await DeviceInfoService.getDeviceInfo();
  debugPrint('Device info: $info');

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

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AddStockRepository>(
          create: (context) => AddStockRepository(
            StockServiceLocal(),
            AddStockServiceRemote(networkService: NetworkService()),
          ),
        ),
        RepositoryProvider<SalesRepository>(
          create: (context) => SalesRepository(
            SalesServiceRemote(networkService: NetworkService()),
            SaleServiceLocal(),
          ),
        ),
        RepositoryProvider<ReturnRepository>(
          create: (context) => ReturnRepository(ReturnServiceLocal()),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<ThemeBloc>(create: (context) => ThemeBloc()),
          BlocProvider<AddStockBloc>(
            create: (context) =>
                AddStockBloc(context.read<AddStockRepository>()),
          ),
          BlocProvider<SalesBloc>(
            create: (context) => SalesBloc(context.read<SalesRepository>()),
          ),
          BlocProvider<ReturnBloc>(
            create: (context) => ReturnBloc(context.read<ReturnRepository>()),
          ),
          BlocProvider<ConnectivityBloc>(
            create: (context) =>
                ConnectivityBloc(NetworkService())
                  ..add(CheckInternetConnectivityEvent()),
          ),
        ],
        child: BlocBuilder<ThemeBloc, ThemeMode>(
          builder: (BuildContext context, state) {
            return MaterialApp(
              scaffoldMessengerKey: Global.appScaffoldMessengerKey,
              debugShowCheckedModeBanner: false,
              theme: lightTheme,
              darkTheme: darkTheme,
              themeMode: state,
              initialRoute: "/",
              routes: routes,
              builder: (context, child) => ConnectivitySnackListener(
                child: child ?? const SizedBox.shrink(),
              ),
            );
          },
        ),
      ),
    );
  }
}
