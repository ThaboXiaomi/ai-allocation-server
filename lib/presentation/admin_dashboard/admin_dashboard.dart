import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
  String _adminName = 'Admin'; // Default name
  String _adminEmail = 'admin@university.edu'; // Default email
  final ValueNotifier<bool> _isDarkMode = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);

    try {
      // ─── Notifications ─────────────────────
      final notificationsSnapshot = await FirebaseFirestore.instance
          .collection('notifications')
          .orderBy('time', descending: true)
          .get();
      _notifications = notificationsSnapshot.docs.map((doc) {
        return {'id': doc.id, ...doc.data()};
      }).toList();

      // ─── Recent Timetables ─────────────────
      final timetablesSnapshot = await FirebaseFirestore.instance
          .collection('timetables')
          .orderBy('date', descending: true)
          .limit(5)
          .get();
      _recentTimetables = timetablesSnapshot.docs.map((doc) {
        return {'id': doc.id, ...doc.data()};
      }).toList();

      // ─── Faculties ──────────────────────────
      final facultiesSnapshot =
          await FirebaseFirestore.instance.collection('faculties').get();
      _faculties = facultiesSnapshot.docs.map((doc) {
        return {'id': doc.id, ...doc.data()};
      }).toList();

      // ─── Room Statuses ──────────────────────
      final roomStatusSnapshot =
          await FirebaseFirestore.instance.collection('rooms').get();
      _roomStatus = roomStatusSnapshot.docs
          .map((doc) => doc.data())
          .toList();
      // ─── Analytics Data ─────────────────────
      final analyticsSnapshot = await FirebaseFirestore.instance
          .collection('analytics')
          .doc('data')
          .get();

      // Grab the raw map (or empty map if doc missing)
      _analyticsData = analyticsSnapshot.data() ?? {};

      // Ensure there's always a `weeklyData` list
      final rawWeekly = _analyticsData['weeklyData'];
      if (rawWeekly is List) {
        // Coerce each element into Map<String, dynamic>
        _analyticsData['weeklyData'] = rawWeekly
            .whereType<Map>()
            .map((m) => Map<String, dynamic>.from(m))
            .toList();
      } else {
        // Missing or wrong type: default to empty list
        _analyticsData['weeklyData'] = <Map<String, dynamic>>[];
      }

      // --- Fetch Admin Details ---
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        try {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .get();
          if (userDoc.exists) {
            final userData = userDoc.data();
            _adminName = userData?['displayName'] ?? currentUser.displayName ?? 'Admin';
            _adminEmail = userData?['email'] ?? currentUser.email ?? 'admin@university.edu';
          } else {
            // Fallback to FirebaseAuth info if user document doesn't exist
            _adminName = currentUser.displayName ?? 'Admin';
            _adminEmail = currentUser.email ?? 'admin@university.edu';
          }
        } catch (e) { // Catch error specific to fetching user details
          debugPrint("Error fetching admin user details: $e");
          // Keep default/FirebaseAuth info if Firestore fetch fails
          _adminName = currentUser.displayName ?? 'Admin';
          _adminEmail = currentUser.email ?? 'admin@university.edu';
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch data: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
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
              actions: [
                IconButton(
                  icon: const CustomIconWidget(
                    iconName: 'notifications',
                    color: Colors.white,
                  ),
                  onPressed: () => _showNotificationsPanel(context),
                ),
                IconButton(
                  icon: const CustomIconWidget(
                    iconName: 'settings',
                    color: Colors.white,
                  ),
                  onPressed: () {
                    // Navigate to the same admin profile settings page
                    Navigator.pushNamed(context, '/admin-profile-settings');
                  },
                ),
              ],
            ),
            drawer: _buildSidebarMenu(context, isDark), // <-- MOVED TO LEFT SIDE
            body: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SafeArea(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildWelcomeSection(),
                          const SizedBox(height: 24),
                          _buildNotificationSummary(),
                          const SizedBox(height: 24),
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
            // Facebook-style header
            Container(
              color: AppTheme.primary50,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppTheme.primary300,
                    child: const Icon(Icons.admin_panel_settings, size: 32, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                          Text(_adminName, // Use fetched admin name
                            style: AppTheme.lightTheme.textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold, color: textColor)),
                        const SizedBox(height: 4),
                          Text(_adminEmail, // Use fetched admin email
                            style: AppTheme.lightTheme.textTheme.bodySmall
                                ?.copyWith(color: subTextColor)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Menu items
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
                    icon: Icons.calendar_today,
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
                    icon: Icons.school,
                    label: 'Faculty Management',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/faculty-management');
                    },
                    textColor: textColor,
                  ),
                  _buildMenuItem(
                    icon: Icons.meeting_room,
                    label: 'Room Allocation',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/venue-management');
                    },
                    textColor: textColor,
                  ),
                  _buildMenuItem(
                    icon: Icons.insights,
                    label: 'System Analytics',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/ai-allocation-dashboard');
                    },
                    textColor: textColor,
                  ),
                  _buildMenuItem(
                    icon: Icons.settings_applications, // Or Icons.manage_accounts
                    label: 'Profile Settings',
                    onTap: () {
                      Navigator.pop(context); // Close drawer
                      // TODO: Implement navigation to a dedicated admin profile settings page
                      Navigator.pushNamed(context, '/admin-profile-settings');
                    },
                    textColor: textColor,
                  ),
                  const Divider(),
                  // Dark mode toggle
                  SwitchListTile(
                    secondary: Icon(_isDarkMode.value ? Icons.dark_mode : Icons.light_mode, color: textColor),
                    title: Text('Dark Mode', style: TextStyle(color: textColor)),
                    value: _isDarkMode.value,
                    onChanged: (val) => _isDarkMode.value = val,
                  ),
                  const Divider(),
                  // Logout
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: const Text('Logout', style: TextStyle(color: Colors.red)),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushReplacementNamed(context, '/admin-login');
                    },
                  ),
                ],
              ),
            ),
            // Facebook-style footer
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
      title: Text(label, style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(color: textColor)),
      onTap: onTap,
    );
  }

  Widget _buildWelcomeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Welcome, Admin',
            style: AppTheme.lightTheme.textTheme.displaySmall),
        const SizedBox(height: 8),
        Text(
          'Manage your AI-powered lecture room allocation system',
          style: AppTheme.lightTheme.textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildNotificationSummary() {
    final unreadCount =
        _notifications.where((n) => n['isRead'] == false).length;

    return InkWell(
      onTap: () => _showNotificationsPanel(context),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: unreadCount > 0 ? AppTheme.primary50 : AppTheme.neutral50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: unreadCount > 0 ? AppTheme.primary300 : AppTheme.neutral300,
          ),
        ),
        child: Row(
          children: [
            CustomIconWidget(
              iconName: 'notifications',
              color:
                  unreadCount > 0 ? AppTheme.primary600 : AppTheme.neutral600,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    unreadCount > 0
                        ? 'You have $unreadCount unread notifications'
                        : 'No new notifications',
                    style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: unreadCount > 0
                          ? AppTheme.primary700
                          : AppTheme.neutral700,
                    ),
                  ),
                  if (unreadCount > 0)
                    Text(
                      'Tap to view all notifications',
                      style: AppTheme.lightTheme.textTheme.bodySmall,
                    ),
                ],
              ),
            ),
            CustomIconWidget(
              iconName: 'arrow_forward_ios',
              color:
                  unreadCount > 0 ? AppTheme.primary600 : AppTheme.neutral600,
              size: 16,
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
                  child:
                      TimetableManagementPage(), // You need to create this page
                ),
              )
            );
          },
          child: _recentTimetables.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Text("No recent timetables."),
                )
              : Column(
                  children: _recentTimetables.map((timetable) {
                    return ListTile(
                      leading: const CustomIconWidget(
                          iconName: 'calendar_today',
                          color: AppTheme.neutral600),
                      title: Text(timetable['name'] ?? 'Unknown Timetable'),
                      subtitle:
                          Text('Date: ${timetable['date'] ?? 'Unknown Date'}'),
                    );
                  }).toList(),
                ),
        ),
        const SizedBox(height: 16),
        // Display Faculties if available
        if (_faculties.isNotEmpty) ...[
          DashboardCardWidget(
            title: 'Faculty Management',
            icon:
                'account_circle', // Placeholder for 'school'. Add 'school' to CustomIconWidget for a better icon.
            collectionName: 'faculties',
            onTap: () => Navigator.pushNamed(
                context, '/faculty-management'), // Example route
            child: Column(
              children: _faculties
                  .map((f) => faculty.FacultyItemWidget(faculty: f))
                  .toList(),
            ),
          ),
          const SizedBox(height: 16),
        ],
        DashboardCardWidget(
          title: 'Room Allocation Status',
          icon:
              'home', // Placeholder for 'meeting_room'. Add 'meeting_room' or 'room' to CustomIconWidget.
          collectionName: 'rooms', // Used for the count
          onTap: () => Navigator.pushNamed(
              context, '/venue-management'), // Example route
          child: _roomStatus.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Text("No room statuses available."),
                )
              : Column(
                  children: _roomStatus
                      .map((room) => RoomStatusWidget(roomData: room))
                      .toList(),
                ),
        ),
        const SizedBox(height: 16),
        DashboardCardWidget(
          title: 'System Analytics',
          icon: 'insights',
          collectionName: 'analytics',
          onTap: () => Navigator.pushNamed(context, '/ai-allocation-dashboard'),
          child: (_analyticsData['weeklyData'] as List<Map<String, dynamic>>)
                  .isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Text("No weekly analytics data available."),
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
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
                  padding: const EdgeInsets.all(16.0),
                  child: Text('Notifications',
                      style: AppTheme.lightTheme.textTheme.headlineSmall),
                ),
                Expanded(
                  child: _notifications.isEmpty
                      ? Center(
                          child: Text('No notifications yet.',
                              style: AppTheme.lightTheme.textTheme.bodyMedium),
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
                                // Mark as read in Firestore (NotificationItemWidget handles this internally now)
                                // For UI update, we might need to refetch or update local state if not handled by stream
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
