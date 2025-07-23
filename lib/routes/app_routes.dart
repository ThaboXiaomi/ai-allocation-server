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
import 'package:lecture_room_allocator/presentation/lecturer_interface/widgets/class_timer_widget.dart'
    as ctw;
import 'package:lecture_room_allocator/presentation/lecturer_interface/widgets/notification_card_widget.dart';
import 'package:lecture_room_allocator/presentation/lecturer_interface/widgets/venue_map_widget.dart';

class AppRoutes {
  // Route constants
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
  static const String venueManagement = '/venue-management';
  static const String facultyList = '/faculty-list';
  static const String studentSettings = '/student-settings';
  static const String lecturerAttendance = '/lecturer-attendance';
  static const String lecturerClassTimer = '/lecturer-class-timer';
  static const String lecturerNotifications = '/lecturer-notifications';
  static const String lecturerVenueMap = '/lecturer-venue-map';

  // Static routes map with Scaffold for proper screen rendering
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
    lecturerAttendance: (_) => AttendanceStatsWidget(courseId: 'sampleCourseId'),
    lecturerClassTimer: (_) => Scaffold(
          appBar: AppBar(title: const Text('Class Timer')),
          body: const ctw.ClassTimerWidget(classId: 'sampleClassId'),
        ),
    lecturerNotifications: (_) => Scaffold(
          appBar: AppBar(title: const Text('Notifications')),
          body: NotificationCardWidget(
            notification: const {
              'id': 'notif1',
              'isRead': false,
              'type': 'system',
            },
            onTap: () {},
          ),
        ),
    lecturerVenueMap: (_) => Scaffold(
          appBar: AppBar(title: const Text('Venue Map')),
          body: const VenueMapWidget(fromVenue: 'A101', toVenue: 'B202'),
        ),
  };

  /// Dynamically determine the initial screen based on auth state
  static Widget getInitialScreen() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const PortalSelectionScreen();
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snap.hasError || !snap.hasData || !snap.data!.exists) {
          // Log error and sign out
          // In a production app, consider using a dedicated logging package.
          debugPrint('Error fetching user role or user document does not exist: ${snap.error}');
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

  /// Handle dynamic route generation with arguments
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final args = settings.arguments as Map<String, dynamic>? ?? {};
    switch (settings.name) {
      case lecturerAttendance:
        final courseId = args['courseId'] as String? ?? 'sampleCourseId';
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Attendance Statistics')),
            body: AttendanceStatsWidget(courseId: courseId),
          ),
        );
      case lecturerClassTimer:
        final classId = args['classId'] as String? ?? 'sampleClassId';
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Class Timer')),
            body: ctw.ClassTimerWidget(classId: classId),
          ),
        );
      case lecturerNotifications:
        final notification = args['notification'] as Map<String, dynamic>? ??
            const {
              'id': 'notif1',
              'isRead': false,
              'type': 'system',
            };
        final onTap = args['onTap'] as VoidCallback? ?? () {};
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Notifications')),
            body: NotificationCardWidget(notification: notification, onTap: onTap),
          ),
        );
      case lecturerVenueMap:
        final fromVenue = args['fromVenue'] as String? ?? 'A101';
        final toVenue = args['toVenue'] as String? ?? 'B202';
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Venue Map')),
            body: VenueMapWidget(fromVenue: fromVenue, toVenue: toVenue),
          ),
        );
      default:
        // Fallback to static routes
        final builder = routes[settings.name];
        if (builder != null) {
          return MaterialPageRoute(builder: builder);
        }
        // Return null to trigger onUnknownRoute in MaterialApp
        return null;
    }
  }
}