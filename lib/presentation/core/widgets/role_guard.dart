import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lecture_room_allocator/routes/app_routes.dart';

class RoleGuard extends StatelessWidget {
  final List<String> allowedRoles;
  final Widget child;

  const RoleGuard({
    Key? key,
    required this.allowedRoles,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const _UnauthorizedScreen(message: 'Please sign in to continue.');
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const _UnauthorizedScreen(message: 'Unable to verify your account role.');
        }

        final data = snapshot.data!.data() as Map<String, dynamic>?;
        final role = (data?['role'] as String? ?? '').toLowerCase();
        final allowed = allowedRoles.map((e) => e.toLowerCase()).toList();

        if (!allowed.contains(role)) {
          return const _UnauthorizedScreen(message: 'You are not authorized to access this page.');
        }

        return child;
      },
    );
  }
}

class _UnauthorizedScreen extends StatelessWidget {
  final String message;

  const _UnauthorizedScreen({required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, size: 48, color: Colors.redAccent),
              const SizedBox(height: 12),
              const Text('Unauthorized', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    AppRoutes.portalSelection,
                    (route) => false,
                  );
                },
                icon: const Icon(Icons.home_outlined),
                label: const Text('Go to Portal Selection'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
