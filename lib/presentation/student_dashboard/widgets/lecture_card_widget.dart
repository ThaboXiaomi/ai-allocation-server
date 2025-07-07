import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../../theme/app_theme.dart';
import '../../../widgets/custom_icon_widget.dart';

class LectureCardWidget extends StatefulWidget {
  final Map<String, dynamic> lecture;
  final VoidCallback onViewMap;

  const LectureCardWidget({
    Key? key,
    required this.lecture,
    required this.onViewMap,
  }) : super(key: key);

  @override
  State<LectureCardWidget> createState() => _LectureCardWidgetState();
}

class _LectureCardWidgetState extends State<LectureCardWidget> {
  bool _isClockedIn = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _checkClockInStatus();
  }

  Future<void> _checkClockInStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final timetableId = widget.lecture["id"];
    final today = DateTime.now().toIso8601String().substring(0, 10);

    final existing = await FirebaseFirestore.instance
        .collection('student_check_ins')
        .where('studentId', isEqualTo: user.uid)
        .where('timetableId', isEqualTo: timetableId)
        .where('date', isEqualTo: today)
        .get();

    setState(() {
      _isClockedIn = existing.docs.isNotEmpty;
    });
  }

  Future<void> _clockIn() async {
    setState(() => _loading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final timetableId = widget.lecture["id"];
    final today = DateTime.now().toIso8601String().substring(0, 10);

    // Fetch this timetable
    final timetableSnap = await FirebaseFirestore.instance
        .collection('timetables')
        .doc(timetableId)
        .get();
    final timetable = timetableSnap.data();
    if (timetable == null) return;

    final room = timetable['room'];
    final date = timetable['date'];
    final startTime = timetable['startTime'];
    final endTime = timetable['endTime'];
    final school = timetable['school'];

    // Find other timetables with same room, date, and overlapping time
    final conflictQuery = await FirebaseFirestore.instance
        .collection('timetables')
        .where('room', isEqualTo: room)
        .where('date', isEqualTo: date)
        .get();

    List<Map<String, dynamic>> conflicts = [];
    for (var doc in conflictQuery.docs) {
      if (doc.id == timetableId) continue;
      final other = doc.data();
      // Check for time overlap
      if (!(endTime.compareTo(other['startTime']) <= 0 ||
          startTime.compareTo(other['endTime']) >= 0)) {
        // Only consider other schools
        if (other['school'] != school) {
          conflicts.add({...other, 'id': doc.id});
        }
      }
    }

    // Check if any student has checked in for this room/time
    final checkIns = await FirebaseFirestore.instance
        .collection('student_check_ins')
        .where('timetableId',
            whereIn: [timetableId, ...conflicts.map((c) => c['id'])])
        .where('date', isEqualTo: today)
        .get();

    if (checkIns.docs.isEmpty) {
      // First check-in: allow and mark as in-progress
      await FirebaseFirestore.instance.collection('student_check_ins').add({
        'studentId': user.uid,
        'timetableId': timetableId,
        'timestamp': FieldValue.serverTimestamp(),
        'date': today,
      });
      await FirebaseFirestore.instance
          .collection('timetables')
          .doc(timetableId)
          .update({'status': 'in-progress'});
      // Optionally send notification: "Check-in successful"
    } else {
      // Another class already checked in: trigger AI for this timetable
      final response = await http.post(
        Uri.parse('http://localhost:3000/resolve-conflict'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'allocationId': timetableId,
          'conflictDetails':
              'Room $room is occupied at $startTime-$endTime on $date. Please suggest an alternative venue.',
          'date': date,
          'startTime': startTime,
          'endTime': endTime,
        }),
      );
      if (response.statusCode == 200) {
        final suggestedVenue = jsonDecode(response.body)['resolvedVenue'];
        await FirebaseFirestore.instance
            .collection('timetables')
            .doc(timetableId)
            .update({
          'status': 'diverted',
          'resolvedVenue': suggestedVenue,
        });
        // Optionally send notification: "Your class has been moved to $suggestedVenue"
      }
      // Optionally show a message: "Room already in use. You have been diverted."
    }

    setState(() {
      _isClockedIn = true;
      _loading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Clock-in successful!')),
    );
  }

  Future<void> _unclockIn() async {
    setState(() => _loading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final timetableId = widget.lecture["id"];
    final today = DateTime.now().toIso8601String().substring(0, 10);

    final existing = await FirebaseFirestore.instance
        .collection('student_check_ins')
        .where('studentId', isEqualTo: user.uid)
        .where('timetableId', isEqualTo: timetableId)
        .where('date', isEqualTo: today)
        .get();

    if (existing.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You have not clocked in yet.')),
      );
      setState(() => _loading = false);
      return;
    }

    for (var doc in existing.docs) {
      await doc.reference.delete();
    }

    // Send notification to Admin and Lecturer
    await _sendClockInNotification('unclock_in');

    setState(() {
      _isClockedIn = false;
      _loading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Unclock-in successful!')),
    );
  }

  Future<void> _sendClockInNotification(String type) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final timetableId = widget.lecture["id"];
    final courseTitle = widget.lecture["courseTitle"] ?? "";
    final courseCode = widget.lecture["courseCode"] ?? "";
    final studentName = user.displayName ?? user.email ?? "Student";
    final now = DateTime.now();

    // Send to admin
    await FirebaseFirestore.instance.collection('notifications').add({
      'type': type,
      'target': 'admin',
      'studentId': user.uid,
      'timetableId': timetableId,
      'courseTitle': courseTitle,
      'courseCode': courseCode,
      'studentName': studentName,
      'timestamp': now,
      'message': type == 'clock_in'
          ? '$studentName clocked in for $courseCode - $courseTitle'
          : '$studentName unclocked-in for $courseCode - $courseTitle',
      'isRead': false,
    });

    // Send to lecturer (assuming lecturerId is in lecture data)
    final lecturerId = widget.lecture["lecturerId"];
    if (lecturerId != null) {
      await FirebaseFirestore.instance.collection('notifications').add({
        'type': type,
        'target': 'lecturer',
        'lecturerId': lecturerId,
        'studentId': user.uid,
        'timetableId': timetableId,
        'courseTitle': courseTitle,
        'courseCode': courseCode,
        'studentName': studentName,
        'timestamp': now,
        'message': type == 'clock_in'
            ? '$studentName clocked in for $courseCode - $courseTitle'
            : '$studentName unclocked-in for $courseCode - $courseTitle',
        'isRead': false,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final lecture = widget.lecture;
    final bool isReallocated = lecture["isReallocated"] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: isReallocated ? Colors.amber.shade300 : AppTheme.neutral200,
          width: isReallocated ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          // Header with course code and time
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isReallocated ? Colors.amber.shade100 : AppTheme.neutral50,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isReallocated
                              ? Colors.amber.shade50
                              : AppTheme.primary50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isReallocated
                                ? Colors.amber.shade300
                                : AppTheme.primary300,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.book_rounded,
                              color: isReallocated
                                  ? Colors.amber.shade700
                                  : AppTheme.primary700,
                              size: 20,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              lecture["courseCode"]?.toString() ?? "",
                              style: AppTheme.lightTheme.textTheme.titleSmall
                                  ?.copyWith(
                                color: isReallocated
                                    ? Colors.amber.shade700
                                    : AppTheme.primary700,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                color: AppTheme.primary600,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${lecture["startTime"]?.toString() ?? ""} - ${lecture["endTime"]?.toString() ?? ""}',
                                style: AppTheme.lightTheme.textTheme.bodyMedium
                                    ?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                          if (isReallocated)
                            Row(
                              children: [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  color: Colors.amber.shade600,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Venue Changed',
                                  style: AppTheme.lightTheme.textTheme.bodySmall
                                      ?.copyWith(
                                    color: Colors.amber.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(lecture["status"]?.toString() ?? "")
                        .withAlpha(26),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color:
                          _getStatusColor(lecture["status"]?.toString() ?? "")
                              .withAlpha(77),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        lecture["status"] == "ongoing"
                            ? Icons.play_circle_fill_rounded
                            : lecture["status"] == "completed"
                                ? Icons.check_circle_rounded
                                : Icons.schedule_rounded,
                        color: _getStatusColor(
                            lecture["status"]?.toString() ?? ""),
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _getStatusText(lecture["status"]?.toString() ?? ""),
                        style:
                            AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                          color: _getStatusColor(
                              lecture["status"]?.toString() ?? ""),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Course details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Show all lecture details as in Firebase
                Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        color: AppTheme.primary600, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      lecture["courseTitle"]?.toString() ?? "",
                      style:
                          AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildInfoItem(
                      icon: 'person',
                      label: lecture["instructor"]?.toString() ?? "",
                    ),
                    const SizedBox(width: 16),
                    _buildInfoItem(
                      icon: 'room',
                      label: 'Room ${lecture["venue"]?.toString() ?? ""}',
                      isHighlighted: isReallocated,
                      highlightColor: AppTheme.warning600,
                    ),
                  ],
                ),
                if (isReallocated) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      CustomIconWidget(
                        iconName: 'swap_horiz',
                        color: Colors.amber.shade600,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Changed from Room ${lecture["originalVenue"]?.toString() ?? ""}',
                        style:
                            AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                          color: Colors.amber.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildInfoItem(
                      icon: 'calendar_today',
                      label: 'Date: ${lecture["date"]?.toString() ?? ""}',
                    ),
                    const SizedBox(width: 16),
                    _buildInfoItem(
                      icon: 'schedule',
                      label:
                          'Time: ${lecture["startTime"]?.toString() ?? ""} - ${lecture["endTime"]?.toString() ?? ""}',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: Icon(
                          _isClockedIn
                              ? Icons.logout_rounded
                              : Icons.login_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                        label: Text(_isClockedIn ? 'Unclock-in' : 'Clock-in'),
                        onPressed: _loading
                            ? null
                            : () async {
                                if (_isClockedIn) {
                                  await _unclockIn();
                                } else {
                                  await _clockIn();
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isClockedIn
                              ? Colors.redAccent
                              : AppTheme.primary600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.map_rounded,
                            color: AppTheme.primary600, size: 18),
                        label: const Text('View Map'),
                        onPressed: widget.onViewMap,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required String icon,
    required String label,
    bool isHighlighted = false,
    Color highlightColor = AppTheme.primary600,
  }) {
    IconData? iconData;
    switch (icon) {
      case 'person':
        iconData = Icons.person_rounded;
        break;
      case 'room':
        iconData = Icons.meeting_room_rounded;
        break;
      case 'swap_horiz':
        iconData = Icons.swap_horiz_rounded;
        break;
      case 'warning':
        iconData = Icons.warning_amber_rounded;
        break;
      case 'map':
        iconData = Icons.map_rounded;
        break;
      case 'qr_code_scanner':
        iconData = Icons.qr_code_scanner_rounded;
        break;
      case 'calendar_today':
        iconData = Icons.calendar_today_rounded;
        break;
      case 'schedule':
        iconData = Icons.schedule_rounded;
        break;
      default:
        iconData = Icons.info_outline_rounded;
    }
    return Row(
      children: [
        Icon(
          iconData,
          color: isHighlighted ? highlightColor : AppTheme.neutral600,
          size: 16,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
            color: isHighlighted ? highlightColor : null,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'ongoing':
        return AppTheme.success600;
      case 'upcoming':
        return AppTheme.primary600;
      case 'completed':
        return AppTheme.neutral600;
      default:
        return AppTheme.neutral600;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'ongoing':
        return 'In Progress';
      case 'upcoming':
        return 'Upcoming';
      case 'completed':
        return 'Completed';
      default:
        return 'Scheduled';
    }
  }
}
