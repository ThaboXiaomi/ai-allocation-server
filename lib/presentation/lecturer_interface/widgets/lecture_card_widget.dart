import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/custom_icon_widget.dart';

class LectureCardWidget extends StatelessWidget {
  final Map<String, dynamic> lecture;
  final VoidCallback onCheckIn;
  final VoidCallback? onViewMap;

  const LectureCardWidget({
    Key? key,
    required this.lecture,
    required this.onCheckIn,
    this.onViewMap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(

      stream: FirebaseFirestore.instance
          .collection('lectures')
          .doc(lecture['id'])
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Error loading lecture details.'));
        }
        if (!snapshot.hasData || snapshot.data?.data() == null) {
          return const Center(child: Text('Lecture details not available.'));
        }

        final updatedLecture = snapshot.data!.data()!;
        final bool isActive = updatedLecture["isActive"] ?? false;
        final bool hasVenueChange = updatedLecture["hasVenueChange"] ?? false;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            gradient: isActive
                ? LinearGradient(
                    colors: [AppTheme.primary900, AppTheme.primary600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : LinearGradient(
                    colors: [Colors.white, AppTheme.neutral100],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.07),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
            border: hasVenueChange
                ? Border.all(color: AppTheme.warning600, width: 1.5)
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Row(
                  children: [
                    // Course code badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isActive
                            ? Colors.white.withOpacity(0.18)
                            : _getFacultyColor(updatedLecture["faculty"])
                                .withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        updatedLecture["courseCode"],
                        style: TextStyle(
                          color: isActive
                              ? Colors.white
                              : _getFacultyColor(updatedLecture["faculty"]),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Course title and time
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            updatedLecture["courseTitle"],
                            style: TextStyle(
                              color: isActive
                                  ? Colors.white
                                  : AppTheme.neutral900,
                              fontWeight: FontWeight.w700,
                              fontSize: 17,
                              letterSpacing: 0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Icon(Icons.schedule,
                                  size: 16,
                                  color: isActive
                                      ? Colors.white70
                                      : AppTheme.neutral500),
                              const SizedBox(width: 4),
                              Text(
                                '${updatedLecture["startTime"]} - ${updatedLecture["endTime"]}',
                                style: TextStyle(
                                  color: isActive
                                      ? Colors.white70
                                      : AppTheme.neutral600,
                                  fontSize: 13.5,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (isActive)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Chip(
                          label: const Text('ACTIVE'),
                          labelStyle: TextStyle(
                            color: AppTheme.primary900,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                  ],
                ),
              ),
              // Divider
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Divider(
                  color: isActive
                      ? Colors.white.withOpacity(0.18)
                      : AppTheme.neutral200,
                  thickness: 1,
                  height: 0,
                ),
              ),
              // Venue and students info
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Venue row
                    Row(
                      children: [
                        const CustomIconWidget(
                          iconName: 'location_on',
                          color: AppTheme.neutral600,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Venue:',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppTheme.neutral600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 4),
                        if (hasVenueChange)
                          Row(
                            children: [
                              Text(
                                updatedLecture["originalVenue"],
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  decoration: TextDecoration.lineThrough,
                                  color: AppTheme.error600,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const CustomIconWidget(
                                iconName: 'arrow_forward',
                                color: AppTheme.warning600,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                updatedLecture["currentVenue"],
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.warning600,
                                ),
                              ),
                            ],
                          )
                        else
                          Text(
                            updatedLecture["currentVenue"],
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        if (hasVenueChange)
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Chip(
                              avatar: const CustomIconWidget(
                                iconName: 'info',
                                color: AppTheme.warning600,
                                size: 16,
                              ),
                              label: const Text('Changed'),
                              labelStyle: TextStyle(
                                color: AppTheme.warning600,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                              backgroundColor: AppTheme.warning100,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                    color: AppTheme.warning600.withAlpha(77)),
                              ),
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Students row
                    Row(
                      children: [
                        const CustomIconWidget(
                          iconName: 'people',
                          color: AppTheme.neutral600,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Students:',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppTheme.neutral600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${updatedLecture["registeredCount"]} registered',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (updatedLecture["studentCount"] > 0)
                          Text(
                            ' (${updatedLecture["studentCount"]} checked in)',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppTheme.success600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const CustomIconWidget(
                              iconName: 'login',
                              color: Colors.white,
                              size: 20,
                            ),
                            label: const Text('Check In'),
                            onPressed: onCheckIn,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isActive
                                  ? AppTheme.primary700
                                  : AppTheme.neutral400,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                        if (hasVenueChange && onViewMap != null)
                          Padding(
                            padding: const EdgeInsets.only(left: 10),
                            child: Tooltip(
                              message: 'View venue map',
                              child: Material(
                                color: Colors.transparent,
                                child: Ink(
                                  decoration: ShapeDecoration(
                                    color: AppTheme.warning100,
                                    shape: const CircleBorder(),
                                  ),
                                  child: IconButton(
                                    icon: const CustomIconWidget(
                                      iconName: 'map',
                                      color: AppTheme.warning600,
                                      size: 24,
                                    ),
                                    onPressed: onViewMap,
                                  ),
                                ),
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
      },
    );
  }

  Color _getFacultyColor(String faculty) {
    switch (faculty) {
      case 'SOBE':
        return AppTheme.primary600;
      case 'SET':
        return AppTheme.success600;
      case 'SEM':
        return AppTheme.warning600;
      case 'SOCE':
        return AppTheme.info600;
      default:
        return AppTheme.neutral600;
    }
  }
}
