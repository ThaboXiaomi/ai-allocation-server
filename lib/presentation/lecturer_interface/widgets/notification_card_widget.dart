import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For time formatting (add to pubspec.yaml if not present)

import '../../../theme/app_theme.dart';
import '../../../widgets/custom_icon_widget.dart';

class NotificationCardWidget extends StatelessWidget {
  final Map<String, dynamic> notification;
  final VoidCallback onTap;

  const NotificationCardWidget({
    Key? key,
    required this.notification,
    required this.onTap,
  }) : super(key: key);

  Future<void> _markAsRead(String notificationId) async {
    try {
      // Update the notification's `isRead` status in Firestore
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  String _formatTime(String? time) {
    if (time == null || time.isEmpty) return '';
    try {
      final dateTime = DateTime.parse(time);
      return DateFormat('MMM d, h:mm a').format(dateTime);
    } catch (_) {
      return time;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isRead = notification["isRead"] ?? false;
    final String type = notification["type"] ?? "";
    final String notificationId = notification["id"] ?? "";

    Color backgroundColor;
    Color iconColor;
    String iconName;

    switch (type) {
      case "venue_change":
        backgroundColor = isRead ? AppTheme.neutral50 : AppTheme.warning100;
        iconColor = AppTheme.warning600;
        iconName = 'location_on';
        break;
      case "check_in":
        backgroundColor = isRead ? AppTheme.neutral50 : AppTheme.success100;
        iconColor = AppTheme.success600;
        iconName = 'how_to_reg';
        break;
      default:
        backgroundColor = isRead ? AppTheme.neutral50 : AppTheme.primary100;
        iconColor = AppTheme.primary600;
        iconName = 'notifications';
    }

    return AnimatedOpacity(
      opacity: 1.0,
      duration: const Duration(milliseconds: 400),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Material(
          elevation: isRead ? 1 : 4,
          borderRadius: BorderRadius.circular(16),
          color: backgroundColor,
          child: InkWell(
            onTap: () async {
              // Mark the notification as read in Firestore
              if (!isRead) {
                await _markAsRead(notificationId);
              }
              // Trigger the onTap callback
              onTap();
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isRead ? Colors.transparent : iconColor.withOpacity(0.18),
                  width: 1.2,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    alignment: Alignment.topRight,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: iconColor.withOpacity(0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                          border: Border.all(color: iconColor.withAlpha(60)),
                        ),
                        child: CustomIconWidget(
                          iconName: iconName,
                          color: iconColor,
                          size: 26,
                        ),
                      ),
                      if (!isRead)
                        Positioned(
                          right: 2,
                          top: 2,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: iconColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: iconColor.withOpacity(0.3),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notification["title"] ?? "",
                          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                            fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
                            fontSize: 17,
                            color: AppTheme.neutral900,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          notification["message"] ?? "",
                          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                            color: AppTheme.neutral700,
                            fontSize: 15,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(Icons.access_time, size: 15, color: AppTheme.neutral400),
                            const SizedBox(width: 4),
                            Text(
                              _formatTime(notification["time"]),
                              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                                color: AppTheme.neutral400,
                                fontSize: 13,
                              ),
                            ),
                          ],
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
}
