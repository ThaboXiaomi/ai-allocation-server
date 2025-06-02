import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/custom_icon_widget.dart';

class DashboardCardWidget extends StatelessWidget {
  final String title;
  final String icon;
  final String collectionName;
  final VoidCallback onTap;
  final Widget? child;

  const DashboardCardWidget({
    Key? key,
    required this.title,
    required this.icon,
    required this.collectionName,
    required this.onTap,
    this.child,
  }) : super(key: key);

  Future<int> fetchCount() async {
    final snapshot =
        await FirebaseFirestore.instance.collection(collectionName).get();
    return snapshot.docs.length;
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.primary100, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary100.withOpacity(0.25),
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Decorative accent bar
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 6,
                decoration: BoxDecoration(
                  color: AppTheme.primary600,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Icon with a subtle shadow
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary100.withOpacity(0.3),
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: CustomIconWidget(
                          iconName: icon,
                          color: AppTheme.primary700,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          title,
                          style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                            color: AppTheme.primary700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      CustomIconWidget(
                        iconName: 'arrow_forward',
                        color: AppTheme.neutral500,
                        size: 22,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  FutureBuilder<int>(
                    future: fetchCount(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Row(
                          children: [
                            SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Loading...',
                              style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                                color: AppTheme.neutral400,
                              ),
                            ),
                          ],
                        );
                      } else if (snapshot.hasError) {
                        return Text(
                          'Error: ${snapshot.error}',
                          style: TextStyle(color: Colors.redAccent),
                        );
                      } else {
                        return AnimatedOpacity(
                          opacity: 1.0,
                          duration: Duration(milliseconds: 500),
                          child: Text(
                            'Total: ${snapshot.data}',
                            style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primary600,
                              fontSize: 20,
                            ),
                          ),
                        );
                      }
                    },
                  ),
                  if (child != null) ...[
                    const SizedBox(height: 20),
                    child!,
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CourseManagementCard extends StatelessWidget {
  final List<String> _faculties = ['Faculty 1', 'Faculty 2', 'Faculty 3'];

  @override
  Widget build(BuildContext context) {
    return DashboardCardWidget(
      title: 'Course Management',
      icon: 'school',
      collectionName: 'courses',
      onTap: () {
        Navigator.pushNamed(context, '/course-management');
      },
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Faculties',
                style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                'Students',
                style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          ...List.generate(
            _faculties.length,
            (index) => FacultyItemWidget(
              faculty: _faculties[index],
            ),
          ),
          SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const CustomIconWidget(
                iconName: 'edit',
                color: AppTheme.primary600,
                size: 20,
              ),
              label: const Text('Manage Courses'),
              onPressed: () {
                Navigator.pushNamed(context, '/course-management');
              },
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FacultyItemWidget extends StatelessWidget {
  final String faculty;

  const FacultyItemWidget({Key? key, required this.faculty}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(faculty),
      leading: const Icon(Icons.person),
    );
  }
}
