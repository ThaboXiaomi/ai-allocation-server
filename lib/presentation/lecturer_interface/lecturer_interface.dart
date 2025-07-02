import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../theme/app_theme.dart';
import '../../widgets/custom_icon_widget.dart';
import './widgets/attendance_stats_widget.dart';
import './widgets/class_timer_widget.dart';
import './widgets/lecture_card_widget.dart';
import './widgets/notification_card_widget.dart';
import './widgets/quick_action_button_widget.dart';
import './widgets/venue_map_widget.dart';

class LecturerInterface extends StatefulWidget {
  const LecturerInterface({Key? key}) : super(key: key);

  @override
  State<LecturerInterface> createState() => _LecturerInterfaceState();
}

class _LecturerInterfaceState extends State<LecturerInterface>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isCheckedIn = false;
  int _selectedLectureIndex = -1;
  bool _showMap = false;

  Stream<List<Map<String, dynamic>>> _lecturesStream = FirebaseFirestore
      .instance
      .collection('timetables')
      .where('lecturerId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
      .snapshots()
      .map((snapshot) =>
          snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());

  Stream<List<Map<String, dynamic>>> _notificationsStream = FirebaseFirestore
      .instance
      .collection('notifications')
      // .where('lecturerId', isEqualTo: FirebaseAuth.instance.currentUser?.uid) // Example filter
      .orderBy('timestamp', descending: true)
      .snapshots()
      .map((snapshot) =>
          snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());

  // Define quick actions data
  final List<Map<String, dynamic>> _quickActions = [
    {
      "id": "report_issue",
      "icon":
          "report_problem", // Changed to a more appropriate icon for "Report Issue"
      "title": "Report Issue",
      "color": AppTheme.warning600,
    }
    // Add more actions as needed, ensuring icons are in CustomIconWidget
  ];

  int _selectedNavIndex = 0;

  final List<_DashboardNavItem> _navItems = [
    _DashboardNavItem(
      icon: 'fact_check', // Attendance
      label: 'Attendance',
      widgetBuilder: (context) =>
          AttendanceStatsWidget(courseId: 'sampleCourseId'),
    ),
    _DashboardNavItem(
      icon: 'timer', // Class Timer
      label: 'Class Timer',
      widgetBuilder: (context) => ClassTimerWidget(classId: 'sampleClassId'),
    ),
    _DashboardNavItem(
      icon: 'notifications_active', // Notifications
      label: 'Notifications',
      widgetBuilder: (context) =>
          const SizedBox.shrink(), // Will open notifications panel
    ),
    _DashboardNavItem(
      icon: 'map', // Venue Map
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

  Future<void> _logCheckIn(String timetableId) async {
    try {
      await FirebaseFirestore.instance.collection('check_ins').add({
        'timetableId': timetableId,
        'timestamp': FieldValue.serverTimestamp(),
        'lecturerId': 'currentLecturerId', // Replace with actual lecturer ID
      });
    } catch (e) {
      debugPrint('Error logging check-in: $e');
    }
  }

  void _handleCheckIn(int index, String lectureId) {
    setState(() {
      _isCheckedIn = true;
      _selectedLectureIndex = index;
    });
    _logCheckIn(lectureId);
  }

  void _handleEndClass() {
    setState(() {
      _isCheckedIn = false;
      _selectedLectureIndex = -1;
    });
  }

  void _onNavTap(int index) {
    if (_navItems[index].widgetBuilder == null) {
      _showNotificationsPanel(context);
    } else {
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
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _isDarkMode,
      builder: (context, isDark, _) {
        return MaterialApp(
            theme: isDark ? AppTheme.darkTheme : AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme, // Add this line for completeness
            themeMode:
                isDark ? ThemeMode.dark : ThemeMode.light, // Add this line
            home: Scaffold(
              drawer: _buildSimpleDrawer(context),
              endDrawer: _buildSidebarMenu(context, isDark),
              appBar: AppBar(
                elevation: 0,
                backgroundColor: Colors.transparent,
                title: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
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
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: AppTheme.primary900,
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        Text(
                          'Have a productive day!',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.neutral600,
                                  ),
                        ),
                      ],
                    ),
                  ],
                ),
                actions: [
                  IconButton(
                    icon: const CustomIconWidget(
                      iconName: 'notifications',
                      color: AppTheme.primary600,
                    ),
                    onPressed: () => _showNotificationsPanel(context),
                    tooltip: 'Notifications',
                  ),
                  // Add a dark mode toggle button to the AppBar actions
                  IconButton(
                    icon: Icon(
                      isDark ? Icons.dark_mode : Icons.light_mode,
                      color: AppTheme.primary600,
                    ),
                    tooltip:
                        isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
                    onPressed: () {
                      _isDarkMode.value = !isDark;
                    },
                  ),
                ],
              ),
              body: SafeArea(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFF8FBFF), Color(0xFFEAF1FB)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: StreamBuilder<List<Map<String, dynamic>>>(
                    stream: _lecturesStream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return const Center(
                            child: Text('Error loading lectures.'));
                      }
                      final lectures = snapshot.data ?? [];
                      return _isCheckedIn && _selectedLectureIndex != -1
                          ? _buildActiveClassView(
                              lectures[_selectedLectureIndex])
                          : _buildScheduleView(lectures);
                    },
                  ),
                ),
              ),
              // REPLACE the old bottomNavigationBar with the new one below:
              bottomNavigationBar: BottomNavigationBar(
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
              ),
            ));
      },
    );
  }

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

    return Column(
      children: [
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: _notificationsStream,
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data!.any((n) => !n["isRead"])) {
              return _buildNotificationSummary(snapshot.data!);
            }
            return const SizedBox.shrink();
          },
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppTheme.neutral300.withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TabBar(
            controller: _tabController,
            labelColor: AppTheme.primary700,
            unselectedLabelColor: AppTheme.neutral400,
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: AppTheme.primary50,
            ),
            tabs: const [
              Tab(text: "Today's Schedule"),
              Tab(text: "Upcoming Lectures"),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildLecturesList(todayLectures,
                  emptyText:
                      "No lectures scheduled for today.\nAll schedules shown are assigned to you by the admin."),
              _buildLecturesList(upcomingLectures,
                  emptyText:
                      "No upcoming lectures.\nAll schedules shown are assigned to you by the admin."),
            ],
          ),
        ),
        const SizedBox(height: 8),
        _buildQuickActionsRow(),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildNotificationSummary(List<Map<String, dynamic>> notifications) {
    int unreadCount = notifications.where((n) => !n["isRead"]).length;
    return InkWell(
        onTap: () => _showNotificationsPanel(context),
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
        ));
  }

  Widget _buildLecturesList(List<Map<String, dynamic>> lectures,
      {String? emptyText}) {
    return lectures.isEmpty
        ? Center(
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
                    emptyText ?? 'No lectures scheduled',
                    textAlign: TextAlign.center,
                    style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                      color: AppTheme.neutral500,
                    ),
                  ),
                ],
              ),
            ),
          )
        : ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            itemCount: lectures.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final lecture = lectures[index];
              final date = (() {
                final d = lecture['date'];
                if (d is Timestamp) return d.toDate();
                if (d is String) return DateTime.tryParse(d);
                return null;
              })();
              final formattedDate = date != null
                  ? "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}"
                  : '';
              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  leading:
                      const Icon(Icons.class_, color: Colors.blue, size: 36),
                  title: Text(
                    "${lecture['courseCode'] ?? ''} - ${lecture['courseTitle'] ?? ''}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Date: $formattedDate"),
                      Text(
                          "Time: ${lecture['startTime'] ?? ''} - ${lecture['endTime'] ?? ''}"),
                      Text("Room: ${lecture['room'] ?? ''}"),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.info_outline, color: Colors.grey),
                    onPressed: () {
                      // Optionally show more details or actions
                    },
                  ),
                ),
              );
            },
          );
  }

  Widget _buildEmptyUpcomingLectures() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CustomIconWidget(
            iconName: 'event_note',
            color: AppTheme.neutral300,
            size: 72,
          ),
          const SizedBox(height: 18),
          Text(
            'Your upcoming lectures will appear here',
            style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
              color: AppTheme.neutral500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Quick Actions",
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
                        SnackBar(content: Text("${action['title']} tapped")),
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
                      lecture["courseCode"],
                      style:
                          AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      lecture["courseTitle"],
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
              ClassTimerWidget(classId: lecture["id"]),
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
              child: AttendanceStatsWidget(courseId: lecture["id"]),
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

  void _showNotificationsPanel(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: _notificationsStream,
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
                  onTap: () {
                    // Handle notification tap
                  },
                );
              },
            );
          },
        );
      },
    );
  }

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
          fromVenue: lecture["originalVenue"],
          toVenue: lecture["currentVenue"],
        );
      },
    );
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
                        const Icon(Icons.person, size: 32, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Lecturer',
                            style: AppTheme.lightTheme.textTheme.titleLarge
                                ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: textColor)),
                        const SizedBox(height: 4),
                        Text('lecturer@university.edu',
                            style: AppTheme.lightTheme.textTheme.bodySmall
                                ?.copyWith(color: subTextColor)),
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
                      if (Navigator.of(context).canPop()) {
                        Navigator.pop(context);
                      }
                    },
                    textColor: textColor,
                  ),
                  _buildMenuItem(
                    icon: Icons.schedule,
                    label: 'My Schedule',
                    onTap: () {
                      if (Navigator.of(context).canPop()) {
                        Navigator.pop(context);
                      }
                      _tabController.animateTo(0);
                    },
                    textColor: textColor,
                  ),
                  _buildMenuItem(
                    icon: Icons.notifications,
                    label: 'Notifications',
                    onTap: () {
                      if (Navigator.of(context).canPop()) {
                        Navigator.pop(context);
                      }
                      _showNotificationsPanel(context);
                    },
                    textColor: textColor,
                  ),
                  _buildMenuItem(
                    icon: Icons.map,
                    label: 'Venue Map',
                    onTap: () {
                      if (Navigator.of(context).canPop()) {
                        Navigator.pop(context);
                      }
                      setState(() => _showMap = true);
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
                      if (Navigator.of(context).canPop()) {
                        Navigator.pop(context);
                      }
                      Navigator.pushReplacementNamed(
                          context, '/lecturer-login');
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

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primary600),
      title: Text(label,
          style: AppTheme.lightTheme.textTheme.bodyLarge
              ?.copyWith(color: textColor)),
      onTap: onTap,
    );
  }

  Future<List<Map<String, dynamic>>> _fetchStudents(
      List<dynamic> studentIds) async {
    if (studentIds.isEmpty) return [];
    final snapshot = await FirebaseFirestore.instance
        .collection('students')
        .where(FieldPath.documentId, whereIn: studentIds)
        .get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

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
            children: <Widget>[
              DrawerHeader(
                decoration: BoxDecoration(color: Colors.blue),
                child: lecturer == null
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 28,
                                backgroundColor: Colors.white,
                                child:
                                    Icon(Icons.person, size: 32, color: Colors.blue),
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
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(Icons.school, color: Colors.white70, size: 18),
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
                              Icon(Icons.badge, color: Colors.white70, size: 18),
                              const SizedBox(width: 6),
                              Text(
                                'Staff ID: ${lecturer['staffId'] ?? ''}',
                                style: const TextStyle(color: Colors.white70, fontSize: 14),
                              ),
                            ],
                          ),
                        ],
                      ),
              ),
              ListTile(
                leading: Icon(Icons.check_circle_outline),
                title: Text('Attendance'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          AttendanceStatsWidget(courseId: 'sampleCourseId'),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.timer),
                title: Text('Class Timer'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ClassTimerWidget(classId: 'sampleClassId'),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.notifications),
                title: Text('Notifications'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NotificationCardWidget(
                        notification: const {
                          "id": "notif1",
                          "isRead": false,
                          "type": "system",
                        },
                        onTap: () {},
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.map),
                title: Text('Venue Map'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => VenueMapWidget(
                        fromVenue: 'A101',
                        toVenue: 'B202',
                      ),
                    ),
                  );
                },
              ),
              const Divider(),
              ListTile(
                leading: Icon(Icons.logout),
                title: Text('Logout'),
                onTap: () async {
                  Navigator.of(context).pop();
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
}

// Helper class for nav items
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
