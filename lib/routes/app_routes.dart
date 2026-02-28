import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:lecture_room_allocator/presentation/admin_dashboard/admin_dashboard.dart';
import 'package:lecture_room_allocator/presentation/admin_login/admin_auth_screen.dart';
import 'package:lecture_room_allocator/presentation/admin_password_reset/admin_password_reset.dart';
import 'package:lecture_room_allocator/presentation/admin_registration_screen/admin_registration_screen.dart';
import 'package:lecture_room_allocator/presentation/ai_allocation_dashboard/ai_allocation_dashboard.dart';
import 'package:lecture_room_allocator/presentation/common/code_viewer_screen.dart';
import 'package:lecture_room_allocator/presentation/course_management/course_management.dart';
import 'package:lecture_room_allocator/presentation/lecturer_auth_screen/lecturer_auth_screen.dart';
import 'package:lecture_room_allocator/presentation/lecturer_interface/lecturer_interface.dart';
import 'package:lecture_room_allocator/presentation/lecturer_interface/widgets/attendance_stats_widget.dart';
import 'package:lecture_room_allocator/presentation/lecturer_interface/widgets/class_timer_widget.dart' as ctw;
import 'package:lecture_room_allocator/presentation/lecturer_interface/widgets/notification_card_widget.dart';
import 'package:lecture_room_allocator/presentation/lecturer_interface/widgets/venue_map_widget.dart';
import 'package:lecture_room_allocator/presentation/portal_selection_screen/portal_selection_screen.dart';
import 'package:lecture_room_allocator/presentation/splash_screen/splash_screen.dart';
import 'package:lecture_room_allocator/presentation/student_auth_screen/student_auth_screen.dart';
import 'package:lecture_room_allocator/presentation/student_dashboard/student_dashboard.dart';
import 'package:lecture_room_allocator/presentation/student_registration_screen/student_registration_screen.dart';
import 'package:lecture_room_allocator/presentation/student_dashboard/widgets/student_settings.dart';
import 'package:lecture_room_allocator/presentation/core/widgets/role_guard.dart';

class AppRoutes {
  static const String codeViewer = '/code-viewer';
  static const String splash = '/';
  static const String portalSelection = '/portal-selection';
  static const String studentAuth = '/student-auth';
  static const String studentRegister = '/student-register';
  static const String adminAuth = '/admin-auth';
  static const String adminRegister = '/admin-register';
  static const String adminResetPassword = '/admin-reset-password';
  static const String lecturerAuth = '/lecturer-auth';
  static const String studentDashboard = '/student-dashboard';
  static const String adminDashboard = '/admin-dashboard';
  static const String lecturerDashboard = '/lecturer-dashboard';
  static const String courseManagement = '/course-management';
  static const String aiAllocationDashboard = '/ai-allocation-dashboard';
  static const String studentSettings = '/student-settings';
  static const String lecturerAttendance = '/lecturer-attendance';
  static const String lecturerClassTimer = '/lecturer-class-timer';
  static const String lecturerNotifications = '/lecturer-notifications';
  static const String lecturerVenueMap = '/lecturer-venue-map';

  static final Map<String, WidgetBuilder> routes = {
    codeViewer: (_) => const CodeViewerScreen(filePath: '', fileName: ''),
    splash: (_) => const SplashScreen(),
    portalSelection: (_) => const PortalSelectionScreen(),
    studentAuth: (_) => const StudentAuthScreen(),
    studentRegister: (_) => const StudentRegistrationScreen(),
    adminAuth: (_) => const AdminAuthScreen(),
    adminRegister: (_) => const AdminRegistrationScreen(),
    adminResetPassword: (_) => const AdminPasswordResetPage(),
    lecturerAuth: (_) => const LecturerAuthScreen(),
    studentDashboard: (_) => const RoleGuard(allowedRoles: const ['student'], child: StudentDashboardScreen()),
    adminDashboard: (_) => const RoleGuard(allowedRoles: const ['admin'], child: AdminDashboard()),
    lecturerDashboard: (_) => const RoleGuard(allowedRoles: const ['lecturer'], child: LecturerInterface()),
    courseManagement: (_) => const RoleGuard(allowedRoles: const ['admin'], child: CourseManagement()),
    aiAllocationDashboard: (_) => const RoleGuard(allowedRoles: const ['admin'], child: AIAllocationDashboard()),
    studentSettings: (_) => const RoleGuard(allowedRoles: const ['student'], child: StudentSettings()),
  };

  static Widget getInitialScreen() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const PortalSelectionScreen();
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (snap.hasError || !snap.hasData || !snap.data!.exists) {
          FirebaseAuth.instance.signOut();
          return const PortalSelectionScreen();
        }

        final data = snap.data!.data() as Map<String, dynamic>;
        final role = (data['role'] as String? ?? 'student').toLowerCase();

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
    final args = settings.arguments as Map<String, dynamic>? ?? {};

    switch (settings.name) {
      case lecturerAttendance:
        final courseId = args['courseId'] as String?;
        if (courseId == null || courseId.isEmpty) {
          return _buildMissingArgsRoute('courseId');
        }
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Attendance Statistics')),
            body: RoleGuard(allowedRoles: const ['lecturer'], child: AttendanceStatsWidget(courseId: courseId)),
          ),
        );
      case lecturerClassTimer:
        final classId = args['classId'] as String?;
        if (classId == null || classId.isEmpty) {
          return _buildMissingArgsRoute('classId');
        }
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Class Timer')),
            body: RoleGuard(allowedRoles: const ['lecturer'], child: ctw.ClassTimerWidget(classId: classId)),
          ),
        );
      case lecturerNotifications:
        final notification = args['notification'] as Map<String, dynamic>?;
        if (notification == null) {
          return _buildMissingArgsRoute('notification');
        }
        final onTap = args['onTap'] as VoidCallback? ?? () {};
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Notifications')),
            body: RoleGuard(allowedRoles: const ['lecturer'], child: NotificationCardWidget(notification: notification, onTap: onTap)),
          ),
        );
      case lecturerVenueMap:
        final fromVenue = args['fromVenue'] as String?;
        final toVenue = args['toVenue'] as String?;
        if (fromVenue == null || toVenue == null || fromVenue.isEmpty || toVenue.isEmpty) {
          return _buildMissingArgsRoute('fromVenue and toVenue');
        }
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Venue Map')),
            body: RoleGuard(allowedRoles: const ['lecturer'], child: VenueMapWidget(fromVenue: fromVenue, toVenue: toVenue)),
          ),
        );
      default:
        final builder = routes[settings.name];
        if (builder != null) return MaterialPageRoute(builder: builder);
        return null;
    }
  }

  static Route<dynamic> _buildMissingArgsRoute(String requiredArg) {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Missing required route argument: $requiredArg'),
          ),
        ),
      ),
    );
  }
}
