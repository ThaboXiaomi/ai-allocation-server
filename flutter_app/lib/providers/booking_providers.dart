import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/booking.dart';
import '../repositories/allocation_repository.dart';
import '../services/socket_service.dart';

// Provider for SocketService
final socketServiceProvider = Provider<SocketService>((ref) {
  return SocketService();
});

// Provider for current user ID (should be loaded from auth)
final userIdProvider = StateProvider<String?>((ref) => null);

// Provider for AllocationRepository
final allocationRepositoryProvider = Provider<AllocationRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AllocationRepository(apiClient);
});

// Provider for ApiClient
final apiClientProvider = Provider((ref) => ApiClient());

// State notifier for bookings
class BookingsStateNotifier extends StateNotifier<AsyncValue<List<Booking>>> {
  final AllocationRepository _repository;
  final SocketService _socketService;

  BookingsStateNotifier(this._repository, this._socketService)
      : super(const AsyncValue.loading()) {
    _initSocketListener();
    loadBookings();
  }

  void _initSocketListener() {
    _socketService.addBookingListener((booking) {
      // Optimistic update - immediately reflect changes
      state = AsyncValue.data(
        state.value?.map((b) => b.id == booking.id ? booking : b).toList() ??
            [booking],
      );
    });
  }

  Future<void> loadBookings() async {
    state = const AsyncValue.loading();
    try {
      final bookings = await _repository.getUserBookings();
      state = AsyncValue.data(bookings);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> createBooking({
    required String roomId,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    // Optimistic UI update - show pending status immediately
    final tempBooking = Booking(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      userId: '',
      roomId: roomId,
      startTime: startTime,
      endTime: endTime,
      status: BookingStatus.pending,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final currentList = state.value ?? [];
    state = AsyncValue.data([...currentList, tempBooking]);

    try {
      final booking = await _repository.createBooking(
        roomId: roomId,
        startTime: startTime,
        endTime: endTime,
      );
      // Replace temp with actual booking when response arrives
      final updatedList = state.value
              ?.map((b) => b.id == tempBooking.id ? booking : b)
              .toList() ??
          [booking];
      state = AsyncValue.data(updatedList);
    } catch (e, st) {
      // Remove temp booking on error
      final updatedList = state.value?.where((b) => b.id != tempBooking.id).toList() ?? [];
      state = AsyncValue.error(e, st);
      // Could also show error toast here
    }
  }

  Future<void> cancelBooking(String bookingId) async {
    try {
      await _repository.cancelBooking(bookingId);
      await loadBookings(); // Reload to get updated list
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final bookingsProvider = StateNotifierProvider<BookingsStateNotifier, AsyncValue<List<Booking>>>((ref) {
  final repository = ref.watch(allocationRepositoryProvider);
  final socketService = ref.watch(socketServiceProvider);
  return BookingsStateNotifier(repository, socketService);
});

// Waitlist state notifier
class WaitlistStateNotifier extends StateNotifier<AsyncValue<List<WaitlistEntry>>> {
  final AllocationRepository _repository;

  WaitlistStateNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadWaitlist();
  }

  Future<void> loadWaitlist() async {
    state = const AsyncValue.loading();
    try {
      final entries = await _repository.getWaitlist();
      state = AsyncValue.data(entries);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addToWaitlist({
    required String roomId,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    try {
      await _repository.addToWaitlist(
        roomId: roomId,
        startTime: startTime,
        endTime: endTime,
      );
      await loadWaitlist();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final waitlistProvider = StateNotifierProvider<WaitlistStateNotifier, AsyncValue<List<WaitlistEntry>>>((ref) {
  final repository = ref.watch(allocationRepositoryProvider);
  return WaitlistStateNotifier(repository);
});

// Socket connection state
final socketConnectionStateProvider = StreamProvider<bool>((ref) async* {
  final socketService = ref.watch(socketServiceProvider);
  yield socketService.isConnected;
  
  // Could add periodic checks or event stream here
});
