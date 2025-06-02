import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/custom_icon_widget.dart';

class AttendanceStatsWidget extends StatelessWidget {
  final Map<String, dynamic> attendanceData;

  const AttendanceStatsWidget({
    Key? key,
    required this.attendanceData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Attendance Statistics',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text('Total Lectures: ${attendanceData["totalLectures"] ?? 0}'),
          Text('Attended: ${attendanceData["attendedLectures"] ?? 0}'),
          Text(
              'Attendance Percentage: ${attendanceData["attendancePercentage"] ?? 0}%'),
        ],
      ),
    );
  }
}
