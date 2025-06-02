import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/custom_icon_widget.dart';

class ClassTimerWidget extends StatefulWidget {
  final String classId; // Unique class ID for fetching schedule data

  const ClassTimerWidget({
    Key? key,
    required this.classId,
  }) : super(key: key);

  @override
  State<ClassTimerWidget> createState() => _ClassTimerWidgetState();
}

class _ClassTimerWidgetState extends State<ClassTimerWidget> {
  Timer? _timer;
  DateTime? _endTime;
  Duration _remainingTime = const Duration(hours: 2);
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchClassSchedule();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchClassSchedule() async {
    try {
      // Fetch class schedule from Firestore
      final doc = await FirebaseFirestore.instance
          .collection('lectures')
          .doc(widget.classId)
          .get();
      final data = doc.data();
      if (data != null && data['endTime'] != null) {
        _endTime = DateTime.parse(data['endTime']);
        _updateRemainingTime();
        _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateRemainingTime());
      }
    } catch (e) {
      debugPrint('Error fetching class schedule: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _updateRemainingTime() {
    if (_endTime == null) return;
    final now = DateTime.now();
    setState(() {
      _remainingTime = _endTime!.isAfter(now)
          ? _endTime!.difference(now)
          : Duration.zero;
    });
    if (_remainingTime == Duration.zero) {
      _timer?.cancel();
      _updateClassStatus();
    }
  }

  Future<void> _updateClassStatus() async {
    try {
      // Update class status in Firestore
      await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .update({'status': 'Completed'});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Class status updated to "Completed".')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating class status: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Add this check:
    if (_endTime == null) {
      return const Center(child: Text('No class end time found.'));
    }

    final int hours = _remainingTime.inHours;
    final int minutes = _remainingTime.inMinutes.remainder(60);
    final int seconds = _remainingTime.inSeconds.remainder(60);

    final Color timerColor = _getTimerColor();

    // Calculate progress (0.0 to 1.0)
    final totalDuration = _endTime!.difference(_endTime!.subtract(_remainingTime));
    final double progress = totalDuration.inSeconds == 0
        ? 1.0
        : 1.0 - (_remainingTime.inSeconds / totalDuration.inSeconds);

    return Center(
      child: Container(
        width: 320,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(
            color: Colors.white.withOpacity(0.18),
            width: 1.5,
          ),
          // Glassmorphism effect
          backgroundBlendMode: BlendMode.overlay,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Timer Icon with subtle background
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: timerColor.withOpacity(0.12),
                boxShadow: [
                  BoxShadow(
                    color: timerColor.withOpacity(0.18),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: CustomIconWidget(
                iconName: 'timer',
                color: timerColor,
                size: 32,
              ),
            ),
            const SizedBox(height: 18),
            // Timer Text
            Text(
              '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
              style: TextStyle(
                color: timerColor,
                fontWeight: FontWeight.w700,
                fontFamily: 'monospace',
                fontSize: 36,
                letterSpacing: 2,
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: Colors.white.withOpacity(0.18),
                valueColor: AlwaysStoppedAnimation<Color>(timerColor),
              ),
            ),
            const SizedBox(height: 10),
            // Status Text
            Text(
              _remainingTime == Duration.zero
                  ? 'Class Completed'
                  : _remainingTime.inMinutes <= 5
                      ? 'Ending Soon'
                      : 'Ongoing',
              style: TextStyle(
                color: timerColor,
                fontWeight: FontWeight.w500,
                fontSize: 16,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getTimerColor() {
    if (_remainingTime.inMinutes <= 5) {
      return AppTheme.error600;
    } else if (_remainingTime.inMinutes <= 15) {
      return AppTheme.warning600;
    } else {
      return Colors.white;
    }
  }
}
