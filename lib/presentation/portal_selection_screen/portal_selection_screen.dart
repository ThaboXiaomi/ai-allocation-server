import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

import 'package:lecture_room_allocator/routes/app_routes.dart';
import 'package:lecture_room_allocator/theme/app_theme.dart';

class PortalSelectionScreen extends StatelessWidget {
  const PortalSelectionScreen({Key? key}) : super(key: key);

  Future<void> _logAnalyticsEvent(String portal) async {
    await FirebaseAnalytics.instance.logEvent(
      name: 'portal_selected',
      parameters: {'portal': portal},
    );
  }

  Future<void> _trackUserSelection(String portal, BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // Save selected portal to Firestore (user document)
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        'role': portal.toLowerCase(), // Set role directly in user doc
        'selectedPortal': portal,
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)); // Merge to preserve existing fields
    }

    // Log analytics event
    await _logAnalyticsEvent(portal);

    // Navigate to the selected portal
    switch (portal) {
      case 'Admin':
        Navigator.pushNamed(context, AppRoutes.adminAuth);
        break;
      case 'Lecturer':
        Navigator.pushNamed(context, AppRoutes.lecturerAuth);
        break;
      case 'Student':
        Navigator.pushNamed(context, AppRoutes.studentAuth);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Redirect if user is already logged in
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.studentDashboard, // Replace with dynamic role-based redirect if needed
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Lecture Room Allocator',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.primary600,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.primary200,
              AppTheme.primary500,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(30.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Icon(
                  Icons.school,
                  size: 80,
                  color: AppTheme.primary700,
                ),
                const SizedBox(height: 20),
                Text(
                  'Select Your Portal',
                  textAlign: TextAlign.center,
                  style: AppTheme.lightTheme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            blurRadius: 2.0,
                            color: Colors.black.withOpacity(0.3),
                            offset: const Offset(1.0, 1.0),
                          ),
                        ],
                      ),
                ),
                const SizedBox(height: 50),
                _buildPortalButton(
                  context: context,
                  icon: Icons.admin_panel_settings,
                  label: 'Admin Portal',
                  onPressed: () => _trackUserSelection('Admin', context),
                ),
                const SizedBox(height: 25),
                _buildPortalButton(
                  context: context,
                  icon: Icons.school,
                  label: 'Lecturer Portal',
                  onPressed: () => _trackUserSelection('Lecturer', context),
                ),
                const SizedBox(height: 25),
                _buildPortalButton(
                  context: context,
                  icon: Icons.school_outlined,
                  label: 'Student Portal',
                  onPressed: () => _trackUserSelection('Student', context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPortalButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      icon: Icon(
        icon,
        size: 24,
        color: AppTheme.primary700,
      ),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 18,
          color: AppTheme.primary700,
          fontWeight: FontWeight.w600,
        ),
      ),
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white.withOpacity(0.9),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 5,
      ),
    );
  }
}