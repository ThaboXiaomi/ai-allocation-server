import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import './widgets/course_list_item_widget.dart';
import './widgets/faculty_section_widget.dart';

class SearchBarWidget extends StatelessWidget {
  final ValueChanged<String> onSearch;

  const SearchBarWidget({Key? key, required this.onSearch}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Search...',
        prefixIcon: Icon(Icons.search),
      ),
      onChanged: onSearch,
    );
  }
}

class CourseManagement extends StatefulWidget {
  const CourseManagement({Key? key}) : super(key: key);

  @override
  State<CourseManagement> createState() => _CourseManagementState();
}

class _CourseManagementState extends State<CourseManagement> {
  final List<Map<String, dynamic>> _faculties = [
    {
      "id": 1,
      "name": "SOBE",
      "fullName": "School of Business and Economics",
      "color": AppTheme.primary600,
      "activeCourses": 24,
      "totalStudents": 1250,
      "lectureHours": 96,
      "expanded": true,
    },
    {
      "id": 2,
      "name": "SET",
      "fullName": "School of Engineering and Technology",
      "color": AppTheme.success600,
      "activeCourses": 32,
      "totalStudents": 980,
      "lectureHours": 128,
      "expanded": false,
    },
  ];

  final List<Map<String, dynamic>> _courses = [
    {
      "id": 1,
      "facultyId": 1,
      "code": "BUS101",
      "name": "Introduction to Business",
      "students": 120,
      "lecturers": ["Dr. Sarah Johnson", "Prof. Michael Lee"],
      "venueRequirements": "Large lecture hall with projector",
      "scheduleConstraints": "Mornings only",
      "selected": false,
    },
    {
      "id": 2,
      "facultyId": 1,
      "code": "ECO201",
      "name": "Microeconomics",
      "students": 85,
      "lecturers": ["Dr. Robert Chen"],
      "venueRequirements": "Medium lecture room with whiteboard",
      "scheduleConstraints": "No Friday afternoons",
      "selected": false,
    },
  ];

  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Course Management'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SearchBarWidget(
                onSearch: (query) {
                  setState(() {
                    _searchQuery = query;
                  });
                },
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _faculties.length,
                padding: const EdgeInsets.all(16),
                itemBuilder: (context, index) {
                  final faculty = _faculties[index];
                  final facultyCourses = _getFilteredCourses(faculty["id"]);

                  return FacultySectionWidget(
                    facultyId: faculty["id"],
                    isExpanded: faculty["expanded"],
                    onToggleExpanded: () {
                      setState(() {
                        faculty["expanded"] = !faculty["expanded"];
                      });
                    },
                    courseListWidget: faculty["expanded"]
                        ? _buildCourseList(facultyCourses)
                        : const SizedBox.shrink(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getFilteredCourses(int facultyId) {
    return _courses.where((course) {
      if (course["facultyId"] != facultyId) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        return course["name"].toLowerCase().contains(query) ||
            course["code"].toLowerCase().contains(query);
      }
      return true;
    }).toList();
  }

  Widget _buildCourseList(List<Map<String, dynamic>> courses) {
    if (courses.isEmpty) {
      return const Center(
        child: Text("No courses available."),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: courses.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        final course = courses[index];
        return CourseListItemWidget(
          course: course,
          isSelectionMode: false,
          onTap: () {},
          onLongPress: () {},
        );
      },
    );
  }
}
