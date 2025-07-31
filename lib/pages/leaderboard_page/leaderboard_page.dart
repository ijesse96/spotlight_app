import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class LeaderboardPage extends StatelessWidget {
  const LeaderboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3, // Daily / Monthly / Annual
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFFFFB74D),
          title: const Text(
            'Leaderboards',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
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

class LeaderboardTab extends StatefulWidget {
  final String timeRange;

  const LeaderboardTab({super.key, required this.timeRange});

  @override
  State<LeaderboardTab> createState() => _LeaderboardTabState();
}

class _LeaderboardTabState extends State<LeaderboardTab> {
  PageController? _photoPageController;
  
  // Empty list for photos - users will add their own
  final List<String> mockImages = [];

  @override
  void initState() {
    super.initState();
    _photoPageController = PageController();
  }

  @override
  void dispose() {
    _photoPageController?.dispose();
    super.dispose();
  }

  void _showMiniProfile(Map<String, dynamic> user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return _buildMiniProfileSheet(user);
      },
    );
  }

  Widget _buildMiniProfileSheet(Map<String, dynamic> user) {
    const Color orangeColor = Color(0xFFFFB74D);
    
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          
          // Photo carousel
          Container(
            height: 200,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: mockImages.isEmpty
                ? Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.photo_library,
                            size: 48,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'No photos yet',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : PageView.builder(
                    controller: _photoPageController,
                    itemCount: mockImages.length,
                    physics: const BouncingScrollPhysics(),
                    padEnds: false,
                    itemBuilder: (context, index) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            mockImages[index],
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 16),
          
          // Page indicator - only show if there are photos
          if (mockImages.isNotEmpty)
            SmoothPageIndicator(
              controller: _photoPageController!,
              count: mockImages.length,
              effect: const WormEffect(
                dotHeight: 8,
                dotWidth: 8,
                spacing: 8,
                dotColor: Colors.grey,
                activeDotColor: Color(0xFFFFB74D),
              ),
            ),
          const SizedBox(height: 20),
          
          // Profile content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                // Avatar and name
                CircleAvatar(
                  radius: 40,
                  backgroundColor: orangeColor.withOpacity(0.1),
                  child: Icon(
                    Icons.person,
                    size: 40,
                    color: orangeColor,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  user['name'],
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Rank indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: orangeColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "Rank #${user['rank']}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Social media links
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildSocialButton(FontAwesomeIcons.instagram, Colors.purple, "Instagram", user),
                      const SizedBox(width: 20),
                      _buildSocialButton(FontAwesomeIcons.tiktok, Colors.black, "TikTok", user),
                      const SizedBox(width: 20),
                      _buildSocialButton(FontAwesomeIcons.twitch, Colors.purple, "Twitch", user),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Action button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      // TODO: Implement message functionality
                    },
                    icon: const Icon(Icons.message),
                    label: const Text("Message"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: orangeColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialButton(IconData icon, Color color, String platform, Map<String, dynamic> user) {
    return GestureDetector(
      onTap: () {
        // TODO: Implement social media link functionality
        print('Opening $platform profile for ${user["name"]}');
      },
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: FaIcon(
            icon,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }

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
              _buildLeaderboardList('${widget.timeRange} - Earners'),
              _buildLeaderboardList('${widget.timeRange} - Supporters'),
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
        'rank': 1,
      },
      {
        'name': 'GamerGuy',
        'coins': 400,
        'avatarUrl': 'https://i.pravatar.cc/150?img=12',
        'rank': 2,
      },
      {
        'name': 'ASMRlover',
        'coins': 650,
        'avatarUrl': 'https://i.pravatar.cc/150?img=5',
        'rank': 3,
      },
      {
        'name': 'CookingMom',
        'coins': 300,
        'avatarUrl': 'https://i.pravatar.cc/150?img=48',
        'rank': 4,
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
              GestureDetector(
                onTap: () => _showMiniProfile(user),
                child: CircleAvatar(
                  backgroundImage: NetworkImage(user['avatarUrl']),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => _showMiniProfile(user),
                  child: Text(
                    user['name'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const FaIcon(FontAwesomeIcons.coins, color: Color(0xFFFFB74D), size: 16),
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
