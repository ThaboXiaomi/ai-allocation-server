import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 90,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.deepPurple.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getMaterialIcon(icon),
              color: Colors.deepPurple,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getMaterialIcon(String iconName) {
    switch (iconName) {
      case 'calendar_month':
        return Icons.calendar_month;
      case 'email':
        return Icons.email;
      case 'report_problem':
        return Icons.report_problem;
      default:
        return Icons.flash_on;
    }
  }
}
