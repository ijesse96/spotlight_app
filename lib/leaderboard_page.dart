import 'package:flutter/material.dart';

class LeaderboardPage extends StatelessWidget {
  const LeaderboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3, // Daily / Monthly / Annual
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Leaderboards',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          bottom: const TabBar(
            labelColor: Color(0xFFFFB74D), // 🔶 Light Orange
            unselectedLabelColor: Colors.black54,
            indicatorColor: Color(0xFFFFB74D),
            tabs: [
              Tab(text: 'Daily'),
              Tab(text: 'Monthly'),
              Tab(text: 'Annual'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            LeaderboardTab(timeRange: 'Daily'),
            LeaderboardTab(timeRange: 'Monthly'),
            LeaderboardTab(timeRange: 'Annual'),
          ],
        ),
      ),
    );
  }
}

class LeaderboardTab extends StatelessWidget {
  final String timeRange;

  const LeaderboardTab({super.key, required this.timeRange});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // Earners & Supporters
      child: Column(
        children: [
          const TabBar(
            labelColor: Color(0xFFFFB74D), // 🔶 Light Orange
            unselectedLabelColor: Colors.black45,
            indicatorColor: Color(0xFFFFB74D),
            tabs: [
              Tab(text: 'Top Earners'),
              Tab(text: 'Top Supporters'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildLeaderboardList('$timeRange - Earners'),
                _buildLeaderboardList('$timeRange - Supporters'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardList(String label) {
    final List<Map<String, dynamic>> users = [
      {
        'name': 'StreamQueen',
        'coins': 850,
        'avatarUrl': 'https://i.pravatar.cc/150?img=1',
      },
      {
        'name': 'GamerGuy',
        'coins': 400,
        'avatarUrl': 'https://i.pravatar.cc/150?img=12',
      },
      {
        'name': 'ASMRlover',
        'coins': 650,
        'avatarUrl': 'https://i.pravatar.cc/150?img=5',
      },
      {
        'name': 'CookingMom',
        'coins': 300,
        'avatarUrl': 'https://i.pravatar.cc/150?img=48',
      },
    ];

    return ListView.builder(
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return ListTile(
          leading: Text(
            '${index + 1}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          title: Row(
            children: [
              CircleAvatar(
                backgroundImage: NetworkImage(user['avatarUrl']),
              ),
              const SizedBox(width: 12),
              Text(
                user['name'],
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.monetization_on, color: Colors.amber),
              const SizedBox(width: 4),
              Text(
                user['coins'].toString(),
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        );
      },
    );
  }
}
