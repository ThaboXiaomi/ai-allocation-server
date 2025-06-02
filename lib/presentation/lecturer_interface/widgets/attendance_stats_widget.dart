import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'dart:ui'; // For glassmorphism effect

import '../../../theme/app_theme.dart';
import '../../../widgets/custom_icon_widget.dart';

class AttendanceStatsWidget extends StatefulWidget {
  final String courseId; // Unique course ID for fetching attendance data

  const AttendanceStatsWidget({
    Key? key,
    required this.courseId,
  }) : super(key: key);

  @override
  State<AttendanceStatsWidget> createState() => _AttendanceStatsWidgetState();
}

class _AttendanceStatsWidgetState extends State<AttendanceStatsWidget> {
  late Stream<DocumentSnapshot<Map<String, dynamic>>> _attendanceStream;

  @override
  void initState() {
    super.initState();
    // Initialize Firestore stream for real-time attendance data
    _attendanceStream = FirebaseFirestore.instance
        .collection('courses')
        .doc(widget.courseId)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _attendanceStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Error loading attendance data.'));
        }
        if (!snapshot.hasData || snapshot.data?.data() == null) {
          return const Center(child: Text('No attendance data available.'));
        }

        final data = snapshot.data!.data()!;
        final attendanceData =
            List<Map<String, dynamic>>.from(data['attendanceData']);
        final totalStudents = data['totalStudents'] ?? 0;

        return _buildElegantAttendanceCard(attendanceData, totalStudents);
      },
    );
  }

  Widget _buildElegantAttendanceCard(
      List<Map<String, dynamic>> attendanceData, int totalStudents) {
    final double attendanceRate =
        _calculateAttendanceRate(attendanceData, totalStudents);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primary100.withOpacity(0.7),
                  Colors.white.withOpacity(0.6),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary200.withOpacity(0.18),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
              border: Border.all(
                color: AppTheme.primary200.withOpacity(0.18),
                width: 1.2,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with icon and title
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.primary600.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(10),
                        child: const Icon(Icons.bar_chart_rounded,
                            color: AppTheme.primary600, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Text(
                        'Attendance Statistics',
                        style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.primary400.withOpacity(0.8),
                              AppTheme.primary600.withOpacity(0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.wifi_tethering_rounded,
                                color: AppTheme.primary50, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              'Live',
                              style: AppTheme.lightTheme.textTheme.labelMedium
                                  ?.copyWith(
                                color: AppTheme.primary50,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Animated Pie chart
                      SizedBox(
                        height: 170,
                        width: 170,
                        child: Semantics(
                          label: "Attendance Pie Chart",
                          child: PieChart(
                            PieChartData(
                              sectionsSpace: 2,
                              centerSpaceRadius: 48,
                              startDegreeOffset: -90,
                              sections: _getSections(attendanceData, totalStudents),
                              pieTouchData: PieTouchData(
                                enabled: true,
                                touchCallback: (FlTouchEvent event, pieTouchResponse) {},
                              ),
                            ),
                            swapAnimationDuration: const Duration(milliseconds: 900),
                            swapAnimationCurve: Curves.easeInOutCubic,
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                      // Legend
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ...attendanceData
                                .map((item) => _buildLegendItem(
                                      status: item["status"],
                                      count: item["count"],
                                      color: Color(int.parse(item["color"])),
                                    ))
                                .toList(),
                            const SizedBox(height: 10),
                            const Divider(thickness: 1.1),
                            const SizedBox(height: 10),
                            _buildLegendItem(
                              status: "Total",
                              count: totalStudents,
                              color: AppTheme.neutral800,
                              isBold: true,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  // Attendance rate with animated progress bar
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.neutral50.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.neutral200, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.neutral200.withOpacity(0.10),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const CustomIconWidget(
                          iconName: 'insights',
                          color: AppTheme.primary600,
                          size: 28,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Attendance Rate',
                                style: AppTheme.lightTheme.textTheme.bodyLarge
                                    ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TweenAnimationBuilder<double>(
                                tween: Tween<double>(begin: 0, end: attendanceRate),
                                duration: const Duration(milliseconds: 900),
                                curve: Curves.easeOutCubic,
                                builder: (context, value, child) {
                                  return LinearProgressIndicator(
                                    value: value,
                                    backgroundColor: AppTheme.neutral200,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      _getAttendanceRateColor(value),
                                    ),
                                    minHeight: 8,
                                    borderRadius: BorderRadius.circular(4),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 18),
                        TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0, end: attendanceRate),
                          duration: const Duration(milliseconds: 900),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, child) {
                            return Text(
                              '${(value * 100).toInt()}%',
                              style: AppTheme.lightTheme.textTheme.titleMedium
                                  ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: _getAttendanceRateColor(value),
                                fontSize: 22,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<PieChartSectionData> _getSections(
      List<Map<String, dynamic>> attendanceData, int totalStudents) {
    return attendanceData.map((item) {
      final double percentage =
          totalStudents > 0 ? (item["count"] / totalStudents) * 100 : 0;

      return PieChartSectionData(
        color: Color(int.parse(item["color"])),
        value: item["count"].toDouble(),
        title: percentage >= 10 ? '${percentage.toInt()}%' : '',
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Widget _buildLegendItem({
    required String status,
    required int count,
    required Color color,
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          if (!isBold)
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
          const SizedBox(width: 8),
          Text(
            status,
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          const Spacer(),
          Text(
            count.toString(),
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  double _calculateAttendanceRate(
      List<Map<String, dynamic>> attendanceData, int totalStudents) {
    final int presentCount = attendanceData.firstWhere(
        (item) => item["status"] == "Present",
        orElse: () => {"count": 0})["count"];

    return totalStudents > 0 ? presentCount / totalStudents : 0;
  }

  Color _getAttendanceRateColor(double rate) {
    if (rate >= 0.8) {
      return AppTheme.success600;
    } else if (rate >= 0.6) {
      return AppTheme.warning600;
    } else {
      return AppTheme.error600;
    }
  }
}
