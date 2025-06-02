import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/custom_icon_widget.dart';

class QuickActionButtonWidget extends StatelessWidget {
  final String icon;
  final String label;
  final VoidCallback onTap;

  const QuickActionButtonWidget({
    Key? key,
    required this.icon,
    required this.label,
    required this.onTap,
  }) : super(key: key);

  Future<void> _triggerCloudFunction(BuildContext context) async {
    try {
      // Example: Trigger a Firebase Cloud Function
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("User not logged in");
      }

      // Simulate a Cloud Function call (replace with actual implementation)
      await FirebaseFirestore.instance
          .collection('actions')
          .doc(user.uid)
          .set({"action": label, "timestamp": FieldValue.serverTimestamp()});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Action '$label' triggered successfully!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error triggering action: $e")),
      );
    }
  }

  Future<void> _navigateToFirestoreData(BuildContext context) async {
    try {
      // Example: Navigate to a screen that fetches Firestore data
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("User not logged in");
      }

      final doc = await FirebaseFirestore.instance
          .collection('user_data')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Fetched data: ${doc.data()}")),
        );
      } else {
        throw Exception("No data found for user");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching data: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        // Example: Trigger Firebase functionality based on the label
        if (label == "Trigger Action") {
          await _triggerCloudFunction(context);
        } else if (label == "View Data") {
          await _navigateToFirestoreData(context);
        } else {
          onTap();
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 90,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: AppTheme.primary50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.primary200),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary300.withAlpha(77),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: CustomIconWidget(
                iconName: icon,
                color: AppTheme.primary600,
                size: 20,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
