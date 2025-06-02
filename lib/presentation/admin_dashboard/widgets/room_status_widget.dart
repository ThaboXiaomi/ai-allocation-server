import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/custom_icon_widget.dart';

class RoomStatusWidget extends StatelessWidget {
  final Map<String, dynamic> roomData;

  const RoomStatusWidget({
    Key? key,
    required this.roomData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double utilization = (roomData["utilization"] ?? 0.0) as double;
    final Color statusColor = _getStatusColor(utilization);
    final String roomName = roomData["name"] ?? "Unknown Room";
    final int occupiedRooms = roomData["occupiedRooms"] ?? 0;
    final int totalRooms = roomData["totalRooms"] ?? 0;

    return Tooltip(
      message: "Room: $roomName\nUtilization: ${(utilization * 100).toInt()}%",
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              statusColor.withOpacity(0.08),
              Theme.of(context).cardColor,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: statusColor.withOpacity(0.10),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: statusColor.withOpacity(0.25),
            width: 1.2,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      statusColor.withOpacity(0.18),
                      statusColor.withOpacity(0.08),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: statusColor.withOpacity(0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: CustomIconWidget(
                    iconName: 'apartment',
                    color: statusColor,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      roomName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.meeting_room_outlined,
                            size: 16, color: AppTheme.neutral500),
                        const SizedBox(width: 4),
                        Text(
                          '$occupiedRooms/$totalRooms rooms in use',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.neutral600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: utilization,
                        minHeight: 6,
                        backgroundColor: AppTheme.neutral200,
                        valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.circle,
                        color: statusColor,
                        size: 12,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${(utilization * 100).toInt()}%',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _viewRoomDetails(context, roomData),
                    icon: const Icon(Icons.info_outline, size: 18),
                    label: const Text("Details"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: statusColor.withOpacity(0.15),
                      foregroundColor: statusColor,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      textStyle: Theme.of(context)
                          .textTheme
                          .labelLarge
                          ?.copyWith(fontWeight: FontWeight.w600),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(double utilization) {
    if (utilization < 0.5) {
      return AppTheme.success600; // Low utilization - good
    } else if (utilization < 0.8) {
      return AppTheme.warning600; // Medium utilization - warning
    } else {
      return AppTheme.error600; // High utilization - critical
    }
  }

  void _viewRoomDetails(BuildContext context, Map<String, dynamic> roomData) {
    showDialog(
      context: context,
      builder: (context) {
        final double utilization = (roomData["utilization"] ?? 0.0) as double;
        final Color statusColor = _getStatusColor(utilization);
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              CustomIconWidget(
                iconName: 'apartment',
                color: statusColor,
                size: 22,
              ),
              const SizedBox(width: 10),
              Text(roomData["name"] ?? "Room Details"),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow(Icons.meeting_room_outlined, "Occupied Rooms",
                  "${roomData["occupiedRooms"] ?? 0}"),
              _detailRow(Icons.domain_outlined, "Total Rooms",
                  "${roomData["totalRooms"] ?? 0}"),
              _detailRow(Icons.percent, "Utilization",
                  "${(utilization * 100).toStringAsFixed(1)}%"),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.neutral500),
          const SizedBox(width: 8),
          Text(
            "$label: ",
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(value),
        ],
      ),
    );
  }
}
