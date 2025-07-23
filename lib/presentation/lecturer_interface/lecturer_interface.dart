import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/custom_icon_widget.dart';
import './widgets/attendance_stats_widget.dart';
import './widgets/class_timer_widget.dart';
import './widgets/lecture_card_widget.dart';
import './widgets/notification_card_widget.dart';
import './widgets/quick_action_button_widget.dart';
import './widgets/venue_map_widget.dart';

// Lecturer dashboard interface
class LecturerInterface extends StatefulWidget {
  const LecturerInterface({super.key});

  @override
  State<LecturerInterface> createState() => _LecturerInterfaceState();
}

class _LecturerInterfaceState extends State<LecturerInterface>
    with SingleTickerProviderStateMixin {
  // State variables
  late TabController _tabController;
  bool _isCheckedIn = false;
  int _selectedLectureIndex = -1;
  bool _showMap = false;
  int _selectedNavIndex = 0;

  // Streams for real-time data
  Stream<List<Map<String, dynamic>>> _lecturesStream() =>
      FirebaseFirestore.instance
          .collection('timetables')
          .where('lecturerId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
          .snapshots()
          .map((snapshot) =>
              snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());

  Stream<List<Map<String, dynamic>>> _notificationsStream() =>
      FirebaseFirestore.instance
          .collection('notifications')
          .orderBy('timestamp', descending: true)
          .snapshots()
          .map((snapshot) =>
              snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());

  // Quick actions configuration
  final List<Map<String, dynamic>> _quickActions = [
    {
      'id': 'report_issue',
      'icon': 'report_problem',
      'title': 'Report Issue',
      'color': AppTheme.warning600,
    },
  ];

  // Navigation items
  final List<_DashboardNavItem> _navItems = [
    _DashboardNavItem(
      icon: 'fact_check',
      label: 'Attendance',
      widgetBuilder: (context) =>
          AttendanceStatsWidget(courseId: 'sampleCourseId'),
    ),
    _DashboardNavItem(
      icon: 'timer',
      label: 'Class Timer',
      widgetBuilder: (context) => ClassTimerWidget(classId: 'sampleClassId'),
    ),
    _DashboardNavItem(
      icon: 'notifications_active',
      label: 'Notifications',
      widgetBuilder: (context) => _LecturerInterfaceState._buildNotificationsView(context),
    ),
    _DashboardNavItem(
      icon: 'map',
      label: 'Venue Map',
      widgetBuilder: (context) =>
          VenueMapWidget(fromVenue: 'A101', toVenue: 'B202'),
    ),
  ];

  final ValueNotifier<bool> _isDarkMode = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _isDarkMode.dispose();
    super.dispose();
  }

  // Log check-in to Firestore
  Future<void> _logCheckIn(String timetableId) async {
    try {
      await FirebaseFirestore.instance.collection('check_ins').add({
        'timetableId': timetableId,
        'timestamp': FieldValue.serverTimestamp(),
        'lecturerId': FirebaseAuth.instance.currentUser?.uid,
      });
    } catch (e) {
      debugPrint('Error logging check-in: $e');
    }
  }

  // Handle check-in action
  void _handleCheckIn(int index, String lectureId) {
    setState(() {
      _isCheckedIn = true;
      _selectedLectureIndex = index;
    });
    _logCheckIn(lectureId);
  }

  // Handle end class action
  void _handleEndClass() {
    setState(() {
      _isCheckedIn = false;
      _selectedLectureIndex = -1;
    });
  }

  // Handle navigation item tap
  void _onNavTap(int index) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.only(top: 16),
        child: _navItems[index].widgetBuilder!(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _isDarkMode,
      builder: (context, isDark, _) {
        return MaterialApp(
          theme: isDark ? AppTheme.darkTheme : AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
          home: Scaffold(
            drawer: _buildSimpleDrawer(context),
            endDrawer: _buildSidebarMenu(context, isDark),
            appBar: _buildAppBar(context, isDark),
            body: _buildBody(),
            bottomNavigationBar: _buildBottomNavigationBar(),
          ),
        );
      },
    );
  }

  // Build the app bar with lecturer info and actions
  AppBar _buildAppBar(BuildContext context, bool isDark) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      title: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('lecturers')
            .doc(FirebaseAuth.instance.currentUser?.uid)
            .get(),
        builder: (context, snapshot) {
          final lecturer = snapshot.data?.data() as Map<String, dynamic>?;

          return Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: AppTheme.primary100,
                child: const CustomIconWidget(
                  iconName: 'account_circle',
                  color: AppTheme.primary600,
                  size: 32,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome, Lecturer',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppTheme.primary900,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    'Have a productive day!',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.neutral600,
                        ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
      actions: [
        IconButton(
          icon: const Icon(
            Icons.notifications_active,
            color: AppTheme.primary600,
          ),
          onPressed: () => _onNavTap(2), // Show notifications
          tooltip: 'Notifications',
        ),
        IconButton(
          icon: Icon(
            isDark ? Icons.dark_mode : Icons.light_mode,
            color: AppTheme.primary600,
          ),
          tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
          onPressed: () => _isDarkMode.value = !isDark,
        ),
      ],
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
    );
  }

  // Build the main body with lectures stream
  Widget _buildBody() {
    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF8FBFF), Color(0xFFEAF1FB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: _lecturesStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return const Center(child: Text('Error loading lectures.'));
            }
            final lectures = snapshot.data ?? [];
            return _isCheckedIn && _selectedLectureIndex != -1
                ? _buildActiveClassView(lectures[_selectedLectureIndex])
                : _buildScheduleView(lectures);
          },
        ),
      ),
    );
  }

  // Build the bottom navigation bar
  BottomNavigationBar _buildBottomNavigationBar() {
    return BottomNavigationBar(
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.today),
          label: "Today's Schedule",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.schedule),
          label: 'Upcoming Lectures',
        ),
      ],
      currentIndex: _tabController.index,
      onTap: (index) {
        _tabController.animateTo(index);
        setState(() {});
      },
    );
  }

  // Build schedule view with tabs
  Widget _buildScheduleView(List<Map<String, dynamic>> lectures) {
    final today = DateTime.now();

    bool isSameDay(DateTime a, DateTime b) =>
        a.year == b.year && a.month == b.month && a.day == b.day;

    DateTime? parseLectureDate(dynamic dateField) {
      if (dateField is Timestamp) return dateField.toDate();
      if (dateField is String) return DateTime.tryParse(dateField);
      return null;
    }

    final todayLectures = lectures.where((lecture) {
      final date = parseLectureDate(lecture['date']);
      return date != null && isSameDay(date, today);
    }).toList();

    final upcomingLectures = lectures.where((lecture) {
      final date = parseLectureDate(lecture['date']);
      return date != null && date.isAfter(today);
    }).toList();

    return TabBarView(
      controller: _tabController,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 18),
            _buildQuickActionsRow(),
            const SizedBox(height: 10),
            Expanded(
              child: _buildLecturesList(
                todayLectures,
                emptyText: 'No lectures scheduled for today.',
              ),
            ),
          ],
        ),
        _buildLecturesList(
          upcomingLectures,
          emptyText: 'No upcoming lectures scheduled.',
        ),
      ],
    );
  }

  // Build notification summary card
  Widget _buildNotificationSummary(List<Map<String, dynamic>> notifications) {
    final unreadCount = notifications.where((n) => !n['isRead']).length;
    return InkWell(
      onTap: () => _onNavTap(2), // Show notifications
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.primary50,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary100.withOpacity(0.12),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primary100,
                shape: BoxShape.circle,
              ),
              child: const CustomIconWidget(
                iconName: 'notifications_active',
                color: AppTheme.primary600,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                'You have $unreadCount unread notification${unreadCount > 1 ? 's' : ''}',
                style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primary700,
                ),
              ),
            ),
            const CustomIconWidget(
              iconName: 'arrow_forward_ios',
              color: AppTheme.primary600,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  // Build lectures list
  Widget _buildLecturesList(List<Map<String, dynamic>> lectures,
      {required String emptyText}) {
    if (lectures.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CustomIconWidget(
                iconName: 'event_busy',
                color: AppTheme.neutral300,
                size: 72,
              ),
              const SizedBox(height: 18),
              Text(
                emptyText,
                textAlign: TextAlign.center,
                style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                  color: AppTheme.neutral500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: lectures.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final lecture = lectures[index];
        final date = parseLectureDate(lecture['date']);
        return LectureCardWidget(
          lecture: lecture,
          onCheckIn: () => _handleCheckIn(index, lecture['id']),
        );
      },
    );
  }

  // Build quick actions row
  Widget _buildQuickActionsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppTheme.primary900,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _quickActions.map((action) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: QuickActionButtonWidget(
                    action: action,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${action['title']} tapped')),
                      );
                    },
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // Build active class view
  Widget _buildActiveClassView(Map<String, dynamic> lecture) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.primary700, AppTheme.primary400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(32),
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary700.withAlpha(30),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lecture['courseCode'] ?? '',
                      style:
                          AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      lecture['courseTitle'] ?? '',
                      style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                        color: Colors.white.withAlpha(220),
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              ClassTimerWidget(classId: lecture['id']),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: AttendanceStatsWidget(courseId: lecture['id']),
            ),
          ),
        ),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: ElevatedButton.icon(
            icon: const CustomIconWidget(
              iconName: 'logout',
              color: Colors.white,
              size: 20,
            ),
            label: const Text('End Class'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            onPressed: _handleEndClass,
          ),
        ),
      ],
    );
  }

  // Build notifications view
  static Widget _buildNotificationsView(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('notifications')
          .orderBy('timestamp', descending: true)
          .snapshots()
          .map((snapshot) =>
              snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList()),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Error loading notifications.'));
        }
        final notifications = snapshot.data ?? [];
        return ListView.builder(
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            return NotificationCardWidget(
              notification: notifications[index],
              onTap: () {},
            );
          },
        );
      },
    );
  }

  // Build attendance view with student check-ins
  Widget _buildAttendanceView(BuildContext context) {
    final lecturerId = FirebaseAuth.instance.currentUser?.uid;
    if (lecturerId == null) {
      return const Center(child: Text('Please log in to view attendance.'));
    }

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _lecturesStream(),
      builder: (context, lectureSnapshot) {
        if (lectureSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (lectureSnapshot.hasError || !lectureSnapshot.hasData) {
          return const Center(child: Text('Error loading lectures.'));
        }

        final lectures = lectureSnapshot.data ?? [];
        if (lectures.isEmpty) {
          return const Center(child: Text('No lectures found.'));
        }

        return ListView.builder(
          itemCount: lectures.length,
          itemBuilder: (context, index) {
            final lecture = lectures[index];
            return FutureBuilder<List<String>>(
              future: _fetchCheckedInStudentNames(lecture['id']),
              builder: (context, studentSnapshot) {
                if (studentSnapshot.connectionState == ConnectionState.waiting) {
                  return ListTile(
                    title: Text(lecture['courseTitle'] ?? 'Lecture'),
                    subtitle: const Text('Loading attendance...'),
                  );
                }
                if (studentSnapshot.hasError || !studentSnapshot.hasData) {
                  return ListTile(
                    title: Text(lecture['courseTitle'] ?? 'Lecture'),
                    subtitle: const Text('Error loading attendance.'),
                  );
                }

                final studentNames = studentSnapshot.data ?? [];
                return ExpansionTile(
                  title: Text(lecture['courseTitle'] ?? 'Lecture'),
                  subtitle: Text('Checked in: ${studentNames.length} students'),
                  children: studentNames.isEmpty
                      ? [const ListTile(title: Text('No students checked in.'))]
                      : studentNames.map((name) => ListTile(title: Text(name))).toList(),
                );
              },
            );
          },
        );
      },
    );
  }

  // Fetch checked-in student names for a specific lecture
  Future<List<String>> _fetchCheckedInStudentNames(String timetableId) async {
    final checkInsSnapshot = await FirebaseFirestore.instance
        .collection('student_check_ins')
        .where('timetableId', isEqualTo: timetableId)
        .get();

    final studentIds = checkInsSnapshot.docs
        .map((doc) => doc['studentId'] as String)
        .toList();

    if (studentIds.isEmpty) return [];

    final studentsSnapshot = await FirebaseFirestore.instance
        .collection('students')
        .where(FieldPath.documentId, whereIn: studentIds)
        .get();

    return studentsSnapshot.docs
        .map((doc) => doc['name'] as String? ?? 'Unknown')
        .toList();
  }

  // Show venue map bottom sheet
  void _showVenueMapBottomSheet(
      BuildContext context, Map<String, dynamic> lecture) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return VenueMapWidget(
          fromVenue: lecture['originalVenue'] ?? '',
          toVenue: lecture['currentVenue'] ?? '',
        );
      },
    );
  }

  // Build menu item widget
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
        style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(color: textColor),
      ),
      onTap: onTap,
    );
  }

  // Build sidebar menu
  Widget _buildSidebarMenu(BuildContext context, bool isDark) {
    final textColor = isDark ? Colors.white : AppTheme.primary900;
    final subTextColor = isDark ? Colors.white70 : AppTheme.neutral600;

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Container(
              color: AppTheme.primary50,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppTheme.primary300,
                    child: const Icon(Icons.person, size: 32, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Lecturer',
                          style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'lecturer@allocation.edu',
                          style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                            color: subTextColor,
                          ),
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
                    onTap: () => Navigator.pop(context),
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
                    icon: Icons.check_circle_outline,
                    label: 'Attendance',
                    onTap: () {
                      Navigator.pop(context);
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                        ),
                        builder: (context) => Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: _buildAttendanceView(context),
                        ),
                      );
                    },
                    textColor: textColor,
                  ),
                  _buildMenuItem(
                    icon: Icons.timer,
                    label: 'Class Timer',
                    onTap: () {
                      Navigator.pop(context);
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                        ),
                        builder: (context) => Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: ClassTimerWidget(classId: 'sampleClassId'),
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
                      _onNavTap(2); // Use existing nav tap for notifications
                    },
                    textColor: textColor,
                  ),
                  _buildMenuItem(
                    icon: Icons.report_problem,
                    label: 'Report Issue',
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Report Issue tapped')),
                      );
                    },
                    textColor: textColor,
                  ),
                  const Divider(),
                  SwitchListTile(
                    secondary: Icon(
                      _isDarkMode.value ? Icons.dark_mode : Icons.light_mode,
                    ),
                    title: Text('Dark Mode', style: TextStyle(color: textColor)),
                    value: _isDarkMode.value,
                    onChanged: (val) => _isDarkMode.value = val,
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: const Text('Logout', style: TextStyle(color: Colors.red)),
                    onTap: () {
                      Navigator.pop(context);
                      FirebaseAuth.instance.signOut();
                      Navigator.pushReplacementNamed(context, '/lecturer-login');
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                '© 2025 University Room Allocator',
                style: TextStyle(color: subTextColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build simple drawer
  Widget _buildSimpleDrawer(BuildContext context) {
    return Drawer(
      child: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('lecturers')
            .doc(FirebaseAuth.instance.currentUser?.uid)
            .get(),
        builder: (context, snapshot) {
          final lecturer = snapshot.data?.data() as Map<String, dynamic>?;

          return ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: const BoxDecoration(color: Colors.blue),
                child: lecturer == null
                    ? const Center(child: CircularProgressIndicator(color: Colors.white))
                    : _buildDrawerHeaderContent(lecturer),
              ),
              ListTile(
                leading: const Icon(Icons.check_circle_outline),
                title: const Text('Attendance'),
                onTap: () {
                  Navigator.pop(context);
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    builder: (context) => Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: _buildAttendanceView(context),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.timer),
                title: const Text('Class Timer'),
                onTap: () {
                  Navigator.pop(context);
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    builder: (context) => Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: ClassTimerWidget(classId: 'sampleClassId'),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.notifications),
                title: const Text('Notifications'),
                onTap: () {
                  Navigator.pop(context);
                  _onNavTap(2);
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Logout'),
                onTap: () async {
                  Navigator.pop(context);
                  await FirebaseAuth.instance.signOut();
                  Navigator.pushReplacementNamed(context, '/lecturer-login');
                },
              ),
            ],
          );
        },
      ),
    );
  }

  // Build drawer header content
  Widget _buildDrawerHeaderContent(Map<String, dynamic> lecturer) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const CircleAvatar(
              radius: 28,
              backgroundColor: Colors.white,
              child: Icon(Icons.person, size: 32, color: Colors.blue),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lecturer['name'] ?? 'Lecturer',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lecturer['email'] ?? '',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Icon(Icons.school, color: Colors.white70, size: 18),
            const SizedBox(width: 6),
            Text(
              lecturer['school'] ?? '',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(Icons.badge, color: Colors.white70, size: 18),
            const SizedBox(width: 6),
            Text(
              'Staff ID: ${lecturer['staffId'] ?? ''}',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      ],
    );
  }

  // Fetch students data
  Future<List<Map<String, dynamic>>> _fetchStudents(List<dynamic> studentIds) async {
    if (studentIds.isEmpty) return [];
    final snapshot = await FirebaseFirestore.instance
        .collection('students')
        .where(FieldPath.documentId, whereIn: studentIds)
        .get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  // Parse lecture date from dynamic input
  DateTime? parseLectureDate(dynamic dateField) {
    if (dateField is Timestamp) return dateField.toDate();
    if (dateField is String) return DateTime.tryParse(dateField);
    return null;
  }
}

// Helper class for navigation items
class _DashboardNavItem {
  final String icon;
  final String label;
  final WidgetBuilder? widgetBuilder;

  const _DashboardNavItem({
    required this.icon,
    required this.label,
    this.widgetBuilder,
  });
}

// ClassTimerWidget definition
class ClassTimerWidget extends StatefulWidget {
  final String classId;

  const ClassTimerWidget({super.key, required this.classId});

  @override
  _ClassTimerWidgetState createState() => _ClassTimerWidgetState();
}

class _ClassTimerWidgetState extends State<ClassTimerWidget> {
  int? _remainingSeconds;
  String? _lectureTitle;
  bool _isRunning = false;
  Timer? _timer;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLectureData();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchLectureData() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('timetables')
          .doc(widget.classId)
          .get();
      final data = snapshot.data() as Map<String, dynamic>?;
      if (data != null) {
        setState(() {
          _lectureTitle = data['courseTitle'] ?? 'Lecture';
          final durationMinutes = data['duration'] ?? 60; // Default to 60 minutes
          _remainingSeconds = durationMinutes * 60;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching lecture data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _startPauseTimer() {
    if (_isLoading || _remainingSeconds == null) return;

    if (_isRunning) {
      _timer?.cancel();
    } else {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_remainingSeconds! > 0) {
          setState(() {
            _remainingSeconds = _remainingSeconds! - 1;
          });
        } else {
          _timer?.cancel();
          setState(() {
            _isRunning = false;
          });
        }
      });
    }
    setState(() {
      _isRunning = !_isRunning;
    });
  }

  String _formatTime(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _lectureTitle ?? 'Lecture',
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.primary900,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Text(
            _remainingSeconds != null ? _formatTime(_remainingSeconds!) : '00:00',
            style: AppTheme.lightTheme.textTheme.headlineMedium?.copyWith(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: AppTheme.primary600,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _isRunning ? 'Running' : 'Paused',
            style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
              color: AppTheme.neutral600,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            icon: Icon(_isRunning ? Icons.pause : Icons.play_arrow),
            label: Text(_isRunning ? 'Pause' : 'Start'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _startPauseTimer,
          ),
        ],
      ),
    );
  }
}