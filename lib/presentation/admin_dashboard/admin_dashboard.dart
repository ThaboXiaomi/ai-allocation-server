import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lecture_room_allocator/presentation/admin_login/admin_auth_screen.dart';

import '../../theme/app_theme.dart';
import '../../widgets/custom_icon_widget.dart';
import './widgets/analytics_chart_widget.dart';
import './widgets/dashboard_card_widget.dart';
import './widgets/faculty_item_widget.dart' as faculty;
import './widgets/notification_item_widget.dart';
import './widgets/room_status_widget.dart';
import './widgets/timetable_management_bloc.dart';
import './widgets/timetable_management_page.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  List<Map<String, dynamic>> _notifications = [];
  List<Map<String, dynamic>> _recentTimetables = [];
  List<Map<String, dynamic>> _faculties = [];
  List<Map<String, dynamic>> _roomStatus = [];
  Map<String, dynamic> _analyticsData = {};
  bool _isLoading = true;
  String _adminName = 'Admin';
  String _adminEmail = 'admin@university.edu';
  final ValueNotifier<bool> _isDarkMode = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    if (mounted) setState(() => _isLoading = true);

    try {
      final notificationsSnapshot = await FirebaseFirestore.instance
          .collection('notifications')
          .orderBy('time', descending: true)
          .get();
      _notifications = notificationsSnapshot.docs.map((doc) {
        return {'id': doc.id, ...doc.data()};
      }).toList();

      final timetablesSnapshot = await FirebaseFirestore.instance
          .collection('timetables')
          .orderBy('date', descending: true)
          .limit(5)
          .get();
      _recentTimetables = timetablesSnapshot.docs.map((doc) {
        return {'id': doc.id, ...doc.data()};
      }).toList();

      final facultiesSnapshot =
          await FirebaseFirestore.instance.collection('faculties').get();
      _faculties = facultiesSnapshot.docs.map((doc) {
        return {'id': doc.id, ...doc.data()};
      }).toList();

      final roomStatusSnapshot =
          await FirebaseFirestore.instance.collection('rooms').get();
      _roomStatus = roomStatusSnapshot.docs.map((doc) => doc.data()).toList();

      final analyticsSnapshot = await FirebaseFirestore.instance
          .collection('analytics')
          .doc('data')
          .get();
      _analyticsData = analyticsSnapshot.data() ?? {};
      final rawWeekly = _analyticsData['weeklyData'];
      if (rawWeekly is List) {
        _analyticsData['weeklyData'] = rawWeekly
            .whereType<Map>()
            .map((m) => Map<String, dynamic>.from(m))
            .toList();
      } else {
        _analyticsData['weeklyData'] = <Map<String, dynamic>>[];
      }

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        try {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .get();
          if (userDoc.exists) {
            final userData = userDoc.data();
            _adminName =
                userData?['displayName'] ?? currentUser.displayName ?? 'Admin';
            _adminEmail = userData?['email'] ??
                currentUser.email ??
                'admin@university.edu';
          } else {
            _adminName = currentUser.displayName ?? 'Admin';
            _adminEmail = currentUser.email ?? 'admin@university.edu';
          }
        } catch (e) {
          debugPrint("Error fetching admin user details: $e");
          _adminName = currentUser.displayName ?? 'Admin';
          _adminEmail = currentUser.email ?? 'admin@university.edu';
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch data: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
            appBar: AppBar(
              title: const Text('Admin Dashboard'),
              elevation: 2,
              actions: [
                IconButton(
                  icon: const Icon(
                    Icons.notifications_outlined,
                    color: Colors.white,
                    size: 28,
                  ),
                  onPressed: () => _showNotificationsPanel(context),
                  tooltip: 'Notifications',
                ),
                IconButton(
                  icon: const Icon(
                    Icons.settings_outlined,
                    color: Colors.white,
                    size: 28,
                  ),
                  onPressed: () {
                    Navigator.pushNamed(context, '/admin-profile-settings');
                  },
                  tooltip: 'Settings',
                ),
              ],
            ),
            drawer: _buildSidebarMenu(context, isDark),
            body: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SafeArea(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildWelcomeSection(),
                          const SizedBox(height: 32),
                          _buildNotificationSummary(),
                          const SizedBox(height: 32),
                          _buildDashboardGrid(),
                        ],
                      ),
                    ),
                  ),
          ),
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
            Container(
              color: AppTheme.primary50,
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppTheme.primary300,
                    child: const Icon(
                      Icons.admin_panel_settings_outlined,
                      size: 36,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _adminName,
                          style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _adminEmail,
                          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
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
                    icon: Icons.dashboard_outlined,
                    label: 'Dashboard',
                    onTap: () {
                      if (Navigator.of(context).canPop()) {
                        Navigator.pop(context);
                      }
                    },
                    textColor: textColor,
                  ),
                  _buildMenuItem(
                    icon: Icons.calendar_today_outlined,
                    label: 'Timetable Management',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BlocProvider(
                            create: (_) => TimetableManagementBloc(
                              firestore: FirebaseFirestore.instance,
                            ),
                            child: TimetableManagementPage(),
                          ),
                        ),
                      );
                    },
                    textColor: textColor,
                  ),
                  _buildMenuItem(
                    icon: Icons.school_outlined,
                    label: 'Faculty Management',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/faculty-management');
                    },
                    textColor: textColor,
                  ),
                  _buildMenuItem(
                    icon: Icons.meeting_room_outlined,
                    label: 'Room Allocation',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/venue-management');
                    },
                    textColor: textColor,
                  ),
                  _buildMenuItem(
                    icon: Icons.insights_outlined,
                    label: 'System Analytics',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/ai-allocation-dashboard');
                    },
                    textColor: textColor,
                  ),
                  _buildMenuItem(
                    icon: Icons.manage_accounts_outlined,
                    label: 'Profile Settings',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/admin-profile-settings');
                    },
                    textColor: textColor,
                  ),
                  const Divider(),
                  SwitchListTile(
                    secondary: Icon(
                      _isDarkMode.value
                          ? Icons.dark_mode_outlined
                          : Icons.light_mode_outlined,
                      color: textColor,
                      size: 26,
                    ),
                    title: Text(
                      'Dark Mode',
                      style: TextStyle(color: textColor),
                    ),
                    value: _isDarkMode.value,
                    onChanged: (val) => _isDarkMode.value = val,
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(
                      Icons.logout_outlined,
                      color: Colors.red,
                      size: 26,
                    ),
                    title: const Text(
                      'Logout',
                      style: TextStyle(color: Colors.red),
                    ),
                    onTap: () {
                      Navigator.of(context).pop();
                      FirebaseAuth.instance.signOut().then((_) {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => const AdminAuthScreen(),
                          ),
                        );
                      });
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                '© 2025 Lecturer Room Allocator',
                style: TextStyle(
                  color: subTextColor,
                  fontSize: 12,
                ),
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
      leading: Icon(
        icon,
        color: AppTheme.primary600,
        size: 26,
      ),
      title: Text(
        label,
        style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      hoverColor: AppTheme.primary50.withOpacity(0.1),
    );
  }

  Widget _buildWelcomeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome, $_adminName',
          style: AppTheme.lightTheme.textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.primary900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Manage your AI-powered lecture room allocation system',
          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
            color: AppTheme.neutral600,
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationSummary() {
    final unreadCount =
        _notifications.where((n) => n['isRead'] == false).length;

    return InkWell(
      onTap: () => _showNotificationsPanel(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: unreadCount > 0 ? AppTheme.primary50 : AppTheme.neutral50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: unreadCount > 0 ? AppTheme.primary300 : AppTheme.neutral300,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              unreadCount > 0
                  ? Icons.notifications_active_outlined
                  : Icons.notifications_none_outlined,
              color: unreadCount > 0 ? AppTheme.primary600 : AppTheme.neutral600,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    unreadCount > 0
                        ? '$unreadCount Unread Notification${unreadCount > 1 ? 's' : ''}'
                        : 'No New Notifications',
                    style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: unreadCount > 0
                          ? AppTheme.primary700
                          : AppTheme.neutral700,
                    ),
                  ),
                  if (unreadCount > 0)
                    Text(
                      'Tap to view all notifications',
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.neutral600,
                      ),
                    ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: unreadCount > 0 ? AppTheme.primary600 : AppTheme.neutral600,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardGrid() {
    return Column(
      children: [
        DashboardCardWidget(
          title: 'Timetable Management',
          icon: 'calendar_today',
          collectionName: 'timetables',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BlocProvider(
                  create: (_) => TimetableManagementBloc(
                    firestore: FirebaseFirestore.instance,
                  ),
                  child: TimetableManagementPage(),
                ),
              ),
            );
          },
          child: _recentTimetables.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.0),
                  child: Text(
                    "No recent timetables.",
                    style: TextStyle(color: AppTheme.neutral600),
                  ),
                )
              : Column(
                  children: _recentTimetables.map((timetable) {
                    return ListTile(
                      leading: const Icon(
                        Icons.calendar_view_day_outlined,
                        color: AppTheme.neutral600,
                        size: 24,
                      ),
                      title: Text(
                        timetable['name'] ?? 'Unknown Timetable',
                        style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        'Date: ${timetable['date'] ?? 'Unknown Date'}',
                        style: AppTheme.lightTheme.textTheme.bodySmall,
                      ),
                    );
                  }).toList(),
                ),
        ),
        const SizedBox(height: 20),
        if (_faculties.isNotEmpty) ...[
          DashboardCardWidget(
            title: 'Faculty Management',
            icon: 'school',
            collectionName: 'faculties',
            onTap: () => Navigator.pushNamed(context, '/faculty-management'),
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('faculties')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }
                final faculties = snapshot.data!.docs;
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: faculties.length,
                  itemBuilder: (context, index) {
                    final doc = faculties[index];
                    final facultyData = {
                      'id': doc.id,
                      ...doc.data() as Map<String, dynamic>
                    };
                    return faculty.FacultyItemWidget(faculty: facultyData);
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 20),
        ],
        DashboardCardWidget(
          title: 'Room Allocation Status',
          icon: 'meeting_room',
          collectionName: 'rooms',
          onTap: () => Navigator.pushNamed(context, '/venue-management'),
          child: _roomStatus.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.0),
                  child: Text(
                    "No room statuses available.",
                    style: TextStyle(color: AppTheme.neutral600),
                  ),
                )
              : Column(
                  children: _roomStatus
                      .map((room) => RoomStatusWidget(roomData: room))
                      .toList(),
                ),
        ),
        const SizedBox(height: 20),
        DashboardCardWidget(
          title: 'System Analytics',
          icon: 'insights',
          collectionName: 'analytics',
          onTap: () => Navigator.pushNamed(context, '/ai-allocation-dashboard'),
          child: (_analyticsData['weeklyData'] as List<Map<String, dynamic>>)
                  .isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.0),
                  child: Text(
                    "No weekly analytics data available.",
                    style: TextStyle(color: AppTheme.neutral600),
                  ),
                )
              : AnalyticsChartWidget(
                  weeklyData: _analyticsData['weeklyData']
                      as List<Map<String, dynamic>>,
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (BuildContext context, ScrollController scrollController) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Notifications',
                        style:
                            AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 24),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _notifications.isEmpty
                      ? Center(
                          child: Text(
                            'No notifications yet.',
                            style:
                                AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                              color: AppTheme.neutral600,
                            ),
                          ),
                        )
                      : ListView.separated(
                          controller: scrollController,
                          itemCount: _notifications.length,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          separatorBuilder: (context, index) =>
                              const Divider(height: 1),
                          itemBuilder: (BuildContext context, int index) {
                            return NotificationItemWidget(
                              notification: _notifications[index],
                              onTap: () async {
                                // NotificationItemWidget handles marking as read
                              },
                            );
                          },
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}