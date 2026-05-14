import 'package:json_annotation/json_annotation.dart';

part 'booking.g.dart';

enum BookingStatus {
  pending,
  confirmed,
  rejected,
  waitlisted,
  cancelled,
}

@JsonSerializable()
class Booking {
  final String id;
  final String userId;
  final String roomId;
  final DateTime startTime;
  final DateTime endTime;
  final BookingStatus status;
  final String? conflictReason;
  final double? conflictScore;
  final DateTime createdAt;
  final DateTime updatedAt;

  Booking({
    required this.id,
    required this.userId,
    required this.roomId,
    required this.startTime,
    required this.endTime,
    required this.status,
    this.conflictReason,
    this.conflictScore,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Booking.fromJson(Map<String, dynamic> json) => _$BookingFromJson(json);
  Map<String, dynamic> toJson() => _$BookingToJson(this);

  bool get isPending => status == BookingStatus.pending;
  bool get isConfirmed => status == BookingStatus.confirmed;
  bool get isWaitlisted => status == BookingStatus.waitlisted;
}

@JsonSerializable()
class Room {
  final String id;
  final String name;
  final int capacity;
  final List<String> amenities;
  final Map<String, dynamic> location;
  final bool isAvailable;

  Room({
    required this.id,
    required this.name,
    required this.capacity,
    required this.amenities,
    required this.location,
    required this.isAvailable,
  });

  factory Room.fromJson(Map<String, dynamic> json) => _$RoomFromJson(json);
  Map<String, dynamic> toJson() => _$RoomToJson(this);
}

@JsonSerializable()
class WaitlistEntry {
  final String id;
  final String userId;
  final String roomId;
  final DateTime requestedStartTime;
  final DateTime requestedEndTime;
  final int position;
  final DateTime createdAt;

  WaitlistEntry({
    required this.id,
    required this.userId,
    required this.roomId,
    required this.requestedStartTime,
    required this.requestedEndTime,
    required this.position,
    required this.createdAt,
  });

  factory WaitlistEntry.fromJson(Map<String, dynamic> json) =>
      _$WaitlistEntryFromJson(json);
  Map<String, dynamic> toJson() => _$WaitlistEntryToJson(this);
}

@JsonSerializable()
class DemandPrediction {
  final String roomId;
  final DateTime date;
  final double predictedDemand;
  final String trend; // 'increasing', 'stable', 'decreasing'
  final List<Map<String, dynamic>> historicalData;

  DemandPrediction({
    required this.roomId,
    required this.date,
    required this.predictedDemand,
    required this.trend,
    required this.historicalData,
  });

  factory DemandPrediction.fromJson(Map<String, dynamic> json) =>
      _$DemandPredictionFromJson(json);
  Map<String, dynamic> toJson() => _$DemandPredictionToJson(this);
}
