import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/custom_icon_widget.dart';

class CourseListItemWidget extends StatelessWidget {
  final Map<String, dynamic> course;
  final bool isSelectionMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const CourseListItemWidget({
    Key? key,
    required this.course,
    required this.isSelectionMode,
    required this.onTap,
    required this.onLongPress,
  }) : super(key: key);

  Future<void> _updateCourseSelection(String courseId, bool isSelected) async {
    try {
      await FirebaseFirestore.instance
          .collection('courses')
          .doc(courseId)
          .update({'selected': isSelected});
    } catch (e) {
      print('Error updating course selection: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        if (isSelectionMode) {
          final isSelected = !(course["selected"] ?? false);
          _updateCourseSelection(course["id"], isSelected);
        }
        onTap();
      },
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        child: Row(
          children: [
            if (isSelectionMode)
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: course["selected"] == true
                        ? AppTheme.primary600
                        : Colors.transparent,
                    border: Border.all(
                      color: course["selected"] == true
                          ? AppTheme.primary600
                          : AppTheme.neutral400,
                      width: 2,
                    ),
                  ),
                  child: course["selected"] == true
                      ? const Center(
                          child: CustomIconWidget(
                            iconName: 'check',
                            color: Colors.white,
                            size: 16,
                          ),
                        )
                      : null,
                ),
              ),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course["code"],
                    style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    course["name"],
                    style: AppTheme.lightTheme.textTheme.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const CustomIconWidget(
                        iconName: 'people',
                        color: AppTheme.neutral600,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        course["students"].toString(),
                        style: AppTheme.lightTheme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const CustomIconWidget(
                        iconName: 'person',
                        color: AppTheme.neutral600,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "${course["lecturers"].length}",
                        style: AppTheme.lightTheme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (!isSelectionMode)
              const CustomIconWidget(
                iconName: 'chevron_right',
                color: AppTheme.neutral400,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}
