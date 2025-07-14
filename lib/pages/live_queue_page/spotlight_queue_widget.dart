import 'dart:async';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/queue_service.dart';
import '../spotlight_page/spotlight_page.dart';

class SpotlightQueueWidget extends StatefulWidget {
  final bool shouldInitialize;
  
  const SpotlightQueueWidget({Key? key, this.shouldInitialize = false}) : super(key: key);

  @override
  _SpotlightQueueWidgetState createState() => _SpotlightQueueWidgetState();
}

class _SpotlightQueueWidgetState extends State<SpotlightQueueWidget> with AutomaticKeepAliveClientMixin {
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

  // Spotlight Queue: Global/main stage of the app
  // As app grows, access will require coins, XP, or currency to join
  // Designed to feel exclusive - like an audition or VIP opportunity
  // Firestore service for spotlight_queue collection
  final QueueService _queueService = QueueService();
  
  // Streams for real-time data
  StreamSubscription<Map<String, dynamic>?>? _timerSub;
  StreamSubscription<Map<String, dynamic>?>? _liveUserSub;
  Stream<List<Map<String, dynamic>>>? _queueUsersStream;

  @override
  void initState() {
    super.initState();
    _photoPageController = PageController();
    _queueUsersStream = _queueService.getQueueUsers(); // <-- Fix: initialize the queue users stream
    // Do not attach streams here
  }

  void _attachStreams() {
    _timerSub?.cancel();
    _liveUserSub?.cancel();
    
    _timerSub = _queueService.getSpotlightTimer().listen((timerData) {
      if (timerData != null) {
        final isActive = timerData['isActive'] ?? false;
        final countdown = timerData['countdown'] ?? 20;
        
        print('Spotlight Timer stream update - Countdown: $countdown, IsActive: $isActive');
        
        // Ensure persistent timer is running if there's a live user and timer is active
        if (isActive) {
          _queueService.ensurePersistentSpotlightTimerRunning();
        }
        
        setState(() {});
      }
    });
    
    _liveUserSub = _queueService.getCurrentLiveUser().listen((liveUser) {
      if (liveUser != null) {
        print('Spotlight Live user changed to: ${liveUser['name']}');
        // Ensure persistent timer is running for the new live user
        _queueService.ensurePersistentSpotlightTimerRunning();
      } else {
        print('No spotlight live user');
      }
      setState(() {});
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _attachStreams();
    // Always re-fetch the timer stream to ensure up-to-date timer after switching tabs
    _queueUsersStream = _queueService.getQueueUsers();
  }

  @override
  bool get wantKeepAlive => true;

  void _initializeTimer() async {
    print('Initializing timer for spotlight queue');
    
    // Check if there's already a live user before initializing
    final liveUser = await _queueService.getCurrentLiveUser().first;
    final hasLiveUser = liveUser != null;
    
    if (hasLiveUser) {
      print('Live user exists, checking timer state');
      // Check timer state and start countdown if needed
      final timerData = await _queueService.getSpotlightTimer().first;
      if (timerData != null) {
        final isActive = timerData['isActive'] ?? false;
        if (isActive) {
          print('Live user exists and timer is active, starting countdown');
          // The countdown timer is now managed by the QueueService
        } else {
          // If there's a live user but timer is not active, activate it
          print('Live user exists but timer not active, activating timer');
          await _queueService.updateSpotlightTimer(timerData['countdown'] ?? 20, true);
        }
      }
      // Clean up any users with empty names in the queue
      await _cleanupEmptyNamesInQueue();
      return;
    }
    
    // Initialize the timer in Firestore if it doesn't exist
    await _queueService.initializeSpotlightTimer();
    
    // Clean up any users with empty names in the queue
    await _cleanupEmptyNamesInQueue();
    
    // Check if timer exists
    final timerData = await _queueService.getSpotlightTimer().first;
    if (timerData != null) {
      print('Timer initialized - Countdown: ${timerData['countdown']}, IsActive: ${timerData['isActive']}');
    } else {
      print('No timer found, will be created when user joins');
    }
  }

  Future<void> _cleanupEmptyNamesInQueue() async {
    try {
      final queueUsers = await _queueService.getQueueUsers().first;
      for (var user in queueUsers) {
        final name = user['name'] as String?;
        final userId = user['userId'] as String?;
        
        if (name == null || name.isEmpty || userId == null) {
          // Remove users with empty names or missing userId by deleting the document directly
          await FirebaseFirestore.instance.collection('spotlight_queue').doc(userId).delete();
          print('Cleaned up user with empty name: $userId');
        }
      }
    } catch (e) {
      print('Error cleaning up empty names: $e');
    }
  }

  void _listenToTimerChanges() {
    _timerSub?.cancel(); // Cancel any existing subscription
    _timerSub = _queueService.getSpotlightTimer().listen((timerData) {
      if (timerData != null) {
        final isActive = timerData['isActive'] ?? false;
        final countdown = timerData['countdown'] ?? 20;
        
        print('Timer stream update - Countdown: $countdown, IsActive: $isActive');
        
        // Check if there's a live user to determine if timer should be active
        _queueService.getCurrentLiveUser().first.then((liveUser) {
          final hasLiveUser = liveUser != null;
          // If there's a live user, we should have an active timer
          // If timer is not active but there's a live user, activate it
          if (hasLiveUser && !isActive) {
            print('Live user exists but timer not active, activating timer');
            _queueService.updateSpotlightTimer(countdown, true);
            return;
          }
          
          final shouldBeActive = hasLiveUser && isActive;
          
          if (shouldBeActive) {
            // Start countdown timer if not already running
            // The countdown timer is now managed by the QueueService
          } else {
            // Stop countdown timer if timer is not active
            print('Stopping countdown timer from stream listener');
            // The countdown timer is now managed by the QueueService
          }
        });
      } else {
        print('Timer stream update - No data');
        // Stop countdown timer if no timer data
        // The countdown timer is now managed by the QueueService
      }
    });
  }

  void _listenToLiveUserChanges() {
    _liveUserSub?.cancel(); // Cancel any existing subscription
    _liveUserSub = _queueService.getCurrentLiveUser().listen((liveUser) {
      if (liveUser != null) {
        print('Live user changed to: ${liveUser['name']}');
        // Timer will be activated automatically by setUserAsLive
        // Wait a moment for the timer to be activated, then start countdown
        Future.delayed(const Duration(milliseconds: 500), () {
          if (!_isDisposed) {
            // The countdown timer is now managed by the QueueService
          }
        });
      } else {
        print('No live user');
        // Stop countdown timer when no live user
        // The countdown timer is now managed by the QueueService
      }
    });
  }

  void _startCountdownTimer() {
    if (_isDisposed) return;
    
    // The countdown timer is now managed by the QueueService
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
                _buildSocialButton(FontAwesomeIcons.instagram, Colors.purple, "Instagram", user),
                _buildSocialButton(FontAwesomeIcons.tiktok, Colors.black, "TikTok", user),
                _buildSocialButton(FontAwesomeIcons.twitch, Colors.purple, "Twitch", user),
              ],
            ),
          ),
          const SizedBox(height: 24),
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
    // Handle cases where name might be null or empty
    final userName = user["name"] as String?;
    final displayName = (userName != null && userName.isNotEmpty) ? userName : "Unknown User";
    
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
                displayName, 
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
      stream: _queueService.getCurrentLiveUser(),
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
                builder: (context) => const SpotlightPage(),
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
                      stream: _queueService.getSpotlightTimer(),
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
                          stream: _queueService.getCurrentLiveUser(),
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
    _timerSub?.cancel();
    _liveUserSub?.cancel();
    // Reset instance flag so timer can be reinitialized if user switches back
    _isInitialized = false;
    super.dispose();
  }
  
  // Instance method to reset initialization for spotlight queue (useful for testing)
  void resetSpotlightInitialization() {
    _isInitialized = false;
  }

  // Method to initialize timer when tab is selected
  void initializeTimerWhenSelected() {
    if (!_isInitialized) {
      _initializeTimer();
      _isInitialized = true;
    }
  }



  // Method to refresh streams (called from LiveQueuePage)
  @override
  void didUpdateWidget(SpotlightQueueWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Initialize timer if shouldInitialize changed to true
    if (widget.shouldInitialize && !oldWidget.shouldInitialize && !_isInitialized) {
      _initializeTimer();
      _isInitialized = true;
    }
    // Refresh streams when tab becomes visible
    if (widget.shouldInitialize && !oldWidget.shouldInitialize) {
      _attachStreams();
      // Always re-fetch the timer stream to ensure up-to-date timer after switching tabs
      _queueUsersStream = _queueService.getQueueUsers();
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color orangeColor = Color(0xFFFFB74D);

    return Column(
      children: [
        _buildCurrentStreamerCard(),
        StreamBuilder<Map<String, dynamic>?>(
          stream: _queueService.getCurrentUserQueueStatus(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => QueueService().joinQueue(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: orangeColor,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text("Join Spotlight Queue"),
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
                    onPressed: () => QueueService().joinQueue(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: orangeColor,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text("Join Spotlight Queue"),
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
                    onPressed: () => QueueService().joinQueue(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: orangeColor,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text("Join Spotlight Queue"),
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
                          title: const Text("Leave Spotlight Queue?"),
                          content: const Text("If you leave the spotlight queue, you'll lose your exclusive spot."),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text("Cancel"),
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                Navigator.of(context).pop();
                                await QueueService().leaveQueue();
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
                  child: const Text("Leave Spotlight Queue"),
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
              if (_queueUsersStream == null) {
                return const Center(child: Text('Queue not initialized'));
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error:  [${snapshot.error}'));
              }

              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final queueUsers = snapshot.data!;

              if (queueUsers.isEmpty) {
                return const Center(
                  child: Text(
                    'No users in spotlight queue',
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
    );
  }
} 