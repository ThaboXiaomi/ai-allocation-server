import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VenueManagementScreen extends StatelessWidget {
  const VenueManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Venue Management")),
      body: const RoomStatusWidget(),
    );
  }
}

class RoomStatusWidget extends StatelessWidget {
  const RoomStatusWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance.collection('lecture_rooms').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Error loading rooms'));
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(child: Text('No rooms found.'));
        }
        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final room = docs[index].data() as Map<String, dynamic>;
            return ListTile(
              title: Text(room['name'] ?? ''),
              subtitle: Text(room['status'] ?? ''),
            );
          },
        );
      },
    );
  }
}
