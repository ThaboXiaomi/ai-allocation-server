import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/custom_icon_widget.dart';

class FacultyItemWidget extends StatelessWidget {
  final Map<String, dynamic> faculty;

  const FacultyItemWidget({
    Key? key,
    required this.faculty,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.lightTheme;
    final initials = (faculty["name"] as String?)?.isNotEmpty == true
        ? faculty["name"].substring(0, 2).toUpperCase()
        : "?";
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      color: AppTheme.neutral50,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
        child: Row(
          children: [
            // Circular avatar with initials
            CircleAvatar(
              radius: 28,
              backgroundColor: faculty["color"] ?? AppTheme.neutral200,
              child: Text(
                initials,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(width: 18),
            // Faculty details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    faculty["fullName"] ?? "",
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                      color: AppTheme.neutral900,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    faculty["name"] ?? "",
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.neutral500,
                      fontWeight: FontWeight.w400,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            // Student count pill button
            GestureDetector(
              onTap: () async {
                final docRef = FirebaseFirestore.instance
                    .collection('faculties')
                    .doc(faculty['id']);
                await docRef.update({
                  'studentCount': (faculty['studentCount'] ?? 0) + 1
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppTheme.neutral200),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.neutral200.withOpacity(0.18),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CustomIconWidget(
                      iconName: 'person',
                      color: AppTheme.neutral600,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      faculty["studentCount"].toString(),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.neutral800,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FacultyListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Faculty List')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('faculties').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No faculties found.'));
          }
          final faculties = snapshot.data!.docs;
          return ListView.builder(
            itemCount: faculties.length,
            itemBuilder: (context, index) {
              final faculty = faculties[index].data() as Map<String, dynamic>;
              return FacultyItemWidget(faculty: faculty);
            },
          );
        },
      ),
    );
  }
}
