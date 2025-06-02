import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/custom_icon_widget.dart';

class FacultySectionWidget extends StatefulWidget {
  final String facultyId; // Use facultyId to fetch data dynamically
  final bool isExpanded;
  final VoidCallback onToggleExpanded;
  final Widget courseListWidget;

  const FacultySectionWidget({
    Key? key,
    required this.facultyId,
    required this.isExpanded,
    required this.onToggleExpanded,
    required this.courseListWidget,
  }) : super(key: key);

  @override
  _FacultySectionWidgetState createState() => _FacultySectionWidgetState();
}

class _FacultySectionWidgetState extends State<FacultySectionWidget> {
  Map<String, dynamic>? facultyData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchFacultyData();
  }

  Future<void> _fetchFacultyData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('faculties')
          .doc(widget.facultyId)
          .get();
      if (doc.exists) {
        setState(() {
          facultyData = doc.data();
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching faculty data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _updateFacultyStat(String field, int value) async {
    try {
      await FirebaseFirestore.instance
          .collection('faculties')
          .doc(widget.facultyId)
          .update({field: value});
    } catch (e) {
      print('Error updating faculty stat: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (facultyData == null) {
      return const Center(child: Text('Faculty data not found.'));
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: (facultyData!["color"] as Color).withAlpha(77),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: widget.onToggleExpanded,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: (facultyData!["color"] as Color).withAlpha(51),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          facultyData!["name"],
                          style: AppTheme.lightTheme.textTheme.titleMedium
                              ?.copyWith(
                            color: facultyData!["color"],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              facultyData!["fullName"],
                              style: AppTheme.lightTheme.textTheme.titleLarge
                                  ?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "${facultyData!["activeCourses"]} active courses",
                              style: AppTheme.lightTheme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      CustomIconWidget(
                        iconName: widget.isExpanded
                            ? 'keyboard_arrow_up'
                            : 'keyboard_arrow_down',
                        color: AppTheme.neutral600,
                        size: 24,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatItem(
                          icon: 'menu_book',
                          value: facultyData!["activeCourses"].toString(),
                          label: "Courses",
                          color: facultyData!["color"],
                        ),
                      ),
                      Expanded(
                        child: _buildStatItem(
                          icon: 'people',
                          value: facultyData!["totalStudents"].toString(),
                          label: "Students",
                          color: facultyData!["color"],
                        ),
                      ),
                      Expanded(
                        child: _buildStatItem(
                          icon: 'schedule',
                          value: facultyData!["lectureHours"].toString(),
                          label: "Hours",
                          color: facultyData!["color"],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (widget.isExpanded)
            Column(
              children: [
                const Divider(),
                widget.courseListWidget,
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        CustomIconWidget(
          iconName: icon,
          color: color,
          size: 24,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: AppTheme.lightTheme.textTheme.bodySmall,
        ),
      ],
    );
  }
}
