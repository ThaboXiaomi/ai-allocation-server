import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

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

  Future<void> _markAsRead(BuildContext context) async {
    try {
      final String notificationId = notification["id"];
      if (notificationId.isEmpty) return;

      // Update the `isRead` field in Firestore
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notificationId)
          .update({"isRead": true});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error marking notification as read: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isRead = notification["isRead"] ?? false;
    final String type = notification["type"] ?? "system";

    return InkWell(
      onTap: () {
        _markAsRead(context);
        onTap();
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isRead ? null : _getNotificationColor(type).withAlpha(13),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getNotificationColor(type).withAlpha(26),
                shape: BoxShape.circle,
              ),
              child: CustomIconWidget(
                iconName: _getNotificationIcon(type),
                color: _getNotificationColor(type),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification["title"] ?? "",
                    style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                      fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification["message"] ?? "",
                    style: AppTheme.lightTheme.textTheme.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        notification["time"] ?? "",
                        style: AppTheme.lightTheme.textTheme.bodySmall,
                      ),
                      if (type == "venue_change" &&
                          notification["walkingTime"] != null) ...[
                        const SizedBox(width: 8),
                        const CustomIconWidget(
                          iconName: 'directions_walk',
                          color: AppTheme.neutral500,
                          size: 14,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${notification["walkingTime"]} min walk',
                          style:
                              AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (!isRead)
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _getNotificationColor(type),
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'venue_change':
        return AppTheme.warning600;
      case 'reminder':
        return AppTheme.primary600;
      case 'system':
        return AppTheme.info600;
      default:
        return AppTheme.neutral600;
    }
  }

  String _getNotificationIcon(String type) {
    switch (type) {
      case 'venue_change':
        return 'swap_horiz';
      case 'reminder':
        return 'alarm';
      case 'system':
        return 'info';
      default:
        return 'notifications';
    }
  }
}
