import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';


class AppTheme {
  static const Color neutral800 = Color(0xFF333333);
  static const Color primary600 = Color(0xFF007BFF);
  static const Color warning600 = Color(0xFFFFA500);
  static const Color neutral200 = Color(0xFFCCCCCC);

  static final TextTheme lightTheme = TextTheme(
    bodySmall: TextStyle(fontSize: 12, color: Colors.black),
  );
}

class AllocationChartWidget extends StatelessWidget {
  static const Color neutral800 =
      Color(0xFF333333); // Replace with your desired color

  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final Color tooltipBgColor; // Define the parameter

  AllocationChartWidget({
    Key? key,
    this.tooltipBgColor = Colors.white, // Provide a default value if needed
  }) : super(key: key);


  @override
  Widget build(BuildContext context) {
    return Container(
      color: tooltipBgColor, // Use the parameter
      child: Text('Allocation Chart'),
    );
  }
}