import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:lecture_room_allocator/routes/app_routes.dart';
import 'package:lecture_room_allocator/theme/app_theme.dart';

class PortalSelectionScreen extends StatefulWidget {
  const PortalSelectionScreen({Key? key}) : super(key: key);

  @override
  State<PortalSelectionScreen> createState() => _PortalSelectionScreenState();
}

class _PortalSelectionScreenState extends State<PortalSelectionScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideIn;
  bool _didAttemptAutoRedirect = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _slideIn = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _redirectSignedInUser();
  }

  Future<void> _redirectSignedInUser() async {
    if (_didAttemptAutoRedirect) return;
    _didAttemptAutoRedirect = true;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final role = (doc.data()?['role'] as String? ?? 'student').toLowerCase();
    if (!mounted) return;

    if (role == 'admin') {
      Navigator.pushReplacementNamed(context, AppRoutes.adminDashboard);
    } else if (role == 'lecturer') {
      Navigator.pushReplacementNamed(context, AppRoutes.lecturerDashboard);
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.studentDashboard);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _logAnalyticsEvent(String portal) async {
    await FirebaseAnalytics.instance.logEvent(
      name: 'portal_selected',
      parameters: {'portal': portal},
    );
  }

  Future<void> _trackUserSelection(String portal, BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'role': portal.toLowerCase(),
        'selectedPortal': portal,
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    await _logAnalyticsEvent(portal);

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
    return Scaffold(
      body: Stack(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.98, end: 1.02),
            duration: const Duration(seconds: 6),
            curve: Curves.easeInOut,
            builder: (context, scale, _) {
              return Transform.scale(
                scale: scale,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF1877F2),
                        Color(0xFF0E5CC2),
                        Color(0xFF075E54),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeIn,
              child: SlideTransition(
                position: _slideIn,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 12),
                      const Text(
                        'Campus Connect',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Fast, social-inspired lecture coordination for everyone.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.92),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildStatsCard(),
                      const SizedBox(height: 18),
                      _buildPortalTile(
                        context: context,
                        icon: Icons.admin_panel_settings_rounded,
                        iconColor: const Color(0xFF1877F2),
                        title: 'Admin Hub',
                        subtitle: 'Oversee schedules, alerts, and room operations',
                        onTap: () => _trackUserSelection('Admin', context),
                      ),
                      const SizedBox(height: 14),
                      _buildPortalTile(
                        context: context,
                        icon: Icons.cast_for_education_rounded,
                        iconColor: const Color(0xFF075E54),
                        title: 'Lecturer Space',
                        subtitle: 'Run classes, track attendance, and check room updates',
                        onTap: () => _trackUserSelection('Lecturer', context),
                      ),
                      const SizedBox(height: 14),
                      _buildPortalTile(
                        context: context,
                        icon: Icons.groups_rounded,
                        iconColor: AppTheme.primary700,
                        title: 'Student Zone',
                        subtitle: 'See classes, room changes, and live notifications',
                        onTap: () => _trackUserSelection('Student', context),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.25)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(label: 'Realtime', value: '24/7'),
          _StatItem(label: 'Allocation', value: 'AI'),
          _StatItem(label: 'Notices', value: 'Instant'),
        ],
      ),
    );
  }

  Widget _buildPortalTile({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 5,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.black45),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12)),
      ],
    );
  }
}
