import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/custom_icon_widget.dart';

class LectureCardWidget extends StatelessWidget {
  final Map<String, dynamic> lecture;
  final VoidCallback onViewMap;

  const LectureCardWidget({
    Key? key,
    required this.lecture,
    required this.onViewMap,
  }) : super(key: key);

  Future<void> _handleCheckIn(BuildContext context) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("User not logged in");
      }

      final lectureId = lecture["id"];
      final checkInRef = FirebaseFirestore.instance
          .collection('lectures')
          .doc(lectureId)
          .collection('attendance')
          .doc(user.uid);

      // Check if the user has already checked in
      final checkInDoc = await checkInRef.get();
      if (checkInDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("You have already checked in.")),
        );
        return;
      }

      // Record the check-in
      await checkInRef.set({
        "timestamp": FieldValue.serverTimestamp(),
        "userId": user.uid,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Check-in successful!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error during check-in: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isReallocated = lecture["isReallocated"] ?? false;
    final bool isCheckInAvailable = lecture["checkInAvailable"] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: isReallocated ? Colors.amber.shade300 : AppTheme.neutral200,
          width: isReallocated ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          // Header with course code and time
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isReallocated ? Colors.amber.shade100 : AppTheme.neutral50,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isReallocated
                              ? Colors.amber.shade50
                              : AppTheme.primary50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isReallocated
                                ? Colors.amber.shade300
                                : AppTheme.primary300,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.book_rounded,
                              color: isReallocated
                                  ? Colors.amber.shade700
                                  : AppTheme.primary700,
                              size: 20,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              lecture["courseCode"]?.toString() ?? "N/A",
                              style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                                color: isReallocated
                                    ? Colors.amber.shade700
                                    : AppTheme.primary700,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                color: AppTheme.primary600,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${lecture["startTime"]?.toString() ?? "N/A"} - ${lecture["endTime"]?.toString() ?? "N/A"}',
                                style: AppTheme.lightTheme.textTheme.bodyMedium
                                    ?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                          if (isReallocated)
                            Row(
                              children: [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  color: Colors.amber.shade600,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Venue Changed',
                                  style: AppTheme.lightTheme.textTheme.bodySmall
                                      ?.copyWith(
                                    color: Colors.amber.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(lecture["status"]?.toString() ?? "")
                        .withAlpha(26),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _getStatusColor(lecture["status"]?.toString() ?? "")
                          .withAlpha(77),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        lecture["status"] == "ongoing"
                            ? Icons.play_circle_fill_rounded
                            : lecture["status"] == "completed"
                                ? Icons.check_circle_rounded
                                : Icons.schedule_rounded,
                        color: _getStatusColor(lecture["status"]?.toString() ?? ""),
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _getStatusText(lecture["status"]?.toString() ?? ""),
                        style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                          color: _getStatusColor(lecture["status"]?.toString() ?? ""),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Course details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lecture["courseTitle"]?.toString() ?? "N/A",
                  style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildInfoItem(
                      icon: 'person',
                      label: lecture["instructor"]?.toString() ?? "N/A",
                    ),
                    const SizedBox(width: 16),
                    _buildInfoItem(
                      icon: 'room',
                      label: 'Room ${lecture["venue"]?.toString() ?? "N/A"}',
                      isHighlighted: isReallocated,
                      highlightColor: AppTheme.warning600,
                    ),
                  ],
                ),
                if (isReallocated) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      CustomIconWidget(
                        iconName: 'swap_horiz',
                        color: Colors.amber.shade600,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Changed from Room ${lecture["originalVenue"]?.toString() ?? "N/A"}',
                        style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                          color: Colors.amber.shade600,
                        ),
                      ),
                    ],
                  ),
                ],

                // Action buttons
                const SizedBox(height: 16),
                Row(
                  children: [
                    if (isCheckInAvailable) ...[
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const CustomIconWidget(
                            iconName: 'qr_code_scanner',
                            color: Colors.white,
                            size: 18,
                          ),
                          label: const Text('Check In'),
                          onPressed: () => _handleCheckIn(context),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const CustomIconWidget(
                          iconName: 'map',
                          color: AppTheme.primary600,
                          size: 18,
                        ),
                        label: const Text('View Map'),
                        onPressed: onViewMap,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required String icon,
    required String label,
    bool isHighlighted = false,
    Color highlightColor = AppTheme.primary600,
  }) {
    IconData? iconData;
    switch (icon) {
      case 'person':
        iconData = Icons.person_rounded;
        break;
      case 'room':
        iconData = Icons.meeting_room_rounded;
        break;
      case 'swap_horiz':
        iconData = Icons.swap_horiz_rounded;
        break;
      case 'warning':
        iconData = Icons.warning_amber_rounded;
        break;
      case 'map':
        iconData = Icons.map_rounded;
        break;
      case 'qr_code_scanner':
        iconData = Icons.qr_code_scanner_rounded;
        break;
      default:
        iconData = Icons.info_outline_rounded;
    }
    return Row(
      children: [
        Icon(
          iconData,
          color: isHighlighted ? highlightColor : AppTheme.neutral600,
          size: 16,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
            color: isHighlighted ? highlightColor : null,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'ongoing':
        return AppTheme.success600;
      case 'upcoming':
        return AppTheme.primary600;
      case 'completed':
        return AppTheme.neutral600;
      default:
        return AppTheme.neutral600;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'ongoing':
        return 'In Progress';
      case 'upcoming':
        return 'Upcoming';
      case 'completed':
        return 'Completed';
      default:
        return 'Scheduled';
    }
  }
}
