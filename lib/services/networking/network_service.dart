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

  /// Returns true if backend is reachable & healthy.
  Future<bool> isBackendHealthy() async {
    try {
      // Adjust "health" path to match your backend (e.g., "ping", "status")
      final res = await dio
          .get(
            'https://measured-advertisement-cm-proposals.trycloudflare.com',
            options: Options(
              // light response, avoid caching
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
