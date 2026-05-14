import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  // await Firebase.initializeApp();
  
  // Initialize Hive for offline caching
  // await Hive.initFlutter();
  // await Hive.openBox('bookings');
  // await Hive.openBox('user_preferences');
  
  runApp(
    ProviderScope(
      child: AIAllocationApp(),
    ),
  );
}

class AIAllocationApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Room Allocation',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: SplashScreen(),
    );
  }
}
