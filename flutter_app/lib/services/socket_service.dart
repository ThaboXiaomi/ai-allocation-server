import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../models/booking.dart';
import '../utils/logger.dart';

typedef BookingUpdateCallback = void Function(Booking booking);
typedef ConflictResolutionCallback = void Function(String allocationId, String resolution);

class SocketService {
  IO.Socket? _socket;
  bool _isConnected = false;
  final List<BookingUpdateCallback> _bookingListeners = [];
  final List<ConflictResolutionCallback> _conflictListeners = [];

  static const String _serverUrl = 'http://localhost:8080';

  void connect(String userId) {
    if (_socket != null && _isConnected) {
      AppLogger.info('Socket already connected');
      return;
    }

    _socket = IO.io(_serverUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
      'query': {'userId': userId},
    });

    _socket!.onConnect((_) {
      _isConnected = true;
      AppLogger.info('Socket connected');
      _socket!.emit('join_user', userId);
    });

    _socket!.onDisconnect((_) {
      _isConnected = false;
      AppLogger.warning('Socket disconnected');
    });

    _socket!.onConnectError((error) {
      AppLogger.error('Socket connection error: $error');
    });

    // Listen for booking updates
    _socket!.on('booking_updated', (data) {
      AppLogger.info('Booking update received: $data');
      final booking = Booking.fromJson(data);
      for (var listener in _bookingListeners) {
        listener(booking);
      }
    });

    // Listen for conflict resolutions
    _socket!.on('conflict_resolved', (data) {
      AppLogger.info('Conflict resolved: $data');
      for (var listener in _conflictListeners) {
        listener(data['allocationId'], data['resolution']);
      }
    });

    // Listen for room-specific updates
    _socket!.on('room_update', (data) {
      AppLogger.info('Room update: $data');
    });
  }

  void disconnect() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket = null;
      _isConnected = false;
      AppLogger.info('Socket disconnected');
    }
  }

  bool get isConnected => _isConnected;

  void addBookingListener(BookingUpdateCallback listener) {
    _bookingListeners.add(listener);
  }

  void removeBookingListener(BookingUpdateCallback listener) {
    _bookingListeners.remove(listener);
  }

  void addConflictListener(ConflictResolutionCallback listener) {
    _conflictListeners.add(listener);
  }

  void removeConflictListener(ConflictResolutionCallback listener) {
    _conflictListeners.remove(listener);
  }

  void joinRoom(String roomId) {
    if (_isConnected) {
      _socket!.emit('join_room', roomId);
      AppLogger.info('Joined room channel: $roomId');
    }
  }

  void leaveRoom(String roomId) {
    if (_isConnected) {
      _socket!.emit('leave_room', roomId);
      AppLogger.info('Left room channel: $roomId');
    }
  }
}
