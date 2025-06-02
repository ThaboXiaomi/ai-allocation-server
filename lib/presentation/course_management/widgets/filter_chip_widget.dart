import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/custom_icon_widget.dart';

class FilterChipWidget extends StatelessWidget {
  final String label;
  final String userId; // User ID to manage filters for a specific user
  final VoidCallback onDelete;

  const FilterChipWidget({
    Key? key,
    required this.label,
    required this.userId,
    required this.onDelete,
  }) : super(key: key);

  Future<void> _deleteFilterFromFirestore(String filterLabel) async {
    try {
      final filtersCollection = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('filters');

      final querySnapshot = await filtersCollection
          .where('label', isEqualTo: filterLabel)
          .get();

      for (var doc in querySnapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      print('Error deleting filter from Firestore: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.primary100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: AppTheme.primary700,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: () async {
              await _deleteFilterFromFirestore(label);
              onDelete();
            },
            borderRadius: BorderRadius.circular(12),
            child: const Padding(
              padding: EdgeInsets.all(2.0),
              child: CustomIconWidget(
                iconName: 'close',
                color: AppTheme.primary700,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
