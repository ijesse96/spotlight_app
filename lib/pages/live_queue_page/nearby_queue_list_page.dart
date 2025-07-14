import 'dart:async';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/queue_service.dart';
import './nearby_stream_page.dart';

class NearbyQueueListPage extends StatefulWidget {
  final String locationId;
  final String locationName;
  final double distance;

  const NearbyQueueListPage({
    Key? key,
    required this.locationId,
    required this.locationName,
    required this.distance,
  }) : super(key: key);

  @override
  _NearbyQueueListPageState createState() => _NearbyQueueListPageState();
}

class _NearbyQueueListPageState extends State<NearbyQueueListPage> with WidgetsBindingObserver {
  Timer? _timer;
  PageController? _photoPageController;
  bool _isInitialized = false;
  bool _isDisposed = false;
  
  // Mock images for the photo carousel
  final List<String> mockImages = [
    'assets/dummy1.png',
    'assets/dummy2.png',
    'assets/dummy3.png',
  ];

  // Nearby Queue: Location-based nearby queue
  final QueueService _queueService = QueueService();
  
  // Streams for real-time data
  Stream<Map<String, dynamic>?>? _liveUserStream;
  Stream<List<Map<String, dynamic>>>? _queueUsersStream;
  Stream<Map<String, dynamic>?>? _timerStream;

  StreamSubscription<Map<String, dynamic>?>? _timerSub;
  StreamSubscription<Map<String, dynamic>?>? _liveUserSub;

  @override
  void initState() {
    super.initState();
    _photoPageController = PageController();
    WidgetsBinding.instance.addObserver(this);
    
    // Initialize Firestore streams for nearby queue
    _liveUserStream = _queueService.getNearbyLiveUser(widget.locationId);
    _queueUsersStream = _queueService.getNearbyQueueUsers(widget.locationId);
    _timerStream = _queueService.getNearbyTimer(widget.locationId);
    
    // Initialize timer if not already initialized
    if (!_isInitialized) {
      _initializeTimer();
      _isInitialized = true;
    }
    
    // Listen to timer changes and start countdown
    _listenToTimerChanges();
    
    // Listen to live user changes to start timer when user becomes live
    _listenToLiveUserChanges();
  }

  void _attachStreams() {
    _timerSub?.cancel();
    _liveUserSub?.cancel();
    
    _timerSub = _queueService.getNearbyTimer(widget.locationId).listen((timerData) {
      if (timerData != null) {
        final isActive = timerData['isActive'] ?? false;
        final countdown = timerData['countdown'] ?? 20;
        
        print('Nearby Timer stream update - Countdown: $countdown, IsActive: $isActive');
        
        // Ensure persistent timer is running if there's a live user and timer is active
        if (isActive) {
          _queueService.ensureNearbyTimerRunning(widget.locationId);
        }
        
        setState(() {});
      }
    });
    
    _liveUserSub = _queueService.getNearbyLiveUser(widget.locationId).listen((liveUser) {
      if (liveUser != null) {
        print('Nearby Live user changed to: ${liveUser['name']}');
        // Ensure persistent timer is running for the new live user
        _queueService.ensureNearbyTimerRunning(widget.locationId);
      } else {
        print('No nearby live user');
      }
      setState(() {});
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _attachStreams();
    // Always re-fetch the timer/user streams to ensure up-to-date timer after switching pages
    _liveUserStream = _queueService.getNearbyLiveUser(widget.locationId);
    _queueUsersStream = _queueService.getNearbyQueueUsers(widget.locationId);
    _timerStream = _queueService.getNearbyTimer(widget.locationId);
  }

  void _initializeTimer() async {
    print('Initializing timer for location: ${widget.locationId}');
    
    // Check if there's already a live user before initializing
    final liveUser = await _queueService.getNearbyLiveUser(widget.locationId).first;
    final hasLiveUser = liveUser != null;
    
    if (hasLiveUser) {
      print('Live user exists, checking timer state');
      // The persistent timer in QueueService handles timer activation
      // Clean up any users with empty names in the queue
      await _cleanupEmptyNamesInQueue();
      return;
    }
    
    // Initialize the timer in Firestore if it doesn't exist
    await _queueService.initializeNearbyTimer(widget.locationId);
    
    // Clean up any users with empty names in the queue
    await _cleanupEmptyNamesInQueue();
    
    // Check if timer exists
    final timerData = await _queueService.getNearbyTimer(widget.locationId).first;
    if (timerData != null) {
      print('Timer initialized - Countdown: ${timerData['countdown']}, IsActive: ${timerData['isActive']}');
    } else {
      print('No timer found, will be created when user joins');
    }
  }

  Future<void> _cleanupEmptyNamesInQueue() async {
    try {
      final queueUsers = await _queueService.getNearbyQueueUsers(widget.locationId).first;
      for (var user in queueUsers) {
        final name = user['name'] as String?;
        final userId = user['userId'] as String?;
        
        if (name == null || name.isEmpty || userId == null) {
          // Remove users with empty names or missing userId by deleting the document directly
          await FirebaseFirestore.instance.collection('nearby_queue_${widget.locationId}').doc(userId).delete();
          print('Cleaned up user with empty name: $userId');
        }
      }
    } catch (e) {
      print('Error cleaning up empty names: $e');
    }
  }

  void _listenToTimerChanges() {
    _timerStream?.listen((timerData) {
      if (timerData != null) {
        final isActive = timerData['isActive'] ?? false;
        final countdown = timerData['countdown'] ?? 20;
        
        print('Timer stream update - Countdown: $countdown, IsActive: $isActive');
        
        // The persistent timer in QueueService handles timer management
      } else {
        print('Timer stream update - No data');
      }
    });
  }

  void _listenToLiveUserChanges() {
    _liveUserStream?.listen((liveUser) {
      if (liveUser != null) {
        print('Live user changed to: ${liveUser['name']}');
        // The persistent timer in QueueService handles timer activation
      } else {
        print('No live user');
      }
    });
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
          
          // Avatar and name (moved above carousel)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: orangeColor.withOpacity(0.1),
                  child: Icon(
                    Icons.person,
                    size: 50,
                    color: orangeColor,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  (user["name"] as String?) ?? "Unknown User",
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          
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
          
          // Action buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                // Message button
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Implement direct messaging system
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Direct messaging coming soon!'),
                          backgroundColor: Color(0xFFFFB74D),
                        ),
                      );
                    },
                    icon: const Icon(Icons.message, color: Colors.white),
                    label: const Text(
                      'Message',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: orangeColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          
          // Social media links
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSocialButton(
                  icon: FontAwesomeIcons.instagram,
                  color: Colors.purple,
                  onTap: () => _launchUrl('https://instagram.com'),
                ),
                _buildSocialButton(
                  icon: FontAwesomeIcons.tiktok,
                  color: Colors.black,
                  onTap: () => _launchUrl('https://tiktok.com'),
                ),
                _buildSocialButton(
                  icon: FontAwesomeIcons.youtube,
                  color: Colors.red,
                  onTap: () => _launchUrl('https://youtube.com'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  Widget _buildUserRow(Map<String, dynamic> user) {
    const Color orangeColor = Color(0xFFFFB74D);
    
    // Handle cases where name might be null or empty
    final userName = user["name"] as String?;
    final displayName = (userName != null && userName.isNotEmpty) ? userName : "Unknown User";
    
    return GestureDetector(
      onTap: () => _showMiniProfile(user),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: orangeColor.withOpacity(0.1),
              child: Icon(Icons.person, color: orangeColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    displayName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Position: ${user['position'] ?? 'Unknown'}",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: orangeColor,
              size: 16,
            ),
          ],
        ),
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
                builder: (context) => NearbyStreamPage(
                  locationId: widget.locationId,
                  locationName: widget.locationName,
                  distance: widget.distance,
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
                              "Live Now: ${(currentLiveUser['name'] as String?) ?? 'Unknown User'}",
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
                        // Show loading state instead of fallback 20s
                        if (!timerSnapshot.hasData) {
                          return Column(
                            children: [
                              SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(orangeColor),
                                ),
                              ),
                            ],
                          );
                        }
                        
                        final data = timerSnapshot.data!;
                        final countdown = data['countdown'] ?? 20;
                        final isActive = data['isActive'] ?? false;
                        
                        // Check if there's a live user to determine if timer should be active
                        return StreamBuilder<Map<String, dynamic>?>(
                          stream: _liveUserStream,
                          builder: (context, liveUserSnapshot) {
                            final hasLiveUser = liveUserSnapshot.hasData && liveUserSnapshot.data != null;
                            // If there's a live user, show timer as active (orange) regardless of isActive flag
                            // Also show as active if timer is active (to prevent flickering during stream loading)
                            // If live user stream is still loading, assume active if timer is active
                            final shouldShowActive = hasLiveUser || isActive || (liveUserSnapshot.connectionState == ConnectionState.waiting && isActive);
                            
                            return Column(
                              children: [
                                Text(
                                  "${countdown}s",
                                  style: TextStyle(
                                    color: shouldShowActive ? orangeColor : Colors.grey,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (shouldShowActive)
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            );
                          },
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
    _isDisposed = true;
    _photoPageController?.dispose();
    WidgetsBinding.instance.removeObserver(this);
    _timerSub?.cancel();
    _liveUserSub?.cancel();
    // Reset instance flag so timer can be reinitialized if user switches back
    _isInitialized = false;
    super.dispose();
  }
  
  // Instance method to reset initialization for nearby queue (useful for testing)
  void resetLocationInitialization() {
    _isInitialized = false;
  }

  @override
  Widget build(BuildContext context) {
    const Color orangeColor = Color(0xFFFFB74D);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: orangeColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Nearby Queue',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildCurrentStreamerCard(),
          StreamBuilder<Map<String, dynamic>?>(
            stream: _queueService.getCurrentUserNearbyQueueStatus(widget.locationId),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _queueService.joinNearbyQueue(widget.locationId),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: orangeColor,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text("Join Nearby Queue"),
                    ),
                  ),
                );
              }

              if (!snapshot.hasData) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _queueService.joinNearbyQueue(widget.locationId),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: orangeColor,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text("Join Nearby Queue"),
                    ),
                  ),
                );
              }

              final userStatus = snapshot.data;
              
              // If userStatus is null, user is not in queue
              if (userStatus == null) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _queueService.joinNearbyQueue(widget.locationId),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: orangeColor,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text("Join Nearby Queue"),
                    ),
                  ),
                );
              }

              // User is in queue, show Leave Queue button
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Show confirmation dialog for leaving queue
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text("Leave Nearby Queue?"),
                            content: const Text("If you leave the nearby queue, you'll lose your spot."),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text("Cancel"),
                              ),
                              ElevatedButton(
                                onPressed: () async {
                                  Navigator.of(context).pop();
                                  await _queueService.leaveNearbyQueue(widget.locationId);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: orangeColor,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text("Yes, Leave"),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[400],
                      foregroundColor: Colors.white,
                    ),
                    child: const Text("Leave Nearby Queue"),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          const Divider(),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _queueUsersStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final queueUsers = snapshot.data!;

                if (queueUsers.isEmpty) {
                  return const Center(
                    child: Text(
                      'No users in nearby queue',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: queueUsers.length,
                  itemBuilder: (context, index) {
                    final user = queueUsers[index];
                    return _buildUserRow(user);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
} 