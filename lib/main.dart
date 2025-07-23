import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For orientation control
import 'package:sizer/sizer.dart'; // Responsive design

// Local imports
import './core/utils/navigator_service.dart';
import './core/utils/pref_utils.dart';
import './routes/app_routes.dart';
import './theme/app_theme.dart';
import 'firebase_options.dart'; // Required for DefaultFirebaseOptions

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Firebase initialization
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // Log the detailed error to the console
    print("CRITICAL: Firebase initialization failed: $e");
    print(
        "Please ensure you have run 'flutterfire configure' and that your Firebase project setup is correct.");
    print(
        "Check for missing or misconfigured google-services.json (Android) or GoogleService-Info.plist (iOS) if not using DefaultFirebaseOptions.");

    // Display an error screen to the user
    runApp(FirebaseErrorScreen(error: e.toString()));
    return; // Stop further execution if Firebase init fails
  }

  // Shared preferences initialization
  await PrefUtils().init();

  runApp(const MyApp());
}

// Error screen for Firebase initialization failure
class FirebaseErrorScreen extends StatelessWidget {
  final String error;
  const FirebaseErrorScreen({Key? key, required this.error}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "Application Error:\nFailed to initialize critical services.\nPlease contact support or try again later.\n\nDetails: $error",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red, fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (context, orientation, deviceType) {
        return MaterialApp(
          title: 'Lecture Room Allocator',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.light,
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: const TextScaler.linear(1.0),
              ),
              child: child!,
            );
          },
          navigatorKey: NavigatorService.navigatorKey,
          //debugShowCheckedModeBanner: false,
          routes: AppRoutes.routes,
          onGenerateRoute: AppRoutes.onGenerateRoute,
          onUnknownRoute: (settings) {
            return MaterialPageRoute(
              builder: (context) => Scaffold(
                body: Center(
                  child: Text('404: Route "${settings.name}" not found'),
                ),
              ),
            );
          },
          home: AppRoutes.getInitialScreen(),
        );
      },
    );
  }
}