// test.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io'; // for exit()
import 'dart:typed_data';

import 'package:dio/dio.dart';

void main() async {
  final network = NetworkCall();
  await network.runDemo();
  exit(0);
}

/// --- Simple in-memory token storage for demo ---
class TokenStorage {
  static String accessToken =
      'expired_token'; // start expired to trigger refresh
  static String refreshToken = 'refresh_token_abc';
}

/// --- Mock server that simulates endpoints and token refresh ---
class MockServer {
  static int refreshCounter = 0;

  /// Simulates handling of incoming request.
  /// - If path == '/refresh' => returns a new access_token string.
  /// - Else checks Authorization header; if token is not the current valid token, returns 401.
  static Future<MockHttpResponse> handle(RequestOptions options) async {
    // Simulate network latency
    await Future.delayed(
      Duration(milliseconds: 300 + (50 * (options.path.hashCode % 5))),
    );

    final authHeader = options.headers['Authorization'] as String?;
    // Refresh endpoint
    if (options.path == '/refresh') {
      refreshCounter++;
      final newToken = 'token_v${refreshCounter}'; // unique token each refresh
      print('🔁 MockServer: issuing new token: $newToken');
      return MockHttpResponse(
        statusCode: 200,
        body: {'access_token': newToken},
      );
    }

    // Regular API endpoints
    final providedToken = (authHeader ?? '').replaceFirst('Bearer ', '');
    // In this mock: valid token is whatever TokenStorage.accessToken currently is
    if (providedToken == TokenStorage.accessToken &&
        providedToken != 'expired_token') {
      // success
      return MockHttpResponse(
        statusCode: 200,
        body: {'path': options.path, 'ok': true},
      );
    } else {
      // token invalid/expired
      print(
        '🚫 MockServer: received request to ${options.path} with INVALID token: $providedToken',
      );
      return MockHttpResponse(
        statusCode: 401,
        body: {'message': 'token expired'},
      );
    }
  }
}

class MockHttpResponse {
  final int statusCode;
  final Map<String, dynamic> body;
  MockHttpResponse({required this.statusCode, required this.body});
}

/// --- A small HttpClientAdapter that routes requests to our MockServer ---
/// NOTE: signature matches Dio v5: Stream<Uint8List>? and Future<void>? cancelFuture
class MockAdapter implements HttpClientAdapter {
  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final resp = await MockServer.handle(options);
    final responseBytes = utf8.encode(jsonEncode(resp.body));
    final headers = {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    };

    // ResponseBody.fromBytes wants Uint8List
    return ResponseBody.fromBytes(
      Uint8List.fromList(responseBytes),
      resp.statusCode,
      headers: headers,
    );
  }
}

/// --- NetworkCall demonstrates the Dio interceptor and single-refresh lock logic ---
class NetworkCall {
  final Dio dio = Dio();
  Future<void>? _refreshFuture; // acts as a lock / shared future

  NetworkCall() {
    dio.httpClientAdapter = MockAdapter();

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Attach access token
          options.headers['Authorization'] =
              'Bearer ${TokenStorage.accessToken}';
          print(
            '➡️ Requesting ${options.path} with token=${TokenStorage.accessToken}',
          );
          return handler.next(options);
        },
        onError: (err, handler) async {
          final response = err.response;
          // If we got 401, try to refresh token only once at a time
          if (response != null && response.statusCode == 401) {
            print('⚠️ Interceptor detected 401 for ${err.requestOptions.path}');
            // If no refresh in progress, kick it off
            _refreshFuture ??= _refreshToken();

            try {
              // Wait for the refresh to finish (if it's already running this will await that)
              await _refreshFuture;
              // clear the lock so future 401s can trigger another refresh if needed
              _refreshFuture = null;

              // Retry the original request with the new token
              final retryResponse = await _retry(err.requestOptions);
              return handler.resolve(retryResponse);
            } catch (e) {
              // Refresh failed or retry failed: propagate original error
              print('❌ Refresh or retry failed: $e');
              _refreshFuture = null;
              return handler.reject(err);
            }
          }
          return handler.next(err);
        },
      ),
    );
  }

  /// Demo function that fires 5 requests in parallel using Future.wait
  Future<void> runDemo() async {
    print('--- Demo start ---');
    // Start with accessToken set to expired_token (see TokenStorage) so first batch triggers refresh
    final paths = [
      '/api/one',
      '/api/two',
      '/api/three',
      '/api/four',
      '/api/five',
    ];

    try {
      final results = await Future.wait(paths.map((p) => _safeGet(p)));
      print('--- All results ---');
      for (var r in results) {
        print(r);
      }

      // Second batch to show that subsequent requests use already refreshed token (no extra refresh)
      print('\n--- Second batch (should not refresh) ---');
      final results2 = await Future.wait(paths.map((p) => _safeGet(p)));
      for (var r in results2) {
        print(r);
      }
    } catch (e) {
      print('Exception in demo: $e');
    }
  }

  /// Helper wrapper to call GET and pretty print responses (handles thrown DioException).
  Future<Map<String, dynamic>> _safeGet(String path) async {
    try {
      final res = await dio.get(path);
      // res.toString() contains the JSON body we've returned from MockServer
      final map = jsonDecode(res.toString()) as Map<String, dynamic>;
      return {'path': path, 'status': 'OK', 'body': map};
    } on DioException catch (e) {
      if (e.response != null) {
        return {
          'path': path,
          'status': 'ERROR',
          'code': e.response!.statusCode,
          'data': e.response!.data,
        };
      }
      return {'path': path, 'status': 'ERROR', 'error': e.message};
    }
  }

  /// Private retry helper: replay the original request options with the new token attached.
  Future<Response<dynamic>> _retry(RequestOptions requestOptions) {
    final options = Options(
      method: requestOptions.method,
      headers: Map.of(requestOptions.headers),
      responseType: requestOptions.responseType,
      followRedirects: requestOptions.followRedirects,
      validateStatus: requestOptions.validateStatus,
      receiveDataWhenStatusError: requestOptions.receiveDataWhenStatusError,
    );

    // Ensure Authorization uses the new token
    options.headers?['Authorization'] = 'Bearer ${TokenStorage.accessToken}';
    print(
      '↪️ Retrying ${requestOptions.path} with new token=${TokenStorage.accessToken}',
    );
    return dio.request<dynamic>(
      requestOptions.path,
      options: options,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
    );
  }

  /// Token refresh function which calls the MockServer refresh endpoint.
  /// IMPORTANT: this runs only once concurrently due to _refreshFuture lock.
  Future<void> _refreshToken() async {
    print('🔄 Starting token refresh (network call to /refresh)...');
    try {
      final resp = Dio()
        ..httpClientAdapter = MockAdapter()
        ..options.baseUrl = '';

      final response = await resp.post(
        '/refresh',
        data: {'refresh_token': TokenStorage.refreshToken},
      );
      final data = jsonDecode(response.toString()) as Map<String, dynamic>;
      final newToken = data['access_token'] as String;
      // Save new token globally
      TokenStorage.accessToken = newToken;
      print('✅ TokenStorage updated to: ${TokenStorage.accessToken}');
    } catch (e) {
      print('❌ Failed to refresh token: $e');
      rethrow;
    }
  }
}
