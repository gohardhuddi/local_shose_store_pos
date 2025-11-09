// add_stock_service_remote.dart
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:local_shoes_store_pos/helper/global.dart';
import 'package:local_shoes_store_pos/services/networking/network_service.dart';

class ReturnServiceRemote {
  final NetworkService networkService;
  ReturnServiceRemote({required this.networkService});
  Future<Response> uploadCatalogList(List<Map<String, dynamic>> catalog) async {
    try {
      final body = jsonEncode(catalog);
      final String url =
          "${Global.baseUrl}Stock/catalog"; // you asked to explicitly JSON-encode
      final Response response = await networkService.postRequest(
        body: body,
        url: url,
      );
      if (response.statusCode == 200) {
        return response;
      } else {
        return response;
      }
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      throw Exception(e);
    }
  }

  // /// Convenience if you want to send one product at a time.
  // Future<Response> uploadSingle(Map<String, dynamic> product) async {
  //   final body = jsonEncode(product);
  //   return await _dio.post(_url, data: body);
  // }
}
