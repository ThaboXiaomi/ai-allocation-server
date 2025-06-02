import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../../theme/app_theme.dart';

class AppTheme {
  static const Color neutral800 = Color(0xFF333333);
  static const Color primary600 = Color(0xFF007BFF);
  static const Color warning600 = Color(0xFFFFA500);
  static const Color neutral200 = Color(0xFFCCCCCC);

  static final TextTheme lightTheme = TextTheme(
    bodySmall: TextStyle(fontSize: 12, color: Colors.black),
  );
}

class AllocationChartWidget extends StatelessWidget {
  static const Color neutral800 =
      Color(0xFF333333); // Replace with your desired color

  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final Color tooltipBgColor; // Define the parameter

  AllocationChartWidget({
    Key? key,
    this.tooltipBgColor = Colors.white, // Provide a default value if needed
  }) : super(key: key);

  /// Fetch data from the Gemini API
  Future<List<Map<String, dynamic>>> _fetchDataFromGeminiAPI() async {
    try {
      // Replace with your Gemini API endpoint
      const String apiUrl = 'https://api.gemini.com/your-endpoint';
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        // Parse the response body
        final List<dynamic> responseData = json.decode(response.body);
        return responseData.map((item) {
          return {
            'day': item['day'],
            'optimizationRate': item['optimizationRate'],
            'utilization': item['utilization'],
          };
        }).toList();
      } else {
        throw Exception('Failed to fetch data from Gemini API');
      }
    } catch (e) {
      print('Error fetching data from Gemini API: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: tooltipBgColor, // Use the parameter
      child: Text('Allocation Chart'),
    );
  }

  /// Build the line chart with the provided data
  Widget _buildLineChart(List<Map<String, dynamic>> data) {
    return Semantics(
      label: "Weekly Performance Trends Line Chart",
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 10,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: AppTheme.neutral200,
                strokeWidth: 1,
                dashArray: [5, 5],
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitles: (value) {
                if (value >= 0 && value < data.length) {
                  return data[value.toInt()]['day'];
                }
                return '';
              },
            ),
            leftTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitles: (value) {
                if (value % 20 == 0) {
                  return '${value.toInt()}%';
                }
                return '';
              },
            ),
            topTitles: SideTitles(
              showTitles: false,
            ),
            rightTitles: SideTitles(
              showTitles: false,
            ),
          ),
          minX: 0,
          maxX: data.length - 1,
          minY: 60,
          maxY: 100,
          lineBarsData: [
            // Optimization Rate Line
            LineChartBarData(
              spots: List.generate(
                data.length,
                (index) => FlSpot(
                  index.toDouble(),
                  data[index]['optimizationRate'],
                ),
              ),
              isCurved: true,
              colors: [AppTheme.primary600],
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: AppTheme.primary600,
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                colors: [
                  AppTheme.primary600.withAlpha(26),
                  AppTheme.primary600.withAlpha(10),
                ],
              ),
            ),
            // Utilization Line
            LineChartBarData(
              spots: List.generate(
                data.length,
                (index) => FlSpot(
                  index.toDouble(),
                  data[index]['utilization'],
                ),
              ),
              isCurved: true,
              colors: [
                AppTheme.warning600.withAlpha(26),
                AppTheme.warning600.withAlpha(10),
              ],
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: AppTheme.warning600,
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradientColorStops: [0.0, 1.0],
                colors: [AppTheme.warning600.withAlpha(26)],
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              tooltipBgColor: AppTheme.neutral800.withAlpha(204),
              getTooltipItems: (List<LineBarSpot> touchedSpots) {
                return touchedSpots.map((spot) {
                  final String title = spot.barIndex == 0
                      ? 'Optimization Rate'
                      : 'Venue Utilization';
                  final Color color = spot.barIndex == 0
                      ? AppTheme.primary600
                      : AppTheme.warning600;

                  return LineTooltipItem(
                    '$title: ${spot.y.toStringAsFixed(1)}%',
                    TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }
}
