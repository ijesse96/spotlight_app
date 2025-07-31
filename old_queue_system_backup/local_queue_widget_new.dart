import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/queue/index.dart';
import './local_spotlight_page.dart';

class LocalQueueWidgetNew extends StatefulWidget {
  final String locationId;
  final String locationName;
  final bool shouldInitialize;
  
  const LocalQueueWidgetNew({
    Key? key, 
    required this.locationId,
    required this.locationName,
    this.shouldInitialize = false,
  }) : super(key: key);

  @override
  _LocalQueueWidgetNewState createState() => _LocalQueueWidgetNewState();
}

class _LocalQueueWidgetNewState extends State<LocalQueueWidgetNew> with AutomaticKeepAliveClientMixin {
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

  // New modular queue system
  final UnifiedQueueService _unifiedService = UnifiedQueueService();
  late final BaseQueueController _localController;
  
  // Streams for real-time data
  StreamSubscription<TimerState>? _timerSub;
  StreamSubscription<QueueUser?>? _liveUserSub;
  Stream<List<QueueUser>>? _queueUsersStream;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _photoPageController = PageController();
    
    // Initialize the local controller
    _localController = _unifiedService.getLocalQueue(widget.locationId);
    
    // Initialize streams
    _queueUsersStream = _localController.getQueueUsers();
    
    if (widget.shouldInitialize) {
      _initializeStreams();
    }
  }

  void _initializeStreams() {
    if (_isDisposed) return;
    
    setState(() {
      _isInitialized = true;
    });

    // Listen to timer state
    _timerSub = _localController.getTimerState().listen((timerState) {
      if (!_isDisposed) {
        setState(() {
          // Update UI based on timer state
        });
      }
    });

    // Listen to current live user
    _liveUserSub = _localController.getCurrentLiveUser().listen((liveUser) {
      if (!_isDisposed) {
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
    _photoPageController?.dispose();
    _timerSub?.cancel();
    _liveUserSub?.cancel();
    super.dispose();
  }

  Future<void> _joinQueue() async {
    try {
      await _localController.joinQueue();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Successfully joined local queue in ${widget.locationName}!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error joining queue: $e')),
      );
    }
  }

  Future<void> _leaveQueue() async {
    try {
      await _localController.leaveQueue();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Successfully left local queue in ${widget.locationName}!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error leaving queue: $e')),
      );
    }
  }

  Widget _buildCurrentStreamerCard() {
    return StreamBuilder<QueueUser?>(
      stream: _localController.getCurrentLiveUser(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildNoLiveUserCard();
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return _buildNoLiveUserCard();
        }

        final liveUser = snapshot.data!;
        return _buildLiveUserCard(liveUser);
      },
    );
  }

  Widget _buildNoLiveUserCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.home,
            size: 48,
            color: Colors.grey,
          ),
          const SizedBox(height: 8),
          Text(
            'No one is currently live in local area: ${widget.locationName}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Be the first to go live in your local area!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLiveUserCard(QueueUser liveUser) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF5722), Color(0xFFE64A19)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.deepOrange.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.white,
                backgroundImage: liveUser.photoURL != null
                    ? NetworkImage(liveUser.photoURL!)
                    : null,
                child: liveUser.photoURL == null
                    ? const Icon(Icons.person, color: Colors.deepOrange)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      liveUser.displayName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '🎥 LIVE NOW in Local Area: ${widget.locationName}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LocalSpotlightPage(
                        locationId: widget.locationId,
                        liveUserName: liveUser.displayName,
                        viewerCount: 1200, // This could be dynamic
                      ),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.play_circle_fill,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          StreamBuilder<TimerState>(
            stream: _localController.getTimerState(),
            builder: (context, timerSnapshot) {
              if (timerSnapshot.hasData) {
                final timerState = timerSnapshot.data!;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.timer,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${timerState.remainingSeconds}s remaining',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
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
    const Color deepOrangeColor = Color(0xFFFF5722);

    return Column(
      children: [
        _buildCurrentStreamerCard(),
        StreamBuilder<List<QueueUser>>(
          stream: _localController.getQueueUsers(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _joinQueue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: deepOrangeColor,
                      foregroundColor: Colors.white,
                    ),
                    child: Text("Join Local Queue in ${widget.locationName}"),
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
                      backgroundColor: deepOrangeColor,
                      foregroundColor: Colors.white,
                    ),
                    child: Text("Join Local Queue in ${widget.locationName}"),
                  ),
                ),
              );
            }

            final queueUsers = snapshot.data!;
            bool isUserInQueue = queueUsers.any((user) => 
                user.id == _localController.currentUserId);

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isUserInQueue ? _leaveQueue : _joinQueue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isUserInQueue ? Colors.grey.shade400 : deepOrangeColor,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    isUserInQueue 
                        ? "Leave Local Queue in ${widget.locationName}" 
                        : "Join Local Queue in ${widget.locationName}",
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
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
                return Center(
                  child: Text(
                    'No users in local queue in ${widget.locationName}',
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
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