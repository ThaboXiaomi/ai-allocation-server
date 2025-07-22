import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> initializeAllocationsCollection() async {
  final firestore = FirebaseFirestore.instance;

  // Fetch sample timetables
  final timetableSnapshot = await firestore.collection('timetables').get();
  for (var timetableDoc in timetableSnapshot.docs) {
    final timetable = timetableDoc.data();
    final allocationId = timetableDoc.id;

    // Fetch matching decisionLog (if any)
    final decisionLogSnapshot = await firestore
        .collection('decisionLogs')
        .where('allocationId', isEqualTo: allocationId)
        .limit(1)
        .get();
    final decisionLog = decisionLogSnapshot.docs.isNotEmpty
        ? decisionLogSnapshot.docs.first.data()
        : {};

    // Merge fields for allocation
    final allocationData = {
      'eventName': timetable['courseTitle'] ?? '',
      'description': timetable['description'] ?? '',
      'room': timetable['room'] ?? '',
      'status': decisionLog['status'] ?? 'Pending',
      'decisionLog': decisionLog['conflictDetails'] ?? '',
      'timetable': timetable['courseTitle'] ?? '',
      // Add other merged fields as needed
      'lecturer': timetable['lecturer'] ?? '',
      'faculty': timetable['faculty'] ?? '',
      'time': timetable['time'] ?? '',
      'resolvedVenue': decisionLog['suggestedVenue'] ?? '',
      'studentCount': timetable['studentCount'] ?? 0,
      'venueCapacity': timetable['venueCapacity'] ?? 0,
      'distanceFactor': decisionLog['distanceFactor'] ?? 0,
      'confidenceScore': decisionLog['confidenceScore'] ?? 0.0,
    };

    // Write to allocations collection
    await firestore.collection('allocations').doc(allocationId).set(allocationData);
  }
  print('Allocations collection initialized!');
}