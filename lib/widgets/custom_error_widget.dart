import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

import '../theme/app_theme.dart';

// custom_error_widget.dart

class CustomErrorWidget extends StatelessWidget {
  final FlutterErrorDetails? errorDetails;
  final String? errorMessage;

  const CustomErrorWidget({
    Key? key,
    this.errorDetails,
    this.errorMessage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Log the error to Firebase Crashlytics
    if (errorDetails != null) {
      FirebaseCrashlytics.instance.recordFlutterError(errorDetails!);
    } else if (errorMessage != null) {
      FirebaseCrashlytics.instance.log(errorMessage!);
    }

    // Track the error event in Firebase Analytics
    FirebaseAnalytics.instance.logEvent(
      name: 'custom_error_widget_displayed',
      parameters: {
        'error_message': errorMessage ?? 'Unknown error',
        'has_error_details': errorDetails != null,
      },
    );

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  'assets/images/sad_face.svg',
                  height: 42,
                  width: 42,
                ),
                const SizedBox(height: 8),
                Text(
                  "Something went wrong",
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF262626),
                  ),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  child: Text(
                    errorMessage ?? 
                        'We encountered an unexpected error while processing your request.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF525252), // neutral-600
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    // Handle button press
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.arrow_back,
                      size: 18, color: Colors.white),
                  label: const Text('Back'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.lightTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
