import 'package:dio/dio.dart' show Dio;
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

GetIt getIt = GetIt.instance;

class Global {
  static final GlobalKey<ScaffoldMessengerState> appScaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();
  static const String host = 'localhost';
  static const int port = 5245;
  static const String baseUrl = 'http://$host:$port/api/';
  static void setup() {
    // Register Dio as a lazy singleton (created only when first requested)
    getIt.registerLazySingleton<Dio>(() {
      final dio = Dio();

      dio.options.connectTimeout = Duration(seconds: 5); // 5 seconds
      dio.options.receiveTimeout = Duration(seconds: 5);
      dio.options.headers['Content-Type'] = 'application/json';

      return dio;
    });
  }
}
