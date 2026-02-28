import 'package:dio/dio.dart';

import 'api_models.dart';

class ApiService {
  static const String _defaultBaseUrl = 'http://10.0.2.2:3000';
  static const String _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: _defaultBaseUrl,
  );
  static const String _apiAuthToken = String.fromEnvironment('API_AUTH_TOKEN', defaultValue: '');

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        if (_apiAuthToken.isNotEmpty) 'Authorization': 'Bearer $_apiAuthToken',
      },
    ),
  );

  Future<AllocationsResponse> getAllocationsResponse({int limit = 50}) async {
    try {
      final response = await _dio.get('/allocations', queryParameters: {'limit': limit});
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          if (data['items'] is List) {
            return AllocationsResponse.fromMap(data);
          }
          if (data['error'] is Map<String, dynamic>) {
            final error = ApiErrorEnvelope.fromMap(data['error'] as Map<String, dynamic>);
            throw Exception('[${error.code}] ${error.message} (requestId: ${error.requestId ?? 'n/a'})');
          }
        }
        if (data is List) {
          return AllocationsResponse(items: data, count: data.length, limit: data.length);
        }
        throw Exception('Unexpected response payload format from /allocations');
      }
      throw Exception('Failed to load allocations. Status code: ${response.statusCode}');
    } on DioException catch (e) {
      if (e.response?.data is Map<String, dynamic>) {
        final body = e.response!.data as Map<String, dynamic>;
        if (body['error'] is Map<String, dynamic>) {
          final error = ApiErrorEnvelope.fromMap(body['error'] as Map<String, dynamic>);
          throw Exception('[${error.code}] ${error.message} (requestId: ${error.requestId ?? 'n/a'})');
        }
      }
      throw Exception('Failed to connect to server: ${e.message}');
    } catch (e) {
      throw Exception('An unknown error occurred while fetching allocations: $e');
    }
  }

  Future<List<dynamic>> getAllocations({int limit = 50}) async {
    final response = await getAllocationsResponse(limit: limit);
    return response.items;
  }
}
