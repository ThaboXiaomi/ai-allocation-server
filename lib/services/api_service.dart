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
    final safeLimit = limit.clamp(1, 200);

    try {
      final response = await _dio.get('/allocations', queryParameters: {'limit': safeLimit});
      final data = response.data;

      if (response.statusCode == 200) {
        if (data is Map<String, dynamic>) {
          if (data['items'] is List) {
            return AllocationsResponse.fromMap(data);
          }

          if (data['error'] is Map<String, dynamic>) {
            throw _formatApiError(data['error'] as Map<String, dynamic>);
          }
        }

        if (data is List) {
          return AllocationsResponse(items: data, count: data.length, limit: data.length);
        }

        throw Exception('Unexpected response payload format from /allocations');
      }

      throw Exception('Failed to load allocations. Status code: ${response.statusCode}');
    } on DioException catch (e) {
      final body = e.response?.data;
      if (body is Map<String, dynamic> && body['error'] is Map<String, dynamic>) {
        throw _formatApiError(body['error'] as Map<String, dynamic>);
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

  Exception _formatApiError(Map<String, dynamic> rawError) {
    final error = ApiErrorEnvelope.fromMap(rawError);
    return Exception('[${error.code}] ${error.message} (requestId: ${error.requestId ?? 'n/a'})');
  }
}
