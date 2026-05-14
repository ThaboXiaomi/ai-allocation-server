import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/booking.dart';
import '../utils/logger.dart';

class ApiClient {
  final Dio _dio;
  final FlutterSecureStorage _storage;
  static const String _baseUrl = 'http://localhost:8080';

  ApiClient()
      : _dio = Dio(BaseOptions(
          baseUrl: _baseUrl,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
          headers: {
            'Content-Type': 'application/json',
          },
        )),
        _storage = const FlutterSecureStorage();

  // Add authentication interceptor
  Future<void> setAuthHeader() async {
    final token = await _storage.read(key: 'auth_token');
    if (token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    }
  }

  Future<Response<T>> get<T>(String path, {Map<String, dynamic>? queryParameters}) async {
    await setAuthHeader();
    return await _dio.get<T>(path, queryParameters: queryParameters);
  }

  Future<Response<T>> post<T>(String path, {dynamic data}) async {
    await setAuthHeader();
    return await _dio.post<T>(path, data: data);
  }

  Future<Response<T>> put<T>(String path, {dynamic data}) async {
    await setAuthHeader();
    return await _dio.put<T>(path, data: data);
  }

  Future<Response<T>> delete<T>(String path) async {
    await setAuthHeader();
    return await _dio.delete<T>(path);
  }

  Future<void> saveToken(String token) async {
    await _storage.write(key: 'auth_token', value: token);
    AppLogger.info('Auth token saved securely');
  }

  Future<void> clearToken() async {
    await _storage.delete(key: 'auth_token');
    AppLogger.info('Auth token cleared');
  }
}
