import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/queue/index.dart';
import '../../services/user_service.dart';
import '../spotlight_page/spotlight_page.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SpotlightQueueWidgetNew extends StatefulWidget {
  final bool shouldInitialize;
  
  const SpotlightQueueWidgetNew({Key? key, this.shouldInitialize = false}) : super(key: key);

  @override
  _SpotlightQueueWidgetNewState createState() => _SpotlightQueueWidgetNewState();
}

class _SpotlightQueueWidgetNewState extends State<SpotlightQueueWidgetNew> with AutomaticKeepAliveClientMixin {
  Timer? _timer;
  bool _isInitialized = false;
  bool _isDisposed = false;
  
  // New modular queue system
  final UnifiedQueueService _unifiedService = UnifiedQueueService();
  late final BaseQueueController _spotlightController;
  
  // Streams for real-time data
  StreamSubscription<TimerState>? _timerSub;
  StreamSubscription<QueueUser?>? _liveUserSub;
  Stream<List<QueueUser>>? _queueUsersStream;

  // For timer-based rotation
  TimerState? _lastTimerState;
  bool _rotationInProgress = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    
    // Initialize the spotlight controller
    _spotlightController = _unifiedService.spotlightQueue;
    
    // Initialize streams
    _queueUsersStream = _spotlightController.getQueueUsers();
    
    if (widget.shouldInitialize) {
      _initializeStreams();
    }
  }

  void _initializeStreams() {
    if (_isDisposed) return;
    
    print('🔄 [DEBUG] Initializing streams for SpotlightQueueWidgetNew');
    
    setState(() {
      _isInitialized = true;
    });

    // Simple timer listener - no complex rotation logic for now
    _timerSub = _spotlightController.getTimerState().listen((timerState) {
      if (!_isDisposed) {
        print('🕐 [DEBUG] Timer: ${timerState.remainingSeconds}s');
        setState(() {
          // Update UI based on timer state
        });
      }
    });

    // Simple live user listener
    _liveUserSub = _spotlightController.getCurrentLiveUser().listen((liveUser) {
      if (!_isDisposed) {
        print('👤 [DEBUG] Live user: ${liveUser?.displayName}');
        setState(() {
          // Update UI based on live user
        });
      }
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    _timer?.cancel();
    _timerSub?.cancel();
    _liveUserSub?.cancel();
    super.dispose();
  }

  Future<void> _joinQueue() async {
    try {
      print('🔄 [DEBUG] Joining queue...');
      await _spotlightController.joinQueue();
      print('✅ [DEBUG] Successfully joined queue');
      
      // Check if we should automatically go live (first in queue, no one live)
      print('🔄 [DEBUG] Checking queue state for auto go live...');
      final queueUsers = await _spotlightController.getQueueUsers().first;
      final currentUserId = _spotlightController.currentUserId;
      
      print('🔄 [DEBUG] Queue users count: ${queueUsers.length}');
      print('🔄 [DEBUG] Current user ID: $currentUserId');
      
      // Debug: Print all queue users
      for (int i = 0; i < queueUsers.length; i++) {
        final user = queueUsers[i];
        print('🔄 [DEBUG] Queue user $i: ${user.displayName} (${user.id}) - isLive: ${user.isLive}');
      }
      
      // Find current user's position in queue
      final currentUserIndex = queueUsers.indexWhere((user) => user.id == currentUserId);
      final isFirstInQueue = currentUserIndex == 0;
      final hasLiveUser = queueUsers.any((user) => user.isLive);
      
      print('🔄 [DEBUG] Current user index: $currentUserIndex');
      print('🔄 [DEBUG] Is first in queue: $isFirstInQueue');
      print('🔄 [DEBUG] Has live user: $hasLiveUser');
      
      // If first in queue and no one is live, automatically go live
      if (isFirstInQueue && !hasLiveUser) {
        print('🔄 [DEBUG] Auto go live conditions met, going live...');
        await _goLive();
      } else {
        print('🔄 [DEBUG] Auto go live conditions not met, showing join message');
        print('🔄 [DEBUG] - isFirstInQueue: $isFirstInQueue');
        print('🔄 [DEBUG] - !hasLiveUser: ${!hasLiveUser}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Successfully joined spotlight queue!')),
        );
      }
    } catch (e) {
      print('❌ [DEBUG] Error in _joinQueue: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error joining queue: $e')),
      );
    }
  }

  Future<void> _leaveQueue() async {
    try {
      await _spotlightController.leaveQueue();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Successfully left spotlight queue!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error leaving queue: $e')),
      );
    }
  }

  Future<void> _goLive() async {
    try {
      print('🔄 [DEBUG] Going live...');
      // Get current user's data
      final userService = UserService();
      final userData = await userService.getCurrentUserData();
      print('🔄 [DEBUG] User data: $userData');
      
      if (userData != null) {
        final uid = FirebaseAuth.instance.currentUser?.uid;
        final displayName = userData['name'] ?? userData['displayName'] ?? 'Unknown';
        print('🔄 [DEBUG] UID: $uid, Display Name: $displayName');
        
        if (uid != null) {
          print('✅ [DEBUG] Setting user as live: $displayName (UID: $uid)');
          await _spotlightController.setUserAsLive(uid, displayName);
          print('✅ [DEBUG] Successfully set user as live');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You are now live!')),
          );
        } else {
          print('❌ [DEBUG] No current user UID');
          throw Exception('User UID not found');
        }
      } else {
        print('❌ [DEBUG] No user data found');
        throw Exception('User data not found');
      }
    } catch (e) {
      print('❌ [DEBUG] Error going live: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error going live: $e')),
      );
    }
  }

  Widget _buildCurrentStreamerCard() {
    const Color orangeColor = Color(0xFFFFB74D);

    return StreamBuilder<QueueUser?>(
      stream: _spotlightController.getCurrentLiveUser(),
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
                CircleAvatar(
                  backgroundImage: currentLiveUser.photoURL != null
                      ? NetworkImage(currentLiveUser.photoURL!)
                      : null,
                  child: currentLiveUser.photoURL == null
                      ? const Icon(Icons.person)
                      : null,
                ),
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
                              "Live Now: ${currentLiveUser.displayName}",
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
                    StreamBuilder<TimerState>(
                      stream: _spotlightController.getTimerState(),
                      builder: (context, timerSnapshot) {
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
                        
                        final timerState = timerSnapshot.data!;
                        final countdown = timerState.remainingSeconds;
                        final isActive = timerState.isActive;
                        
                        return Column(
                          children: [
                            Text(
                              "${countdown}s",
                              style: TextStyle(
                                color: isActive ? orangeColor : Colors.grey,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (isActive)
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

  Widget _buildUserRow(QueueUser user) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.grey.shade200,
            backgroundImage: user.photoURL != null
                ? NetworkImage(user.photoURL!)
                : null,
            child: user.photoURL == null
                ? const Icon(Icons.person, color: Colors.grey)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Joined ${_formatTimestamp(user.timestamp)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          if (user.isLive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'LIVE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    const Color orangeColor = Color(0xFFFFB74D);

    return Column(
      children: [
        _buildCurrentStreamerCard(),
        StreamBuilder<List<QueueUser>>(
          stream: _spotlightController.getQueueUsers(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _joinQueue,
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
                    onPressed: _joinQueue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: orangeColor,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text("Join Spotlight Queue"),
                  ),
                ),
              );
            }

            final queueUsers = snapshot.data!;
            bool isUserInQueue = queueUsers.any((user) => 
                user.id == _spotlightController.currentUserId);

            // Show Join/Leave Queue button and manual rotation test
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isUserInQueue ? _leaveQueue : _joinQueue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isUserInQueue ? Colors.grey.shade400 : orangeColor,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(
                        isUserInQueue ? "Leave Spotlight Queue" : "Join Spotlight Queue",
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Manual rotation test button (temporary for debugging)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        print('🔄 [DEBUG] Manual rotation test triggered');
                        try {
                          await _unifiedService.moveToNextSpotlightUser();
                          print('✅ [DEBUG] Manual rotation completed successfully');
                        } catch (e) {
                          print('❌ [DEBUG] Manual rotation failed: $e');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text("Manual Rotation Test"),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Manual go live test button (temporary for debugging)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        print('🔄 [DEBUG] Manual go live test triggered');
                        try {
                          await _goLive();
                          print('✅ [DEBUG] Manual go live completed successfully');
                        } catch (e) {
                          print('❌ [DEBUG] Manual go live failed: $e');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text("Manual Go Live Test"),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Clear test data button (temporary for debugging)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        print('🔄 [DEBUG] Clearing test data...');
                        try {
                          await _spotlightController.endLiveSession();
                          print('✅ [DEBUG] Test data cleared successfully');
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Test data cleared!')),
                          );
                        } catch (e) {
                          print('❌ [DEBUG] Error clearing test data: $e');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error clearing data: $e')),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text("Clear Test Data"),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 10),
        const Divider(),
        Expanded(
          child: StreamBuilder<List<QueueUser>>(
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