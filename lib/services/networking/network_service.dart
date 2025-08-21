import 'package:dio/dio.dart';
import 'package:local_shoes_store_pos/helper/global.dart';

class NetworkService {
  final Dio dio = getIt<Dio>();

  Future<Response> postRequest({
    required String body,
    required String url,
  }) async {
    return await dio.post(url, data: body);
  }

  Future<Response> getRequest({required String url}) async {
    return await dio.get(url);
  }
}
