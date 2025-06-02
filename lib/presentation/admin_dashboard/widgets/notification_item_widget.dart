import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/custom_icon_widget.dart';

class NotificationItemWidget extends StatelessWidget {
  final Map<String, dynamic> notification;
  final VoidCallback? onTap;

  const NotificationItemWidget({
    Key? key,
    required this.notification,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isRead = notification['isRead'] == true;
    final String formattedTime = notification["time"] != null
        ? DateFormat('MMM d, h:mm a')
            .format(DateTime.parse(notification["time"]))
        : "Unknown Time";

    return Dismissible(
      key: Key(notification['id'] ?? UniqueKey().toString()),
      onDismissed: (direction) async {
        // Delete the notification from Firestore
        if (notification['id'] != null) {
          await FirebaseFirestore.instance
              .collection('notifications')
              .doc(notification['id'])
              .delete();
        }
      },
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          // Mark notification as read in Firestore
          if (!isRead && notification['id'] != null) {
            await FirebaseFirestore.instance
                .collection('notifications')
                .doc(notification['id'])
                .update({'isRead': true});
          }
          onTap?.call();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
          decoration: BoxDecoration(
            gradient: isRead
                ? null
                : LinearGradient(
                    colors: [
                      AppTheme.primary50.withOpacity(0.7),
                      Colors.white,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            color: isRead ? Colors.white : null,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: isRead ? AppTheme.neutral100 : AppTheme.primary100,
              width: 1.2,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: isRead
                      ? null
                      : LinearGradient(
                          colors: [
                            AppTheme.primary100,
                            AppTheme.primary50,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                  color: isRead ? AppTheme.neutral100 : null,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary100.withOpacity(0.15),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: CustomIconWidget(
                  iconName: 'notifications',
                  color: isRead ? AppTheme.neutral600 : AppTheme.primary600,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification["title"] ?? "No Title",
                            style: AppTheme.lightTheme.textTheme.titleMedium
                                ?.copyWith(
                              fontWeight:
                                  isRead ? FontWeight.w500 : FontWeight.bold,
                              color: isRead
                                  ? AppTheme.neutral700
                                  : AppTheme.primary700,
                              letterSpacing: 0.1,
                            ),
                          ),
                        ),
                        if (!isRead)
                          Container(
                            width: 10,
                            height: 10,
                            margin: const EdgeInsets.only(left: 6),
                            decoration: const BoxDecoration(
                              color: AppTheme.primary600,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      child: Text(
                        notification["message"] ?? "No Message",
                        style: AppTheme.lightTheme.textTheme.bodyMedium
                            ?.copyWith(
                          color: AppTheme.neutral600,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(Icons.access_time,
                            size: 16, color: AppTheme.neutral400),
                        const SizedBox(width: 4),
                        Text(
                          formattedTime,
                          style: AppTheme.lightTheme.textTheme.bodySmall
                              ?.copyWith(
                            color: AppTheme.neutral400,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              AnimatedRotation(
                turns: 0,
                duration: const Duration(milliseconds: 250),
                child: IconButton(
                  icon: Icon(Icons.expand_more,
                      color: AppTheme.neutral400, size: 24),
                  onPressed: () {},
                  splashRadius: 20,
                  tooltip: "Expand",
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
