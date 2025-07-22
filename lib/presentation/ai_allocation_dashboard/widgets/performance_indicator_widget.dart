import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/custom_icon_widget.dart';

class PerformanceIndicatorWidget extends StatelessWidget {
  final String documentId; // Firestore document ID
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  PerformanceIndicatorWidget({
    Key? key,
    required this.documentId,
  }) : super(key: key);

  /// Fetch performance data from Firestore
  Future<Map<String, dynamic>> _fetchPerformanceData() async {
    try {
      final docSnapshot = await firestore.collection('performanceIndicators').doc(documentId).get();

      if (docSnapshot.exists) {
        return docSnapshot.data()!;
      } else {
        throw Exception('Performance data not found');
      }
    } catch (e) {
      print('Error fetching performance data: $e');
      return {};
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _fetchPerformanceData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('Error loading performance data.'));
        }

        final data = snapshot.data!;
        final String title = data['title'] ?? 'N/A';
        final String value = data['value'] ?? '0';
        final String icon = data['icon'] ?? 'info';
        final Color color = _getColorFromHex(data['color'] ?? '#000000');
        final String trend = data['trend'] ?? '0%';
        final bool trendUp = data['trendUp'] ?? true;

        return _buildPerformanceIndicator(
          title: title,
          value: value,
          icon: icon,
          color: color,
          trend: trend,
          trendUp: trendUp,
        );
      },
    );
  }

  Widget _buildPerformanceIndicator({
    required String title,
    required String value,
    required String icon,
    required Color color,
    required String trend,
    required bool trendUp,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(13),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withAlpha(51),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withAlpha(26),
                  shape: BoxShape.circle,
                ),
                child: CustomIconWidget(
                  iconName: icon,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.neutral700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              CustomIconWidget(
                iconName: trendUp ? 'trending_up' : 'trending_down',
                color: trendUp ? AppTheme.success600 : AppTheme.error600,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                trend,
                style: TextStyle(
                  color: trendUp ? AppTheme.success600 : AppTheme.error600,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Helper method to convert a hex color string to a [Color] object
  Color _getColorFromHex(String hexColor) {
    hexColor = hexColor.replaceFirst('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor'; // Add alpha value if missing
    }
    return Color(int.parse(hexColor, radix: 16));
  }
}
