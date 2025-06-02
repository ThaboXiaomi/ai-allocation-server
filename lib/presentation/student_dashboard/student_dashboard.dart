import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:lecture_room_allocator/widgets/custom_icon_widget.dart' as common;
import '../../theme/app_theme.dart';
import './widgets/attendance_stats_widget.dart';
import './widgets/lecture_card_widget.dart';
import './widgets/notification_card_widget.dart';
import './widgets/quick_action_button_widget.dart';
import './widgets/venue_map_widget.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({Key? key}) : super(key: key);

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _showMap = false;

  Map<String, dynamic>? _studentData;
  List<Map<String, dynamic>> _lectureSchedule = [];
  List<Map<String, dynamic>> _notifications = [];
  Map<String, dynamic>? _attendanceData;

  bool _isLoadingStudentData = true;
  bool _isLoadingLectureSchedule = true;
  bool _isLoadingNotifications = true;
  bool _isLoadingAttendanceData = true;

  String? _studentDataError;
  String? _lectureScheduleError;
  String? _notificationsError;
  String? _attendanceDataError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchStudentData();
    _fetchLectureSchedule();
    _fetchNotifications();
    _fetchAttendanceData();
  }

  Future<void> _fetchStudentData() async {
    setState(() => _isLoadingStudentData = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in");
      final doc = await FirebaseFirestore.instance.collection('Students').doc(user.uid).get();
      if (doc.exists) {
        setState(() => _studentData = doc.data());
      } else {
        setState(() => _studentDataError = "Student data not found.");
      }
    } catch (e) {
      setState(() => _studentDataError = "Failed to load student data.");
    } finally {
      setState(() => _isLoadingStudentData = false);
    }
  }

  Future<void> _fetchLectureSchedule() async {
    setState(() => _isLoadingLectureSchedule = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in");
      final querySnapshot = await FirebaseFirestore.instance
          .collection('timetables')
          .where('students', arrayContains: user.uid)
          .get();
      setState(() => _lectureSchedule = querySnapshot.docs.map((doc) => {"id": doc.id, ...doc.data() as Map<String, dynamic>}).toList());
    } catch (e) {
      setState(() => _lectureScheduleError = "Failed to load lecture schedule.");
    } finally {
      setState(() => _isLoadingLectureSchedule = false);
    }
  }

  Future<void> _fetchNotifications() async {
    setState(() => _isLoadingNotifications = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in");
      final querySnapshot = await FirebaseFirestore.instance.collection('notifications').where('studentId', isEqualTo: user.uid).orderBy('timestamp', descending: true).get();
      setState(() => _notifications = querySnapshot.docs.map((doc) => {"id": doc.id, ...doc.data() as Map<String, dynamic>}).toList());
    } catch (e) {
      setState(() => _notificationsError = "Failed to load notifications.");
    } finally {
      setState(() => _isLoadingNotifications = false);
    }
  }

  Future<void> _fetchAttendanceData() async {
    setState(() => _isLoadingAttendanceData = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in");
      final doc = await FirebaseFirestore.instance.collection('attendance').doc(user.uid).get();
      if (doc.exists) {
        setState(() => _attendanceData = doc.data());
      } else {
        setState(() => _attendanceDataError = "Attendance data not found.");
      }
    } catch (e) {
      setState(() => _attendanceDataError = "Failed to load attendance data.");
    } finally {
      setState(() => _isLoadingAttendanceData = false);
    }
  }

  // Add this function to handle student check-in
  Future<void> _studentCheckIn(String timetableId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      // Check if already checked in for this timetable today
      final existing = await FirebaseFirestore.instance
          .collection('student_check_ins')
          .where('studentId', isEqualTo: user.uid)
          .where('timetableId', isEqualTo: timetableId)
          .where('date', isEqualTo: DateTime.now().toIso8601String().substring(0, 10))
          .get();
      if (existing.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Already checked in for this lecture.')),

        );
        return;
      }
      await FirebaseFirestore.instance.collection('student_check_ins').add({
        'studentId': user.uid,
        'timetableId': timetableId,
        'timestamp': FieldValue.serverTimestamp(),
        'date': DateTime.now().toIso8601String().substring(0, 10),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Check-in successful!')),

      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Check-in failed: $e')),

      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // Show notifications panel
            },
          ),
        ],
      ),
      body: _isLoadingNotifications
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? const Center(child: Text('No notifications.'))
              : ListView.builder(
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    return NotificationCardWidget(
                      notification: _notifications[index],
                      onTap: () {
                        setState(() => _notifications[index]["isRead"] = true);
                        // Optionally show details or mark as read in Firestore
                      },
                    );
                  },
                ),
    );
  }

  Widget _buildStudentHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primary50,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppTheme.primary600,
            child: Text(
              _studentData!["name"]?.substring(0, 1) ?? "S",
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, ${_studentData!["name"] ?? "Student"}',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${_studentData!["program"] ?? "N/A"} - Year ${_studentData!["year"] ?? "N/A"}, Semester ${_studentData!["semester"] ?? "N/A"}',
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(_getCurrentDate(), style: TextStyle(fontWeight: FontWeight.w500)),
              Text(_getCurrentDay()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTodayTab() {
    return _showMap
        ? _buildMapView()
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_lectureSchedule.isNotEmpty) _buildNextLectureCard(),
                const SizedBox(height: 24),
                Text(
                  "Today's Schedule",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                if (_lectureSchedule.isNotEmpty)
                  ..._lectureSchedule.map((lecture) => LectureCardWidget(
                        lecture: lecture, // The external LectureCardWidget handles its own check-in
                                          // The onCheckIn prop is not part of its API.
                                          // If navigation is still needed after its internal check-in,
                                          // that would require modification of the external widget or a different approach.
                                          // For now, we rely on its internal check-in logic.
                        onViewMap: () => setState(() => _showMap = true),
                      )),
                const SizedBox(height: 24),
                if (_attendanceData != null) AttendanceStatsWidget(attendanceData: _attendanceData!),
                const SizedBox(height: 24),
                Text(
                  "Quick Actions",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildQuickActions(),
              ],
            ),
          );
  }

  Widget _buildScheduleTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _lectureSchedule.isEmpty
            ? [const Center(child: Text("No lectures scheduled."))]
            : _lectureSchedule.map((lecture) => LectureCardWidget(
                  lecture: lecture,
                  onViewMap: () => setState(() => _showMap = true), // Assuming map view is relevant here too
                )).toList(),
      ),
    );
  }

  Widget _buildNextLectureCard() {
    final nextLecture = _lectureSchedule.first;
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [AppTheme.primary800, AppTheme.primary600],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Next Lecture', style: TextStyle(color: Colors.white, fontSize: 16)),
            const SizedBox(height: 16),
            Text(
              nextLecture["courseCode"],
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              nextLecture["courseTitle"],
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.person, color: Colors.white),
                const SizedBox(width: 8),
                Text(nextLecture["instructor"] ?? '', style: TextStyle(color: Colors.white)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.access_time, color: Colors.white),
                const SizedBox(width: 8),
                Text('${nextLecture["startTime"]} - ${nextLecture["endTime"]}', style: TextStyle(color: Colors.white)),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _studentCheckIn(nextLecture["id"]),
              child: Text('Check In'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppTheme.primary700),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        QuickActionButtonWidget(
          icon: 'calendar_today',
          label: 'Full Schedule',
          onTap: () => _tabController.animateTo(1),
        ),
        QuickActionButtonWidget(
          icon: 'email',
          label: 'Contact Lecturer',
          onTap: () {},
        ),
        QuickActionButtonWidget(
          icon: 'report_problem',
          label: 'Report Issue',
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildMapView() {
    return Stack(
      children: [
        VenueMapWidget(
          currentBuilding: "B Block",
          destination: "Room B201",
          estimatedWalkTime: 5,
        ),
        Positioned(
          top: 16,
          left: 16,
          child: FloatingActionButton.small(
            backgroundColor: Colors.white,
            child: Icon(Icons.arrow_back, color: AppTheme.neutral700),
            onPressed: () => setState(() => _showMap = false),
          ),
        ),
      ],
    );
  }

  void _showNotificationsPanel(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Notifications', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _notifications.length,
                    separatorBuilder: (context, index) => Divider(),
                    itemBuilder: (context, index) => NotificationCardWidget(
                      notification: _notifications[index],
                      onTap: () {
                        setState(() => _notifications[index]["isRead"] = true);
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _getCurrentDate() {
    final now = DateTime.now();
    final months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    return '${months[now.month - 1]} ${now.day}, ${now.year}';
  }

  String _getCurrentDay() {
    final now = DateTime.now();
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[now.weekday - 1];
  }
}