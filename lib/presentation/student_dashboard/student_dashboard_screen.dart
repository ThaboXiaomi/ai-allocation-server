import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'widgets/quick_action_button_widget.dart';
import 'widgets/lecture_card_widget.dart';
import 'widgets/attendance_stats_widget.dart';
import 'widgets/notification_card_widget.dart';

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({Key? key}) : super(key: key);

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
        length: 5, vsync: this); // Increased to 5 for Settings tab
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    if (_tabController.index != 0) {
      setState(() {
        _tabController.index = 0;
      });
      return false;
    }
    // Prevent pop if there's nothing to pop (avoid navigator.dart _history.isNotEmpty error)
    if (!Navigator.of(context).canPop()) {
      return false;
    }
    return true;
  }

  Future<String?> _fetchStudentName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    final doc = await FirebaseFirestore.instance
        .collection('students')
        .doc(user.uid)
        .get();
    final data = doc.data();
    if (data == null) return 'Student';
    final name = data['name'];
    if (name is String && name.isNotEmpty) {
      return name;
    }
    return 'Student';
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _tabController.index,
              onDestinationSelected: (int index) {
                setState(() {
                  _tabController.index = index;
                });
              },
              labelType: NavigationRailLabelType.all,
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.dashboard),
                  label: Text('Dashboard'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.book),
                  label: Text('Lectures'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.check_circle),
                  label: Text('Attendance'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.notifications),
                  label: Text('Notifications'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.settings),
                  label: Text('Settings'),
                ),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  // Dashboard Tab
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FutureBuilder<String?>(
                          future: _fetchStudentName(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Text(
                                'Welcome...',
                                style: TextStyle(
                                    fontSize: 28, fontWeight: FontWeight.bold),
                              );
                            }
                            final name = snapshot.data ?? 'Student';
                            return Text(
                              'Welcome, $name!',
                              style: const TextStyle(
                                  fontSize: 28, fontWeight: FontWeight.bold),
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                        // Quick Actions Section
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: const [
                                    Icon(Icons.flash_on,
                                        color: Colors.deepPurple, size: 28),
                                    SizedBox(width: 8),
                                    Text(
                                      "Quick Actions",
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 18),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    QuickActionButtonWidget(
                                      icon: 'calendar_month',
                                      label: 'Full Schedule',
                                      onTap: () {},
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
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        AttendanceStatsWidget(
                          attendanceData: {
                            "totalLectures": 20,
                            "attendedLectures": 18,
                            "attendancePercentage": 90,
                          },
                        ),
                        const SizedBox(height: 32),
                        LectureCardWidget(
                          lecture: {
                            "id": "lecture1",
                            "isReallocated": false,
                            "checkInAvailable": true,
                          },
                          onViewMap: () {},
                        ),
                        const SizedBox(height: 32),
                        NotificationCardWidget(
                          notification: {
                            "id": "notif1",
                            "isRead": false,
                            "type": "system",
                          },
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),
                  // Lectures Tab
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        LectureCardWidget(
                          lecture: {
                            "id": "lecture1",
                            "isReallocated": false,
                            "checkInAvailable": true,
                          },
                          onViewMap: () {},
                        ),
                      ],
                    ),
                  ),
                  // Attendance Tab
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: const [
                        AttendanceStatsWidget(
                          attendanceData: {
                            "totalLectures": 20,
                            "attendedLectures": 18,
                            "attendancePercentage": 90,
                          },
                        ),
                      ],
                    ),
                  ),
                  // Notifications Tab
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        NotificationCardWidget(
                          notification: {
                            "id": "notif1",
                            "isRead": false,
                            "type": "system",
                          },
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),
                  // Settings Tab
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Settings',
                          style: TextStyle(
                              fontSize: 28, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 24),
                        // Add your settings widgets here
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
