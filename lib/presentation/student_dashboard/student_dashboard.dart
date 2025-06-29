import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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

  final ValueNotifier<bool> _isDarkMode = ValueNotifier(false);
  int _selectedIndex = 0; // Add this for bottom navigation

  @override
  void initState() {
    super.initState();
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
          .collection('students')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        final data = doc.data() ?? {};
        setState(() => _studentData = {
              ...data,
              'name': data['name'] ?? 'Unknown',
            });
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
          .map((doc) => {"id": doc.id, ...doc.data()})
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
          .map((doc) => {"id": doc.id, ...doc.data()})
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

  @override
  void dispose() {
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
                                          Expanded(
                                            child: _selectedIndex == 0
                                                ? _buildTodayTab()
                                                : _buildScheduleTab(),
                                          ),
                                        ],
                                      ),
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.today_rounded),
                  label: 'Today',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.schedule_rounded),
                  label: 'Schedule',
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

  List<Map<String, dynamic>> get _todayLectures {
    final today = DateTime.now();
    return _lectureSchedule.where((lecture) {
      if (lecture['date'] == null) return false;
      final lectureDate = DateTime.tryParse(lecture['date']);
      return lectureDate != null &&
          lectureDate.year == today.year &&
          lectureDate.month == today.month &&
          lectureDate.day == today.day;
    }).toList();
  }

  Widget _buildTodayTab() {
    return _showMap
        ? _buildMapView()
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_todayLectures.isNotEmpty)
                  ..._todayLectures.map((lecture) => LectureCardWidget(
                        lecture: {
                          ...lecture,
                          // Only use fallback if the value is null or empty string
                          "courseCode": (lecture["courseCode"] != null &&
                                  lecture["courseCode"]
                                      .toString()
                                      .trim()
                                      .isNotEmpty)
                              ? lecture["courseCode"].toString()
                              : "",
                          "courseTitle": (lecture["courseTitle"] != null &&
                                  lecture["courseTitle"]
                                      .toString()
                                      .trim()
                                      .isNotEmpty)
                              ? lecture["courseTitle"].toString()
                              : "",
                          "instructor": (lecture["instructor"] != null &&
                                  lecture["instructor"]
                                      .toString()
                                      .trim()
                                      .isNotEmpty)
                              ? lecture["instructor"].toString()
                              : "",
                          "startTime": (lecture["startTime"] != null &&
                                  lecture["startTime"]
                                      .toString()
                                      .trim()
                                      .isNotEmpty)
                              ? lecture["startTime"].toString()
                              : "",
                          "endTime": (lecture["endTime"] != null &&
                                  lecture["endTime"]
                                      .toString()
                                      .trim()
                                      .isNotEmpty)
                              ? lecture["endTime"].toString()
                              : "",
                        },
                        onViewMap: () => setState(() => _showMap = true),
                      )),
                if (_todayLectures.isEmpty)
                  const Center(child: Text("No lectures scheduled for today.")),
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
                      lecture: {
                        ...lecture,
                        "courseCode": (lecture["courseCode"] != null &&
                                lecture["courseCode"]
                                    .toString()
                                    .trim()
                                    .isNotEmpty)
                            ? lecture["courseCode"].toString()
                            : "",
                        "courseTitle": (lecture["courseTitle"] != null &&
                                lecture["courseTitle"]
                                    .toString()
                                    .trim()
                                    .isNotEmpty)
                            ? lecture["courseTitle"].toString()
                            : "",
                        "instructor": (lecture["instructor"] != null &&
                                lecture["instructor"]
                                    .toString()
                                    .trim()
                                    .isNotEmpty)
                            ? lecture["instructor"].toString()
                            : "",
                        "startTime": (lecture["startTime"] != null &&
                                lecture["startTime"]
                                    .toString()
                                    .trim()
                                    .isNotEmpty)
                            ? lecture["startTime"].toString()
                            : "",
                        "endTime": (lecture["endTime"] != null &&
                                lecture["endTime"].toString().trim().isNotEmpty)
                            ? lecture["endTime"].toString()
                            : "",
                      },
                      onViewMap: () => setState(() => _showMap = true),
                    ))
                .toList(),
      ),
    );
  }

  Widget _buildNextLectureCard() {
    final nextLecture = _lectureSchedule.first;
    return LectureCardWidget(
      lecture: {
        ...nextLecture,
        "courseCode": (nextLecture["courseCode"] != null &&
                nextLecture["courseCode"].toString().trim().isNotEmpty)
            ? nextLecture["courseCode"].toString()
            : "",
        "courseTitle": (nextLecture["courseTitle"] != null &&
                nextLecture["courseTitle"].toString().trim().isNotEmpty)
            ? nextLecture["courseTitle"].toString()
            : "",
        "instructor": (nextLecture["instructor"] != null &&
                nextLecture["instructor"].toString().trim().isNotEmpty)
            ? nextLecture["instructor"].toString()
            : "",
        "startTime": (nextLecture["startTime"] != null &&
                nextLecture["startTime"].toString().trim().isNotEmpty)
            ? nextLecture["startTime"].toString()
            : "",
        "endTime": (nextLecture["endTime"] != null &&
                nextLecture["endTime"].toString().trim().isNotEmpty)
            ? nextLecture["endTime"].toString()
            : "",
      },
      onViewMap: () => setState(() => _showMap = true),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        QuickActionButtonWidget(
          icon: 'calendar_today',
          label: 'Full Schedule',
          onTap: () => setState(() {
            _selectedIndex = 1;
          }),
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
                      onTap: () async {
                        setState(() => _notifications[index]["isRead"] = true);
                        // Mark as read in Firestore as well
                        try {
                          await FirebaseFirestore.instance
                              .collection('notifications')
                              .doc(_notifications[index]["id"])
                              .update({"isRead": true});
                        } catch (e) {
                          // Optionally handle error
                        }
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
                      _selectedIndex = 0;
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
                  // --- Settings Tab ---
                  _buildMenuItem(
                    icon: Icons.settings,
                    label: 'Settings',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/student-settings');
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
