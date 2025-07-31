import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/location_service.dart';
import 'pages/auth/auth_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('🚀 [MAIN] Initializing Firebase...');
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('🚀 [MAIN] Firebase initialized successfully');
    print('🚀 [MAIN] Firebase app name: ${Firebase.app().name}');
    print('🚀 [MAIN] Firebase project ID: ${Firebase.app().options.projectId}');
  } catch (e) {
    print('🚀 [MAIN] Firebase initialization failed: $e');
    // Continue with app even if Firebase fails
  }
  
  // Initialize services with error handling
  try {
    // Initialize location service and request permissions
    final locationService = LocationService();
    await locationService.requestLocationPermission();
  } catch (e) {
    print('🚀 [MAIN] Service initialization failed: $e');
    // Continue with app even if services fail
  }
  
  runApp(const SpotlightApp());
}

class SpotlightApp extends StatelessWidget {
  const SpotlightApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Spotlight App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.orange,
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
      routes: {
        '/main': (context) => const AuthWrapper(),
      },
    );
  }
}
