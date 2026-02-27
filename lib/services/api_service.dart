import 'package:dio/dio.dart';

class ApiService {
  // Use --dart-define=API_BASE_URL=https://your-api-url when running/building.
  static const String _defaultBaseUrl = 'http://10.0.2.2:3000';
  static const String _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: _defaultBaseUrl,
  );

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 10),
      headers: const {'Content-Type': 'application/json'},
    ),
  );

  Future<List<dynamic>> getAllocations() async {
    try {
      final response = await _dio.get('/allocations');
      if (response.statusCode == 200) {
        return response.data as List<dynamic>;
      }
      throw Exception('Failed to load allocations. Status code: ${response.statusCode}');
    } on DioException catch (e) {
      final message = e.message ?? 'Unable to connect to allocation server.';
      throw Exception('Failed to connect to server: $message');
    } catch (e) {
      throw Exception('An unknown error occurred while fetching allocations: $e');
    }
  }
}
