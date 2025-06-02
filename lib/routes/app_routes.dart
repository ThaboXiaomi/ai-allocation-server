import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:lecture_room_allocator/presentation/portal_selection_screen/portal_selection_screen.dart';
import 'package:lecture_room_allocator/presentation/student_auth_screen/student_auth_screen.dart';
import 'package:lecture_room_allocator/presentation/admin_login/admin_auth_screen.dart';
import 'package:lecture_room_allocator/presentation/lecturer_auth_screen/lecturer_auth_screen.dart';
import 'package:lecture_room_allocator/presentation/student_dashboard/student_dashboard.dart';
import 'package:lecture_room_allocator/presentation/admin_dashboard/admin_dashboard.dart';
import 'package:lecture_room_allocator/presentation/lecturer_interface/lecturer_interface.dart';
import 'package:lecture_room_allocator/presentation/course_management/course_management.dart';
import 'package:lecture_room_allocator/presentation/ai_allocation_dashboard/ai_allocation_dashboard.dart';

class AppRoutes {
  static const String portalSelection = '/portal-selection';

  static const String studentAuth = '/student-auth';
  static const String adminAuth = '/admin-auth';
  static const String lecturerAuth = '/lecturer-auth';

  static const String studentDashboard = '/student-dashboard';
  static const String adminDashboard = '/admin-dashboard';
  static const String lecturerDashboard = '/lecturer-dashboard';

  static const String courseManagement = '/course-management';
  static const String aiAllocationDashboard = '/ai-allocation-dashboard';

  static final Map<String, WidgetBuilder> routes = {
    portalSelection: (_) => const PortalSelectionScreen(),
    studentAuth: (_) => const StudentAuthScreen(),
    adminAuth: (_) => const AdminAuthScreen(),
    lecturerAuth: (_) => const LecturerAuthScreen(),
    studentDashboard: (_) => const StudentDashboard(),
    adminDashboard: (_) => const AdminDashboard(),
    lecturerDashboard: (_) => const LecturerInterface(),
    courseManagement: (_) => const CourseManagement(),
    aiAllocationDashboard: (_) => const AIAllocationDashboard(),
  };

  /// Dynamically determine the initial screen based on auth state
  static Widget getInitialScreen() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const PortalSelectionScreen();
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get(),
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
            return const StudentDashboard();
        }
      },
    );
  }
}