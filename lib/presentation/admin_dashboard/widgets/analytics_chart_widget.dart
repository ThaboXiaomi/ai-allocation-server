import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';


class AnalyticsChartWidget extends StatelessWidget {
  final List<Map<String, dynamic>> weeklyData;

  const AnalyticsChartWidget({
    Key? key,
    required this.weeklyData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              'Weekly Allocation Performance',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: AppTheme.primary600,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Allocations per day with conflict counts',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.neutral500,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              height: 220,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primary100,
                    Colors.white,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.only(top: 16, right: 16, left: 8),
              child: Semantics(
                label: "Weekly Allocation Performance Chart",
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: 160,
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: AppTheme.neutral200,
                        strokeWidth: 1,
                        dashArray: [4, 4],
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        tooltipBgColor: AppTheme.primary600.withAlpha(220),
                        tooltipPadding: const EdgeInsets.all(10),
                        tooltipMargin: 12,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final conflicts = weeklyData[groupIndex]["conflicts"];
                          return BarTooltipItem(
                            '${weeklyData[groupIndex]["day"]}\n'
                            'Allocations: ${rod.y.round()}\n'
                            'Conflicts: $conflicts',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 36,
                        getTitles: (value) {
                          final index = value.toInt();
                          if (index < 0 || index >= weeklyData.length) {
                            return '';
                          }
                          final day = weeklyData[index]["day"];
                          return day;
                        },
                      ),
                      leftTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitles: (value) {
                          return value.toInt().toString();
                        },
                      ),
                      rightTitles: SideTitles(showTitles: false),
                      topTitles: SideTitles(showTitles: false),
                    ),
                    barGroups: List.generate(
                      weeklyData.length,
                      (index) => BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            y: weeklyData[index]["allocations"].toDouble(),
                            colors: [AppTheme.primary600],
                            width: 18,
                            borderRadius: BorderRadius.circular(8),
                            backDrawRodData: BackgroundBarChartRodData(
                              show: true,
                              y: 160,
                              colors: [AppTheme.primary100],
                            ),
                          ),
                        ],
                        showingTooltipIndicators: [0],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _LegendDot(color: AppTheme.primary600),
                const SizedBox(width: 6),
                Text(
                  'Allocations',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.primary600,
                  ),
                ),
                const SizedBox(width: 18),
                _LegendDot(color: AppTheme.primary100),
                const SizedBox(width: 6),
                Text(
                  'Max Capacity',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.neutral400,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  const _LegendDot({required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
