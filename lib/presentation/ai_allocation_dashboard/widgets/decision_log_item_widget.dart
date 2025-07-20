import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../theme/app_theme.dart'; // Adjust path based on your project structure
import '../../../widgets/custom_icon_widget.dart'; // Adjust path based on your project structure

class DecisionLogItemWidget extends StatelessWidget {
  final Map<String, dynamic> decision;
  final VoidCallback onViewDetails;

  const DecisionLogItemWidget({
    Key? key,
    required this.decision,
    required this.onViewDetails,
  }) : super(key: key);

  /// Fetch decision details from Firestore for the "View Details" action
  Future<Map<String, dynamic>> _fetchDecisionDetails(String decisionId) async {
    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('decisionLogs')
          .doc(decisionId)
          .get();
      return docSnapshot.exists ? docSnapshot.data()! : {};
    } catch (e) {
      print('Error fetching decision details: $e');
      return {};
    }
  }

  @override
  Widget build(BuildContext context) {
    // Safely extract fields with default values to handle nulls
    final String allocationID = decision['allocationID'] ?? 'Unknown ID';
    final String conflictDetails = decision['conflictDetails'] ?? 'No conflict details';
    final String description = decision['description'] ?? 'No description';
    final String resolvedBy = decision['resolvedBy'] ?? 'Unknown';
    final String status = decision['status'] ?? 'Unknown';
    final String suggestedVenue = decision['suggestedVenue'] ?? 'No suggested venue';
    final Timestamp? timestampRaw = decision['timestamp'];
    final String timestamp = timestampRaw != null
        ? timestampRaw.toDate().toString()
        : 'No timestamp';

    // Determine status color based on status
    final Color statusColor = status.toLowerCase() == 'resolved'
        ? AppTheme.success600
        : AppTheme.warning600;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: onViewDetails,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with status icon and basic info
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: CustomIconWidget(
                      iconName: 'info',
                      color: statusColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Allocation: $allocationID',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          timestamp,
                          style: const TextStyle(
                            color: AppTheme.neutral500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Description
              Text(
                description,
                style: const TextStyle(
                  color: AppTheme.neutral700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              // Resolved By
              Text(
                'Resolved By: $resolvedBy',
                style: const TextStyle(
                  color: AppTheme.neutral600,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 12),
              // Conflict Details
              Text(
                'Conflict Details: $conflictDetails',
                style: const TextStyle(
                  color: AppTheme.neutral600,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 12),
              // Suggested Venue
              Text(
                'Suggested Venue: $suggestedVenue',
                style: const TextStyle(
                  color: AppTheme.neutral600,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 12),
              // View Details button
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  icon: const CustomIconWidget(
                    iconName: 'visibility',
                    color: AppTheme.primary600,
                    size: 16,
                  ),
                  label: const Text('View Details'),
                  onPressed: () async {
                    final decisionDetails = await _fetchDecisionDetails(decision['id'] ?? '');
                    print('Decision Details: $decisionDetails');
                    onViewDetails();
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}