import 'dart:async';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/queue_service.dart';
import './local_spotlight_page.dart';

class LocalQueueDetailPage extends StatefulWidget {
  final String title;

  const LocalQueueDetailPage({Key? key, required this.title}) : super(key: key);
  
  // Convert title to location ID for Firebase collections
  String get locationId => title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');

  @override
  _LocalQueueDetailPageState createState() => _LocalQueueDetailPageState();
}

class _LocalQueueDetailPageState extends State<LocalQueueDetailPage> {
  // Add missing state fields
  bool hasJoined = false;
  List<Map<String, dynamic>> queueUsers = [];

  PageController? _photoPageController;
  
  // Mock images for the photo carousel
  final List<String> mockImages = [
    'assets/dummy1.png',
    'assets/dummy2.png',
    'assets/dummy3.png',
  ];

  // Local Queue: Location-based, free for anyone within 5-10 mile radius
  // Designed for casual interaction - no XP or currency required
  // Not tied to specific events, though can be used at concerts/amusement parks
  // Firebase service for local queue management
  final QueueService _queueService = QueueService();
  
  // Streams for real-time data
  Stream<Map<String, dynamic>?>? _liveUserStream;
  Stream<List<Map<String, dynamic>>>? _queueUsersStream;
  Stream<Map<String, dynamic>?>? _timerStream;

  @override
  void initState() {
    super.initState();
    _photoPageController = PageController();
    
    // Initialize Firestore streams for local queue
    _liveUserStream = _queueService.getCurrentLocalLiveUser(widget.locationId);
    _queueUsersStream = _queueService.getLocalQueueUsers(widget.locationId);
    _timerStream = _queueService.getLocalTimer(widget.locationId);
    // Listen to user's queue status
    _queueService.getCurrentUserLocalQueueStatus(widget.locationId).listen((userStatus) {
      setState(() {
        hasJoined = userStatus != null;
      });
    });
    // Listen to queue users
    _queueService.getLocalQueueUsers(widget.locationId).listen((users) {
      setState(() {
        queueUsers = users;
      });
    });
    
    // Note: Timer management is handled by local spotlight page, this page only displays the queue
  }



  Future<void> _moveToNextStreamer() async {
    // Local Queue rotation logic: Move next user to local spotlight
    // Casual, location-based interaction for nearby users
    final queueUsers = await _queueService.getLocalQueueUsers(widget.locationId).first;
    
    if (queueUsers.isNotEmpty) {
      // Set the first user as local live
      final nextUser = queueUsers.first;
      await _queueService.setUserAsLocalLive(widget.locationId, nextUser['userId'], nextUser['name']);
    } else {
      // No users in queue, end current local live session
      await _queueService.endLocalLiveSession(widget.locationId);
    }
    
    // Reset timer in Firestore
    await _queueService.resetLocalTimer(widget.locationId);
  }

    void _confirmJoin() {
    // Show confirmation dialog when trying to leave queue
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Leave Local Queue?'),
          content: const Text('Are you sure you want to leave the local queue? You will lose your spot.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _queueService.leaveLocalQueue(widget.locationId);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFB74D),
                foregroundColor: Colors.white,
              ),
              child: const Text('Leave Local Queue'),
            ),
          ],
        );
      },
    );
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
            child: PageView.builder(
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
          
          // Page indicator
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
                  user["name"],
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Status indicator - Local Queue (Free, Location-based)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: orangeColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    "In Local Queue",
                    style: TextStyle(
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
      onTap: () async {
        // Generate example URLs for demonstration
        String url;
        switch (platform) {
          case "Instagram":
            url = "https://instagram.com/${user["name"].toLowerCase().replaceAll(' ', '')}";
            break;
          case "TikTok":
            url = "https://tiktok.com/@${user["name"].toLowerCase().replaceAll(' ', '')}";
            break;
          case "Twitch":
            url = "https://twitch.tv/${user["name"].toLowerCase().replaceAll(' ', '')}";
            break;
          default:
            return;
        }
        
        final Uri uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          // Show error message if URL cannot be launched
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Could not open $platform profile')),
            );
          }
        }
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

  Widget _buildUserRow(Map<String, dynamic> user) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 16.0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _showMiniProfile(user),
            child: const CircleAvatar(child: Icon(Icons.person)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () => _showMiniProfile(user),
              child: Text(
                user["name"], 
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStreamerCard() {
    const Color orangeColor = Color(0xFFFFB74D);

    return StreamBuilder<Map<String, dynamic>?>(
      stream: _liveUserStream,
      builder: (context, snapshot) {
        final currentLiveUser = snapshot.data;

        if (currentLiveUser == null) {
          return Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300, width: 2),
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey.shade100,
            ),
            child: Row(
              children: const [
                CircleAvatar(child: Icon(Icons.live_tv, color: Colors.black)),
                SizedBox(width: 12),
                Expanded(
                  child: Text("Waiting for next streamer...",
                      style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          );
        }

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => LocalSpotlightPage(
                  locationId: widget.locationId,
                  liveUserName: currentLiveUser['name'],
                  viewerCount: 1200,
                ),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: orangeColor, width: 2),
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
            ),
            child: Row(
              children: [
                const CircleAvatar(child: Icon(Icons.person)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.live_tv, color: Colors.red),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Live Now: ${currentLiveUser['name']}",
                              style: const TextStyle(fontSize: 18, color: Colors.black),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    StreamBuilder<Map<String, dynamic>?>(
                      stream: _timerStream,
                      builder: (context, timerSnapshot) {
                        if (!timerSnapshot.hasData) return SizedBox.shrink();
                        final data = timerSnapshot.data!;
                        final int countdown = data['countdown'] ?? 15;
                        final bool isActive = data['isActive'] ?? false;
                        final Timestamp? lastUpdated = data['lastUpdated'];
                        int secondsLeft = countdown;
                        if (lastUpdated != null) {
                          final elapsed = DateTime.now().difference(lastUpdated.toDate()).inSeconds;
                          secondsLeft = countdown - elapsed;
                          if (secondsLeft < 0) secondsLeft = 0;
                        }
                        if (!isActive) return SizedBox.shrink();
                        return Text(
                          '$secondsLeft s',
                          style: TextStyle(
                            color: orangeColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 4),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: orangeColor,
                      size: 16,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _photoPageController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color orangeColor = Color(0xFFFFB74D);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: orangeColor,
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildCurrentStreamerCard(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _confirmJoin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: hasJoined ? Colors.grey.shade400 : orangeColor,
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  hasJoined ? "Leave Local Queue" : "Join Local Queue",
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Divider(),
          Expanded(
            child: ListView.builder(
              itemCount: queueUsers.length,
              itemBuilder: (context, index) {
                final user = queueUsers[index];
                return _buildUserRow(user);
              },
            ),
          ),
        ],
      ),
    );
  }
}
