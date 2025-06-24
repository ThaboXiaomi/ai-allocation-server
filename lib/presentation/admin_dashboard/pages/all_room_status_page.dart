import 'package:flutter/material.dart';

import '../widgets/room_status_widget.dart';

class AllRoomStatusPage extends StatelessWidget {
  final List<Map<String, dynamic>> allRoomData;

  const AllRoomStatusPage({
    Key? key,
    required this.allRoomData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Room Allocation Status'),
      ),
      body: allRoomData.isEmpty
          ? const Center(
              child: Text(
                "No room statuses available.",
                style: TextStyle(fontSize: 16),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: allRoomData.length,
              itemBuilder: (context, index) {
                return RoomStatusWidget(roomData: allRoomData[index]);
              },
            ),
    );
  }
}