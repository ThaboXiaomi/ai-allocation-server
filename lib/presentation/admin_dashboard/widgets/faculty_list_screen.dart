import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'faculty_item_widget.dart';

class FacultyListScreen extends StatelessWidget {
  const FacultyListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Faculty List'),
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              // Optionally trigger a refresh or show a snackbar
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Refreshing faculties...')),
              );
            },
          ),
        ],
      ),
      body: Container(
        color: Colors.grey[100],
        child: StreamBuilder<QuerySnapshot>(
          stream:
              FirebaseFirestore.instance.collection('faculties').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.school_outlined,
                        size: 60, color: Colors.grey[400]),
                    const SizedBox(height: 12),
                    const Text(
                      'No faculties found.',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  ],
                ),
              );
            }
            final faculties = snapshot.data!.docs;
            return ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              itemCount: faculties.length,
              separatorBuilder: (context, index) => const SizedBox(height: 4),
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
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Add Faculty'),
        backgroundColor: Colors.indigo,
        onPressed: () {
          // Show a dialog or navigate to add faculty screen
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Add Faculty'),
              content: const Text('Faculty creation form goes here.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
