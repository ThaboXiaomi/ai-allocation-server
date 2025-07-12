import 'package:dio/dio.dart';

class ApiService {
  // IMPORTANT: Replace with your computer's IP address.
  // For Android emulators, you can use 10.0.2.2 to connect to your computer's localhost.
  // For physical devices or iOS simulators, use your computer's local IP on the same Wi-Fi network.
  static const String _baseUrl = 'http://127.0.0.1:5000'; // <-- CHANGE THIS

  final Dio _dio = Dio(BaseOptions(
    baseUrl: _baseUrl,
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 3),
  ));

  Future<List<dynamic>> getAllocations() async {
    try {
      final response = await _dio.get('/allocations');
      if (response.statusCode == 200) {
        return response.data as List<dynamic>;
      } else {
        throw Exception('Failed to load allocations. Status code: ${response.statusCode}');
      }
    } on DioException catch (e) {
      // Handle Dio-specific errors (e.g., connection timeout)
      print('Dio error: $e');
      throw Exception('Failed to connect to the server. Please check your network and the server address.');
    } catch (e) {
      print('Generic error: $e');
      throw Exception('An unknown error occurred.');
    }
  }
}