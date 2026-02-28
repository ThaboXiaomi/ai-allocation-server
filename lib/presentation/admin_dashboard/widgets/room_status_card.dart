import 'package:flutter/material.dart';

import 'package:lecture_room_allocator/theme/app_theme.dart';

class RoomStatusCard extends StatelessWidget {
  final String roomName;
  final String status;
  final int capacity;
  final int occupancy;

  const RoomStatusCard({
    Key? key,
    required this.roomName,
    required this.status,
    required this.capacity,
    required this.occupancy,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final statusLower = status.toLowerCase();
    final isAvailable = statusLower == 'available';
    final statusColor = isAvailable ? AppTheme.success600 : AppTheme.error600;
    final ratio = capacity > 0 ? (occupancy / capacity).clamp(0, 1).toDouble() : 0.0;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    roomName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text('Occupancy: $occupancy / $capacity'),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: ratio),
          ],
        ),
      ),
    );
  }
}
