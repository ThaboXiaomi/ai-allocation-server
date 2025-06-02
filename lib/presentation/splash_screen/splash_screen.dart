import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:lecture_room_allocator/routes/app_routes.dart';

class AppRoutes {
  static const String adminLogin = '/adminLogin';
  static const String lecturerAuth = '/lecturerAuth';
  static const String studentAuth = '/studentAuth';
  static const String login = '/login'; // Added login route
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Log splash screen visit to Firebase Analytics
    await FirebaseAnalytics.instance.logEvent(name: 'splash_screen_visited');

    // Simulate a delay for splash screen
    await Future.delayed(const Duration(seconds: 2));

    // Check if the user is logged in
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // Fetch user role from Firestore
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final userRole = userDoc.data()?['role'] ?? 'Student';

      // Navigate to the appropriate portal based on the user's role
      switch (userRole) {
        case 'Admin':
          Navigator.pushReplacementNamed(context, AppRoutes.adminLogin);
          break;
        case 'Lecturer':
          Navigator.pushReplacementNamed(context, AppRoutes.lecturerAuth);
          break;
        case 'Student':
        default:
          Navigator.pushReplacementNamed(context, AppRoutes.studentAuth);
          break;
      }
    } else {
      // Navigate to the login screen if the user is not logged in
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue, Colors.lightBlueAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.school, size: 80, color: Colors.white),
              SizedBox(height: 20),
              Text(
                'Lecture Room Allocator',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 10),
              CircularProgressIndicator(color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}
