import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'faculty_item_widget.dart';

class FacultyListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Faculty Management')),
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
              final doc = faculties[index];
              final faculty = {
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>
              };
              return FacultyItemWidget(faculty: faculty);
            },
          );
        },
      ),
    );
  }
}
