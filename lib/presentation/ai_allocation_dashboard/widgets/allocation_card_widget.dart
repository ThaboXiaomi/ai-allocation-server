import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/custom_icon_widget.dart';

class AllocationCardWidget extends StatelessWidget {
  final Map<String, dynamic> allocation;
  final String documentId; // Firestore document ID
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  AllocationCardWidget({
    Key? key,
    required this.allocation,
    required this.documentId,
  }) : super(key: key);

  Future<void> _updateStatus(String newStatus) async {
    try {
      await firestore.collection('allocations').doc(documentId).update({
        'status': newStatus,
      });
      // Optionally, show a success message
    } catch (e) {
      print('Error updating status: $e');
    }
  }

  // Fetch room name from lecture_rooms collection
  Future<String> _getRoomName(String roomId) async {
    try {
      DocumentSnapshot roomDoc = await firestore.collection('lecture_rooms').doc(roomId).get();
      if (roomDoc.exists) {
        return roomDoc.get('roomName') ?? 'Unknown Room';
      }
      return 'Unknown Room';
    } catch (e) {
      print('Error fetching room name: $e');
      return 'Unknown Room';
    }
  }

  @override
  Widget build(BuildContext context) {
    final allocation = this.allocation;
    final status = allocation['status'] ?? '';
    final isPending = status == 'Pending';
    final isInProgress = status == 'In Progress';
    final isDiverted = status == 'diverted';
    final venue = allocation['resolvedVenue'] ?? allocation['room'];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: _getStatusColor(status).withAlpha(77),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withAlpha(26),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: _getStatusColor(status).withAlpha(77),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CustomIconWidget(
                        iconName: _getStatusIcon(status),
                        color: _getStatusColor(status),
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        status,
                        style: TextStyle(
                          color: _getStatusColor(status),
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.neutral100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    allocation['faculty'],
                    style: const TextStyle(
                      color: AppTheme.neutral700,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  allocation['time'],
                  style: const TextStyle(
                    color: AppTheme.neutral600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              allocation['course'],
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Lecturer: ${allocation['lecturer']}',
              style: const TextStyle(
                color: AppTheme.neutral700,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            // Tabular form for rooms
            FutureBuilder<String>(
              future: _getRoomName(allocation['room']),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Text('Error loading room name');
                }
                final originalRoomName = snapshot.data ?? 'Unknown Room';
                final resolvedRoomName = allocation['resolvedVenue'] ?? 'N/A';

                return DataTable(
                  columns: const [
                    DataColumn(label: Text('Originally Allocated Room')),
                    DataColumn(label: Text('Resolved Conflict Room')),
                  ],
                  rows: [
                    DataRow(cells: [
                      DataCell(
                        Row(
                          children: [
                            CustomIconWidget(
                              iconName: 'meeting_room',
                              color: AppTheme.neutral600,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              originalRoomName,
                              style: const TextStyle(color: AppTheme.neutral600),
                            ),
                          ],
                        ),
                      ),
                      DataCell(
                        Row(
                          children: [
                            CustomIconWidget(
                              iconName: 'meeting_room',
                              color: AppTheme.primary600,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              resolvedRoomName,
                              style: const TextStyle(color: AppTheme.primary600),
                            ),
                          ],
                        ),
                      ),
                    ]),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildInfoColumn(
                    'Students',
                    allocation['studentCount'].toString(),
                    'people',
                    AppTheme.info600,
                  ),
                ),
                Expanded(
                  child: _buildInfoColumn(
                    'Capacity',
                    allocation['venueCapacity'].toString(),
                    'event_seat',
                    AppTheme.warning600,
                  ),
                ),
                Expanded(
                  child: _buildInfoColumn(
                    'Distance',
                    '${allocation['distanceFactor']} min',
                    'directions_walk',
                    AppTheme.neutral600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const CustomIconWidget(
                  iconName: 'info',
                  color: AppTheme.neutral500,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Reason: ${allocation['reason']}',
                    style: const TextStyle(
                      color: AppTheme.neutral600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            if (isPending || isInProgress) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const CustomIconWidget(
                        iconName: 'edit',
                        color: AppTheme.primary600,
                        size: 18,
                      ),
                      label: const Text('Edit'),
                      onPressed: () {
                        _updateStatus('In Progress');
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const CustomIconWidget(
                        iconName: 'check',
                        color: Colors.white,
                        size: 18,
                      ),
                      label: const Text('Approve'),
                      onPressed: () {
                        _updateStatus('Completed');
                      },
                    ),
                  ),
                ],
              ),
            ],
            if (!isPending && !isInProgress) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  const CustomIconWidget(
                    iconName: 'auto_awesome',
                    color: AppTheme.success600,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'AI Confidence: ${(allocation['confidenceScore'] * 100).toInt()}%',
                    style: const TextStyle(
                      color: AppTheme.success600,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoColumn(
      String label, String value, String iconName, Color iconColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.neutral500,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            CustomIconWidget(
              iconName: iconName,
              color: iconColor,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Completed':
        return AppTheme.success600;
      case 'In Progress':
        return AppTheme.primary600;
      case 'Pending':
        return AppTheme.warning600;
      default:
        return AppTheme.neutral600;
    }
  }

  String _getStatusIcon(String status) {
    switch (status) {
      case 'Completed':
        return 'check_circle';
      case 'In Progress':
        return 'sync';
      case 'Pending':
        return 'pending';
      default:
        return 'info';
    }
  }
}