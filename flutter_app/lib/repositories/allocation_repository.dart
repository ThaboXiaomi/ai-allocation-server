import '../models/booking.dart';
import 'api_client.dart';

class AllocationRepository {
  final ApiClient _apiClient;

  AllocationRepository(this._apiClient);

  // Get all bookings for current user
  Future<List<Booking>> getUserBookings() async {
    try {
      final response = await _apiClient.get('/allocations');
      final List<dynamic> data = response.data;
      return data.map((json) => Booking.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch bookings: $e');
    }
  }

  // Create new booking
  Future<Booking> createBooking({
    required String roomId,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    try {
      final response = await _apiClient.post('/allocations', data: {
        'roomId': roomId,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
      });
      return Booking.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to create booking: $e');
    }
  }

  // Resolve conflict
  Future<Map<String, dynamic>> resolveConflict({
    required String allocationId,
    required String details,
  }) async {
    try {
      final response = await _apiClient.post('/resolve-conflict', data: {
        'allocationId': allocationId,
        'details': details,
      });
      return response.data;
    } catch (e) {
      throw Exception('Failed to resolve conflict: $e');
    }
  }

  // Add to waitlist
  Future<WaitlistEntry> addToWaitlist({
    required String roomId,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    try {
      final response = await _apiClient.post('/waitlist', data: {
        'roomId': roomId,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
      });
      return WaitlistEntry.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to add to waitlist: $e');
    }
  }

  // Get waitlist entries
  Future<List<WaitlistEntry>> getWaitlist() async {
    try {
      final response = await _apiClient.get('/waitlist');
      final List<dynamic> data = response.data;
      return data.map((json) => WaitlistEntry.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch waitlist: $e');
    }
  }

  // Get demand prediction
  Future<DemandPrediction> getDemandPrediction({
    required String roomId,
    required DateTime date,
  }) async {
    try {
      final response = await _apiClient.get(
        '/analytics/demand/$roomId',
        queryParameters: {'date': date.toIso8601String()},
      );
      return DemandPrediction.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to fetch demand prediction: $e');
    }
  }

  // Cancel booking
  Future<void> cancelBooking(String bookingId) async {
    try {
      await _apiClient.delete('/allocations/$bookingId');
    } catch (e) {
      throw Exception('Failed to cancel booking: $e');
    }
  }
}
