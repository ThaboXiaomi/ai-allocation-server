import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:lecture_room_allocator/presentation/portal_selection_screen/portal_selection_screen.dart';
import 'package:lecture_room_allocator/presentation/common/code_viewer_screen.dart';
import 'package:lecture_room_allocator/presentation/student_auth_screen/student_auth_screen.dart';
import 'package:lecture_room_allocator/presentation/admin_login/admin_auth_screen.dart';
import 'package:lecture_room_allocator/presentation/lecturer_auth_screen/lecturer_auth_screen.dart';
import 'package:lecture_room_allocator/presentation/student_dashboard/student_dashboard.dart';
import 'package:lecture_room_allocator/presentation/admin_dashboard/admin_dashboard.dart';
import 'package:lecture_room_allocator/presentation/lecturer_interface/lecturer_interface.dart';
import 'package:lecture_room_allocator/presentation/course_management/course_management.dart';
import 'package:lecture_room_allocator/presentation/ai_allocation_dashboard/ai_allocation_dashboard.dart';
import 'package:lecture_room_allocator/presentation/admin_dashboard/widgets/venue_management_screen.dart';
import 'package:lecture_room_allocator/presentation/admin_dashboard/widgets/faculty_list_screen.dart'
    as fls;
import 'package:lecture_room_allocator/presentation/admin_dashboard/widgets/faculty_item_widget.dart'
    as fiw;
import 'package:lecture_room_allocator/presentation/student_dashboard/widgets/student_settings.dart';
import 'package:lecture_room_allocator/presentation/lecturer_interface/widgets/attendance_stats_widget.dart';
import 'package:lecture_room_allocator/presentation/lecturer_interface/widgets/class_timer_widget.dart';
import 'package:lecture_room_allocator/presentation/lecturer_interface/widgets/notification_card_widget.dart';
import 'package:lecture_room_allocator/presentation/lecturer_interface/widgets/venue_map_widget.dart';

class AppRoutes {
  static const String codeViewer = '/code-viewer';
  static const String portalSelection = '/portal-selection';

  static const String studentAuth = '/student-auth';
  static const String adminAuth = '/admin-auth';
  static const String lecturerAuth = '/lecturer-auth';

  static const String studentDashboard = '/student-dashboard';
  static const String adminDashboard = '/admin-dashboard';
  static const String lecturerDashboard = '/lecturer-dashboard';

  static const String courseManagement = '/course-management';
  static const String aiAllocationDashboard = '/ai-allocation-dashboard';
  static const String facultyManagement = '/faculty-management';
  static const String venueManagement =
      '/venue-management'; // <-- Added constant
  static const String facultyList = '/faculty-list';
  static const String studentSettings = '/student-settings';

  // Add these route constants:
  static const String lecturerAttendance = '/lecturer-attendance';
  static const String lecturerClassTimer = '/lecturer-class-timer';
  static const String lecturerNotifications = '/lecturer-notifications';
  static const String lecturerVenueMap = '/lecturer-venue-map';

  static final Map<String, WidgetBuilder> routes = {
    codeViewer: (_) => const CodeViewerScreen(filePath: '', fileName: ''),
    portalSelection: (_) => const PortalSelectionScreen(),
    studentAuth: (_) => const StudentAuthScreen(),
    adminAuth: (_) => const AdminAuthScreen(),
    lecturerAuth: (_) => const LecturerAuthScreen(),
    studentDashboard: (_) => const StudentDashboardScreen(),
    adminDashboard: (_) => const AdminDashboard(),
    lecturerDashboard: (_) => const LecturerInterface(),
    courseManagement: (_) => const CourseManagement(),
    aiAllocationDashboard: (_) => const AIAllocationDashboard(),
    facultyManagement: (_) => fiw.FacultyListScreen(),
    venueManagement: (_) => const VenueManagementScreen(),
    facultyList: (_) => fls.FacultyListScreen(),
    studentSettings: (_) => const StudentSettings(),
    // Add these to the routes map:
    lecturerAttendance: (_) =>
        AttendanceStatsWidget(courseId: 'sampleCourseId'),
    lecturerClassTimer: (_) => ClassTimerWidget(classId: 'sampleClassId'),
    lecturerNotifications: (_) => NotificationCardWidget(
          notification: const {
            "id": "notif1",
            "isRead": false,
            "type": "system",
          },
          onTap: () {},
        ),
    lecturerVenueMap: (_) => VenueMapWidget(fromVenue: 'A101', toVenue: 'B202'),
  };

  /// Dynamically determine the initial screen based on auth state
  static Widget getInitialScreen() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const PortalSelectionScreen();
    }

    return FutureBuilder<DocumentSnapshot>(
      future:
          FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snap.hasError || !snap.hasData || !snap.data!.exists) {
          // Log error and sign out
          print("Error fetching user role: ${snap.error}");
          FirebaseAuth.instance.signOut();
          return const PortalSelectionScreen();
        }

        final data = snap.data!.data() as Map<String, dynamic>;
        final role = data['role'] as String? ?? 'student';

        switch (role) {
          case 'admin':
            return const AdminDashboard();
          case 'lecturer':
            return const LecturerInterface();
          case 'student':
          default:
            return const StudentDashboardScreen();
        }
      },
    );
  }

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case lecturerAttendance:
        final args = settings.arguments as Map<String, dynamic>? ?? {};
        return MaterialPageRoute(
          builder: (_) => AttendanceStatsWidget(
            courseId: args['courseId'] ?? 'sampleCourseId',
          ),
        );
      case lecturerClassTimer:
        final args = settings.arguments as Map<String, dynamic>? ?? {};
        return MaterialPageRoute(
          builder: (_) => ClassTimerWidget(
            classId: args['classId'] ?? 'sampleClassId',
          ),
        );
      case lecturerNotifications:
        final args = settings.arguments as Map<String, dynamic>? ?? {};
        return MaterialPageRoute(
          builder: (_) => NotificationCardWidget(
            notification: args['notification'] ??
                const {
                  "id": "notif1",
                  "isRead": false,
                  "type": "system",
                },
            onTap: args['onTap'] ?? () {},
          ),
        );
      case lecturerVenueMap:
        final args = settings.arguments as Map<String, dynamic>? ?? {};
        return MaterialPageRoute(
          builder: (_) => VenueMapWidget(
            fromVenue: args['fromVenue'] ?? 'A101',
            toVenue: args['toVenue'] ?? 'B202',
          ),
        );
      default:
        // Fallback to static routes or unknown route
        final builder = routes[settings.name];
        if (builder != null) {
          return MaterialPageRoute(builder: builder);
        }
        return null;
    }
  }
}
