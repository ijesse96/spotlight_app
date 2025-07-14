import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/location_service.dart';
import 'services/queue_service.dart';
import 'pages/spotlight_page/spotlight_page.dart';
import 'pages/wallet_page/wallet_page.dart';
import 'pages/live_queue_page/live_queue_page.dart';
import 'pages/leaderboard_page/leaderboard_page.dart';
import 'package:spotlight_app/pages/profile_page/profile_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await FirebaseAuth.instance.signInAnonymously();
  
  // Initialize location service and request permissions
  final locationService = LocationService();
  await locationService.requestLocationPermission();
  
  // Initialize persistent timers
  final queueService = QueueService();
  await queueService.initializePersistentTimers();
  
  // Start persistent timers for any existing live sessions
  await queueService.startPersistentTimersForExistingSessions();
  
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
      home: const MainNavigation(),
    );
  }
}

class MainNavigation extends StatefulWidget {
  final int initialTabIndex;
  
  const MainNavigation({super.key, this.initialTabIndex = 2});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  late int _currentIndex;

  final List<Widget> _pages = [
    const ProfilePage(),
    const LiveQueuePage(),
    const SpotlightPage(),
    const LeaderboardPage(),
    const WalletPage(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTabIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Color(0xFFFFB74D),
        unselectedItemColor: Colors.grey,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_box_outlined), // ✅ Updated icon
            label: 'Queue',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.highlight),
            label: 'Spotlight',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.leaderboard),
            label: 'Leaderboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Wallet',
          ),
        ],
      ),
    );
  }
}
