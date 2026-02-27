import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

class RoomStatusState {
  final bool isLoading;
  final List<Map<String, dynamic>> rooms;
  final String? error;

  const RoomStatusState({
    required this.isLoading,
    required this.rooms,
    this.error,
  });

  factory RoomStatusState.initial() => const RoomStatusState(
        isLoading: true,
        rooms: [],
      );

  RoomStatusState copyWith({
    bool? isLoading,
    List<Map<String, dynamic>>? rooms,
    String? error,
  }) {
    return RoomStatusState(
      isLoading: isLoading ?? this.isLoading,
      rooms: rooms ?? this.rooms,
      error: error,
    );
  }
}

class RoomStatusBloc {
  final FirebaseFirestore _firestore;
  final _controller = StreamController<RoomStatusState>.broadcast();

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;

  RoomStatusBloc({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance {
    _controller.add(RoomStatusState.initial());
  }

  Stream<RoomStatusState> get stream => _controller.stream;

  void watchRoomStatuses() {
    _subscription?.cancel();
    _subscription = _firestore.collection('lecture_rooms').snapshots().listen(
      (snapshot) {
        final rooms = snapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList(growable: false);
        _controller.add(
          RoomStatusState(isLoading: false, rooms: rooms),
        );
      },
      onError: (Object error) {
        _controller.add(
          RoomStatusState(isLoading: false, rooms: const [], error: '$error'),
        );
      },
    );
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    await _controller.close();
  }
}
