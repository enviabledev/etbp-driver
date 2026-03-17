import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:etbp_driver/config/constants.dart';
import 'package:etbp_driver/core/auth/token_storage.dart';

class ApiClient {
  late final Dio _dio;
  final TokenStorage _tokenStorage;

  ApiClient({required TokenStorage tokenStorage}) : _tokenStorage = tokenStorage {
    _dio = Dio(BaseOptions(
      baseUrl: '${AppConstants.apiBaseUrl}${AppConstants.apiPrefix}',
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ));
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _tokenStorage.getAccessToken();
        if (token != null) options.headers['Authorization'] = 'Bearer $token';
        return handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          final refreshed = await _tryRefresh();
          if (refreshed) {
            final token = await _tokenStorage.getAccessToken();
            error.requestOptions.headers['Authorization'] = 'Bearer $token';
            final response = await _dio.fetch(error.requestOptions);
            return handler.resolve(response);
          }
        }
        return handler.next(error);
      },
    ));
    if (kDebugMode) _dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));
  }

  Future<bool> _tryRefresh() async {
    try {
      final rt = await _tokenStorage.getRefreshToken();
      if (rt == null) return false;
      final res = await Dio().post('${AppConstants.apiBaseUrl}${AppConstants.apiPrefix}/auth/refresh', data: {'refresh_token': rt});
      await _tokenStorage.saveTokens(res.data['access_token'], res.data['refresh_token']);
      return true;
    } catch (_) {
      await _tokenStorage.clearTokens();
      return false;
    }
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) => _dio.get(path, queryParameters: queryParameters);
  Future<Response> post(String path, {dynamic data}) => _dio.post(path, data: data);
  Future<Response> put(String path, {dynamic data}) => _dio.put(path, data: data);
  Future<Response> patch(String path, {dynamic data}) => _dio.patch(path, data: data);
}
