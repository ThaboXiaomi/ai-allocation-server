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

class RoomStatusWidget extends StatefulWidget {
  const RoomStatusWidget({Key? key}) : super(key: key);

  @override
  State<RoomStatusWidget> createState() => _RoomStatusWidgetState();
}

class _RoomStatusWidgetState extends State<RoomStatusWidget> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  String _status = 'Available';

  Future<void> _addRoom() async {
    if (_formKey.currentState?.validate() ?? false) {
      await FirebaseFirestore.instance.collection('lecture_rooms').add({
        'name': _nameController.text.trim(),
        'status': _status,
      });
      _nameController.clear();
      setState(() {
        _status = 'Available';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Room added!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Add Room Form
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Form(
            key: _formKey,
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Room Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.meeting_room), // Room icon
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Enter room name'
                        : null,
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _status,
                  icon: const Icon(Icons.event_available), // Status icon
                  items: const [
                    DropdownMenuItem(
                        value: 'Available', child: Text('Available')),
                    DropdownMenuItem(
                        value: 'Unavailable', child: Text('Unavailable')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _status = val);
                  },
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _addRoom,
                  icon: const Icon(Icons.add), // Add icon
                  label: const Text('Add Room'),
                ),
              ],
            ),
          ),
        ),
        const Divider(),
        // Room List
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('lecture_rooms')
                .snapshots(),
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
          ),
        ),
      ],
    );
  }
}
