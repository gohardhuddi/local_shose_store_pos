import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:local_shoes_store_pos/helper/global.dart';

class NetworkService {
  final Dio dio = getIt<Dio>();

  final headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  NetworkService() {
    // If using Dio from getIt, ensure you only do this once
    (dio.httpClientAdapter as IOHttpClientAdapter).onHttpClientCreate =
        (HttpClient client) {
          // 👇 This allows self-signed local certificates (HTTPS on localhost)
          client.badCertificateCallback =
              (X509Certificate cert, String host, int port) {
                // For local dev only! Never use this in production.
                return host.contains('127.0.0.1') ||
                    host.contains('localhost') ||
                    host.contains('192.168.');
              };
          return client;
        };
  }

  Future<Response> postRequest({
    required String body,
    required String url,
  }) async {
    return await dio.post(
      url,
      data: body,
      options: Options(headers: headers),
    );
  }

  Future<Response> getRequest({required String url}) async {
    return await dio.get(url);
  }

  /// Returns true if backend is reachable & healthy.
  Future<bool> isBackendHealthy() async {
    try {
      final res = await dio
          .get(
            '${Global.baseUrl}Stock/health', // or your own endpoint
            options: Options(
              receiveDataWhenStatusError: false,
              sendTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
            ),
          )
          .timeout(const Duration(seconds: 10));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
