import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:lecture_room_allocator/widgets/custom_icon_widget.dart'
    as common;
import '../../theme/app_theme.dart';
import './widgets/attendance_stats_widget.dart';
import './widgets/lecture_card_widget.dart';
import './widgets/notification_card_widget.dart';
import './widgets/quick_action_button_widget.dart';
import './widgets/venue_map_widget.dart';
import 'package:lecture_room_allocator/presentation/common/code_viewer_screen.dart';

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({Key? key}) : super(key: key);

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen>
    with SingleTickerProviderStateMixin {
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
  String? _settingsError; // New error variable for settings update

  final ValueNotifier<bool> _isDarkMode = ValueNotifier(false);

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
      final doc = await FirebaseFirestore.instance
          .collection('students') // <-- Capital "S"
          .doc(user.uid)
          .get();
      if (doc.exists) {
        setState(() => _studentData = doc.data());
      } else {
        setState(() => _studentDataError = "Student profile not found.");
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
      setState(() => _lectureSchedule = querySnapshot.docs
          .map((doc) => {"id": doc.id, ...doc.data() as Map<String, dynamic>})
          .toList());
    } catch (e) {
      setState(
          () => _lectureScheduleError = "Failed to load lecture schedule.");
    } finally {
      setState(() => _isLoadingLectureSchedule = false);
    }
  }

  Future<void> _fetchNotifications() async {
    setState(() => _isLoadingNotifications = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in");
      final querySnapshot = await FirebaseFirestore.instance
          .collection('notifications')
          .where('studentId', isEqualTo: user.uid)
          .orderBy('timestamp', descending: true)
          .get();
      setState(() => _notifications = querySnapshot.docs
          .map((doc) => {"id": doc.id, ...doc.data() as Map<String, dynamic>})
          .toList());
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
      final doc = await FirebaseFirestore.instance
          .collection('attendance')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        setState(() => _attendanceData = doc.data());
      } else {
        // attendance data not found, _attendanceData remains null
      }
    } catch (e) {
      setState(() => _attendanceDataError = "Failed to load attendance data.");
    } finally {
      setState(() => _isLoadingAttendanceData = false);
    }
  }

  // Function to handle student check-in
  Future<void> _studentCheckIn(String timetableId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final existing = await FirebaseFirestore.instance
          .collection('student_check_ins')
          .where('studentId', isEqualTo: user.uid)
          .where('timetableId', isEqualTo: timetableId)
          .where('date',
              isEqualTo: DateTime.now().toIso8601String().substring(0, 10))
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
    _isDarkMode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _isDarkMode,
      builder: (context, isDark, _) {
        return MaterialApp(
          theme: isDark ? AppTheme.darkTheme : AppTheme.lightTheme,
          home: Scaffold(
            endDrawer: _buildSidebarMenu(context, isDark),
            appBar: AppBar(
              title: const Text('Student Dashboard'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications),
                  onPressed: () {
                    _showNotificationsPanel(context);
                  },
                ),
                Builder(builder: (context) {
                  return IconButton(
                      icon: const Icon(Icons.menu),
                      onPressed: () => Scaffold.of(context).openEndDrawer());
                }),
              ],
            ),
            body: _isLoadingStudentData ||
                    _isLoadingLectureSchedule ||
                    _isLoadingNotifications ||
                    _isLoadingAttendanceData
                ? const Center(child: CircularProgressIndicator())
                : _studentDataError != null
                    ? Center(child: Text(_studentDataError!))
                    : _lectureScheduleError != null
                        ? Center(child: Text(_lectureScheduleError!))
                        : _notificationsError != null
                            ? Center(child: Text(_notificationsError!))
                            : _attendanceDataError != null
                                ? Center(child: Text(_attendanceDataError!))
                                : _showMap
                                    ? _buildMapView()
                                    : Column(
                                        children: [
                                          _buildStudentHeader(),
                                          TabBar(
                                            controller: _tabController,
                                            tabs: const [
                                              Tab(text: 'Today'),
                                              Tab(text: 'Schedule'),
                                            ],
                                          ),
                                          Expanded(
                                            child: TabBarView(
                                              controller: _tabController,
                                              children: [
                                                _buildTodayTab(),
                                                _buildScheduleTab(),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
          ),
        );
      },
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
                style: const TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hello, ${_studentData!["name"] ?? "Student"}',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
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
                Text(_getCurrentDate(),
                    style: const TextStyle(fontWeight: FontWeight.w500)),
                Text(_getCurrentDay()),
              ],
            ),
          ],
        ));
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
                const Text(
                  "Today's Schedule",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                if (_lectureSchedule.isNotEmpty)
                  ..._lectureSchedule.map((lecture) => LectureCardWidget(
                        lecture: lecture,
                        onViewMap: () => setState(() => _showMap = true),
                      )),
                const SizedBox(height: 24),
                if (_attendanceData != null)
                  AttendanceStatsWidget(attendanceData: _attendanceData ?? {}),
                const SizedBox(height: 24),
                _buildLatestNotificationSection(),
                const SizedBox(height: 24),
                const Text(
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
            : _lectureSchedule
                .map((lecture) => LectureCardWidget(
                      lecture: lecture,
                      onViewMap: () => setState(() => _showMap = true),
                    ))
                .toList(),
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
            const Text('Next Lecture',
                style: TextStyle(color: Colors.white, fontSize: 16)),
            const SizedBox(height: 16),
            Text(
              nextLecture["courseCode"],
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold),
            ),
            Text(
              nextLecture["courseTitle"],
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.person, color: Colors.white),
                const SizedBox(width: 8),
                Text(nextLecture["instructor"] ?? '',
                    style: const TextStyle(color: Colors.white)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.access_time, color: Colors.white),
                const SizedBox(width: 8),
                Text('${nextLecture["startTime"]} - ${nextLecture["endTime"]}',
                    style: const TextStyle(color: Colors.white)),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _studentCheckIn(nextLecture["id"]),
              child: const Text('Check In'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppTheme.primary700),
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
        const VenueMapWidget(
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
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
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
                      const Text('Notifications',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.close),
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
                    separatorBuilder: (context, index) => const Divider(),
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

  void _showAttendanceStatsPanel(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
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
                      const Text('Attendance Statistics',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    child: AttendanceStatsWidget(
                        attendanceData: _attendanceData ?? {}),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildLatestNotificationSection() {
    if (_notifications.isEmpty) {
      return const SizedBox.shrink();
    }

    final latestNotification = _notifications.first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Latest Notification",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        NotificationCardWidget(
          notification: latestNotification,
          onTap: () {
            _showNotificationsPanel(context);
          },
        ),
      ],
    );
  }

  String _getCurrentDate() {
    final now = DateTime.now();
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return '${months[now.month - 1]} ${now.day}, ${now.year}';
  }

  String _getCurrentDay() {
    final now = DateTime.now();
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    return days[now.weekday - 1];
  }

  Widget _buildSidebarMenu(BuildContext context, bool isDark) {
    final textColor = isDark ? Colors.white : AppTheme.primary900;
    final subTextColor = isDark ? Colors.white70 : AppTheme.neutral600;
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // Facebook-style header
            Container(
              color: AppTheme.primary50,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppTheme.primary300,
                    child:
                        const Icon(Icons.school, size: 32, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _studentData?["name"] ?? "Student",
                          style: AppTheme.lightTheme.textTheme.titleLarge
                              ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: textColor),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _studentData?["email"] ?? "student@university.edu",
                          style: AppTheme.lightTheme.textTheme.bodySmall
                              ?.copyWith(color: subTextColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                children: [
                  _buildMenuItem(
                    icon: Icons.dashboard,
                    label: 'Dashboard',
                    onTap: () {
                      Navigator.pop(context);
                    },
                    textColor: textColor,
                  ),
                  _buildMenuItem(
                    icon: Icons.schedule,
                    label: 'My Schedule',
                    onTap: () {
                      Navigator.pop(context);
                      _tabController.animateTo(0);
                    },
                    textColor: textColor,
                  ),
                  _buildMenuItem(
                    icon: Icons.contacts_outlined,
                    label: 'Lecturer Information',
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                "Lecturer Information: Feature coming soon!")),
                      );
                    },
                    textColor: textColor,
                  ),
                  _buildMenuItem(
                    icon: Icons.pie_chart_outline,
                    label: 'Attendance Stats',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CodeViewerScreen(
                            filePath:
                                'lib/presentation/student_dashboard/widgets/attendance_stats_widget.dart',
                            fileName: 'attendance_stats_widget.dart',
                          ),
                        ),
                      );
                    },
                    textColor: textColor,
                  ),
                  _buildMenuItem(
                    icon: Icons.notifications,
                    label: 'Notifications',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CodeViewerScreen(
                            filePath:
                                'lib/presentation/student_dashboard/widgets/notification_card_widget.dart',
                            fileName: 'notification_card_widget.dart',
                          ),
                        ),
                      );
                    },
                    textColor: textColor,
                  ),
                  _buildMenuItem(
                    icon: Icons.map,
                    label: 'Venue Map',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CodeViewerScreen(
                            filePath:
                                'lib/presentation/student_dashboard/widgets/venue_map_widget.dart',
                            fileName: 'venue_map_widget.dart',
                          ),
                        ),
                      );
                    },
                    textColor: textColor,
                  ),
                  const Divider(),
                  SwitchListTile(
                    secondary: Icon(
                        _isDarkMode.value ? Icons.dark_mode : Icons.light_mode,
                        color: textColor),
                    title:
                        Text('Dark Mode', style: TextStyle(color: textColor)),
                    value: _isDarkMode.value,
                    onChanged: (val) => _isDarkMode.value = val,
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: const Text('Logout',
                        style: TextStyle(color: Colors.red)),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushReplacementNamed(context, '/student-login');
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                '© 2025 Lecturer Room Allocator',
                style: TextStyle(color: subTextColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primary600),
      title: Text(
        label,
        style:
            AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(color: textColor),
      ),
      onTap: onTap,
    );
  }
}
