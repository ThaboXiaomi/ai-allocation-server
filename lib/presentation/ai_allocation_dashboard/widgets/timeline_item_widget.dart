import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/custom_icon_widget.dart';

class TimelineItemWidget extends StatelessWidget {
  final String timeSlotId; // Firestore document ID for the time slot
  final bool isLast;

  const TimelineItemWidget({
    Key? key,
    required this.timeSlotId,
    this.isLast = false,
  }) : super(key: key);

  /// Fetch time slot data from Firestore
  Future<Map<String, dynamic>> _fetchTimeSlotData() async {
    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('timeSlots')
          .doc(timeSlotId)
          .get();

      if (docSnapshot.exists) {
        return docSnapshot.data()!;
      } else {
        throw Exception('Time slot not found');
      }
    } catch (e) {
      print('Error fetching time slot data: $e');
      return {};
    }
  }


  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _fetchTimeSlotData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('Error loading time slot data.'));
        }

        final timeSlot = snapshot.data!;
        final List<dynamic> events = timeSlot['events'] ?? [];

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 80,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Text(
                  timeSlot['time'] ?? 'N/A',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.neutral700,
                  ),
                ),
              ),
            ),
            Container(
              width: 24,
              alignment: Alignment.center,
              child: Column(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: events.isEmpty
                          ? AppTheme.neutral300
                          : AppTheme.primary600,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                    ),
                  ),
                  if (!isLast)
                    Container(
                      width: 2,
                      height:
                          events.isEmpty ? 40 : (events.length * 80).toDouble(),
                      color: AppTheme.neutral300,
                    ),
                ],
              ),
            ),
            Expanded(
              child: events.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'No scheduled allocations',
                        style: TextStyle(
                          color: AppTheme.neutral500,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: List.generate(
                        events.length,
                        (index) => _buildEventCard(events[index]),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
    final bool isReallocation = event['isReallocation'] ?? false;

    return Container(
      margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getColorFromHex(event['color'] ?? '#000000').withAlpha(77),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getColorFromHex(event['color'] ?? '#000000')
                      .withAlpha(26),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  event['status'] ?? 'N/A',
                  style: TextStyle(
                    color: _getColorFromHex(event['color'] ?? '#000000'),
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.neutral100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  event['faculty'] ?? 'N/A',
                  style: const TextStyle(
                    color: AppTheme.neutral700,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ),
              if (isReallocation) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primary100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      CustomIconWidget(
                        iconName: 'swap_horiz',
                        color: AppTheme.primary600,
                        size: 12,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Reallocated',
                        style: TextStyle(
                          color: AppTheme.primary700,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            event['course'] ?? 'N/A',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const CustomIconWidget(
                iconName: 'meeting_room',
                color: AppTheme.neutral600,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                'Venue: ${event['venue'] ?? 'N/A'}',
                style: const TextStyle(
                  color: AppTheme.neutral700,
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
