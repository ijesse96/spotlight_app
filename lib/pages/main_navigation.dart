import 'package:flutter/material.dart';
import 'spotlight_page/spotlight_page.dart';
import 'wallet_page/wallet_page.dart';
import 'live_queue_page/live_queue_page.dart';
import 'leaderboard_page/leaderboard_page.dart';
import 'profile_page/profile_page.dart';

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
            icon: Icon(Icons.add_box_outlined),
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