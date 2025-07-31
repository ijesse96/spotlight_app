import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:spotlight_app/pages/profile_page/profile_page.dart';
import '../live_queue_page/live_queue_page.dart';
import '../../main.dart';
import '../../services/super_simple_queue.dart';
import '../../services/agora_service.dart';
import '../../services/debug_user_service.dart';
import 'widgets/gift_card.dart';
import 'widgets/chat_box_widget.dart';
import 'widgets/gift_panel_widget.dart';
import 'widgets/viewer_coin_overlay.dart';
import 'widgets/countdown_timer_widget.dart';
import 'widgets/streamer_header_widget.dart';
import 'widgets/stream_stats_overlay.dart';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';

class SpotlightPage extends StatefulWidget {
  const SpotlightPage({super.key});

  @override
  State<SpotlightPage> createState() => _SpotlightPageState();
}

class _SpotlightPageState extends State<SpotlightPage> {
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _chatMessages = [];
  final Map<String, int> _giftCounts = {};
  final Map<String, String?> _userAvatars = {}; // Cache for user avatars
  int _coinTotal = 0;
  int _userCoinBalance = 1250;
  bool _shouldAutoScroll = true;

  Timer? _giftComboTimer;
  String? _comboGiftName;
  int _comboGiftCount = 0;

  // Main Spotlight queue rotation variables - using new SuperSimpleQueue
  Duration _countdown = const Duration(seconds: 20);
  String _currentLiveUserName = "Waiting...";
  final SuperSimpleQueue _queueService = SuperSimpleQueue();
  StreamSubscription<SuperSimpleUser?>? _liveUserSubscription;
  StreamSubscription<int>? _timerSubscription;
  bool _isDisposed = false;

  // Agora video service
  final AgoraService _agoraService = AgoraService();
  bool _isStreamer = false;
  bool _isStreamStarted = false;
  String? _currentUserId;

  // Real-time chat system
  StreamSubscription<QuerySnapshot>? _chatSubscription;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _currentUserName;
  String? _currentUserDisplayName;
  String? _currentLiveUserId; // Added to store current live user's ID

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      final atBottom = _scrollController.offset >= _scrollController.position.maxScrollExtent - 10;
      setState(() {
        _shouldAutoScroll = atBottom;
      });
    });
    _initializeMainSpotlightStream();
    _getCurrentUserId();
    _initializeRealTimeChat();
  }

  void _initializeMainSpotlightStream() async {
    _listenToLiveUser();
    _listenToSpotlightTimer();
  }

  Future<void> _getCurrentUserId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _currentUserId = user.uid;
      });
      
      // Get user display name for chat
      await _getUserDisplayName(user.uid);
    }
  }

  Future<void> _getUserDisplayName(String uid) async {
    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        setState(() {
          _currentUserName = userData['username'] ?? 'User$uid';
          // Prioritize display name (name field) over username for chat
          _currentUserDisplayName = userData['name'] ?? userData['username'] ?? 'User$uid';
        });
      } else {
        setState(() {
          _currentUserName = 'User$uid';
          _currentUserDisplayName = 'User$uid';
        });
      }
    } catch (e) {
      print("❌ Error getting user display name: $e");
      setState(() {
        _currentUserName = 'User$uid';
        _currentUserDisplayName = 'User$uid';
      });
    }
  }

  Future<String?> _getUserAvatar(String userId) async {
    // Return cached avatar if available
    if (_userAvatars.containsKey(userId)) {
      return _userAvatars[userId];
    }

    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final avatarUrl = userData['avatarUrl'];
        
        // Cache the avatar (even if null)
        _userAvatars[userId] = avatarUrl;
        
        return avatarUrl;
      }
    } catch (e) {
      print("❌ Error getting user avatar: $e");
    }
    
    // Cache null to avoid repeated failed requests
    _userAvatars[userId] = null;
    return null;
  }

  void _initializeRealTimeChat() {
    // Listen to real-time chat messages
    _chatSubscription = _firestore
        .collection('spotlight_chat')
        .orderBy('timestamp', descending: false)
        .limit(50) // Limit to last 50 messages for performance
        .snapshots()
        .listen((snapshot) {
      if (_isDisposed) return;

      // Clear existing messages and add new ones
      setState(() {
        _chatMessages.clear();
        for (var doc in snapshot.docs) {
          final data = doc.data();
          _chatMessages.add({
            'id': doc.id,
            'userId': data['userId'] ?? '', // Add userId field
            'displayName': data['displayName'] ?? data['username'] ?? 'Unknown', // Support both old and new field names
            'message': data['message'] ?? '',
            'isGift': data['isGift'] ?? false,
            'timestamp': data['timestamp'],
          });
        }
      });

      // Auto-scroll to bottom for new messages
      if (_shouldAutoScroll) {
        _scrollToBottom();
    }
    });
  }

  void _listenToLiveUser() {
    _liveUserSubscription = _queueService.liveUserStream.listen((liveUser) async {
      if (liveUser != null) {
        setState(() {
          _currentLiveUserName = liveUser.name;
          _currentLiveUserId = liveUser.id; // Update the new variable
        });
        
        // Check if current user is the streamer
        final isCurrentUserStreamer = liveUser.id == _currentUserId;
        
        if (isCurrentUserStreamer && !_isStreamStarted) {
          // It's my turn to stream!
          await _startMyStream();
        } else if (!isCurrentUserStreamer && _isStreamStarted) {
          // I'm no longer the streamer, stop my stream
          await _stopMyStream();
        }
        
        setState(() {
          _isStreamer = isCurrentUserStreamer;
        });
      } else {
        setState(() {
          _currentLiveUserName = "Waiting...";
          _isStreamer = false;
          _currentLiveUserId = null; // Clear the live user ID
        });
        
        if (_isStreamStarted) {
          await _stopMyStream();
        }
      }
    });
  }

  Future<void> _startMyStream() async {
    print("🎥 Starting my stream...");
    
    try {
      // 1. Ask for camera + mic permissions
      final cameraStatus = await Permission.camera.request();
      final microphoneStatus = await Permission.microphone.request();
      
      if (cameraStatus.isDenied || microphoneStatus.isDenied) {
        print("❌ Camera or microphone permission denied");
        return;
      }
      
      // 2. Set up video view change callback
      _agoraService.setVideoViewChangedCallback(() {
        if (mounted) {
          setState(() {});
        }
      });
      
      // 3. Initialize and join Agora channel
      await _agoraService.initialize();
      await _agoraService.joinChannel('spotlight');
      
      setState(() {
        _isStreamStarted = true;
      });
      
      print("✅ Stream started successfully!");
      
    } catch (e) {
      print("❌ Error starting stream: $e");
    }
  }

  Future<void> _stopMyStream() async {
    print("🛑 Stopping my stream...");
    
    try {
      await _agoraService.leaveChannel();
      
      setState(() {
        _isStreamStarted = false;
      });
      
      print("✅ Stream stopped successfully!");
      
    } catch (e) {
      print("❌ Error stopping stream: $e");
    }
  }

  void _listenToSpotlightTimer() {
    _timerSubscription = _queueService.timerStream.listen((seconds) {
        setState(() {
        _countdown = Duration(seconds: seconds);
        });
    });
  }

  void _listenToSpotlightChat() {
    // This method is no longer needed as chat messages are managed via Firestore
  }

  void _listenToSpotlightGiftTotal() {
    // This method is no longer needed as gift total is managed locally
  }

  Future<void> _addTestChatMessages() async {
    // This method is no longer needed as we use real-time Firestore messages
  }

  Future<void> _sendChatMessage(String message, {bool isGift = false}) async {
    if (message.trim().isEmpty || _currentUserId == null) return;

    try {
      // Add message to Firestore
      await _firestore.collection('spotlight_chat').add({
        'userId': _currentUserId,
        'displayName': _currentUserDisplayName ?? _currentUserName ?? 'User',
        'message': message.trim(),
        'isGift': isGift,
        'timestamp': FieldValue.serverTimestamp(),
    });

      // Clear the input field
      _chatController.clear();
      
      // Force auto-scroll to show the user's sent message
      setState(() {
        _shouldAutoScroll = true;
      });
      
      // Scroll to bottom immediately to show the sent message
      _scrollToBottom();
      
      print("✅ Chat message sent successfully!");
      
    } catch (e) {
      print("❌ Error sending chat message: $e");
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients && _shouldAutoScroll) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  void _sendGiftWithModalState(String giftName, int coinAmount, void Function(void Function()) setModalState) {
    // Check if user has enough coins
    if (_userCoinBalance < coinAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Not enough coins! You need $coinAmount coins to send this gift.'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() {
      _coinTotal += coinAmount;
      _userCoinBalance -= coinAmount;
      _giftCounts[giftName] = (_giftCounts[giftName] ?? 0) + 1;
    });
    setModalState(() {});

    if (_comboGiftName == giftName) {
      _comboGiftCount++;
    } else {
      _comboGiftName = giftName;
      _comboGiftCount = 1;
    }

    _giftComboTimer?.cancel();
    _giftComboTimer = Timer(const Duration(seconds: 1), () {
      final comboMessage = _comboGiftCount > 1
          ? "$_comboGiftName x$_comboGiftCount"
          : "$_comboGiftName";

      // Send gift message to Firestore
      _sendChatMessage(comboMessage, isGift: true);

      _comboGiftName = null;
      _comboGiftCount = 0;
    });
  }

  void _openGiftMenu() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.45,
              maxChildSize: 0.9,
              builder: (_, controller) => Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        const Center(
                          child: Text('Send a Gift', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                        Positioned(
                          right: 0,
                          child: Row(
                            children: [
                              const Icon(FontAwesomeIcons.coins, size: 16, color: Color(0xFFFFB74D)),
                              const SizedBox(width: 4),
                              Text(
                                '$_userCoinBalance',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: GridView.count(
                        controller: controller,
                        crossAxisCount: 4,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 0.7,
                        children: [
                          GiftCard(
                            icon: Icons.local_florist, 
                            label: 'Rose', 
                            coinValue: 50, 
                            userCoinBalance: _userCoinBalance,
                            onTap: () => _sendGiftWithModalState('🌹', 50, setModalState)
                          ),
                          GiftCard(
                            icon: Icons.whatshot, 
                            label: 'Fire', 
                            coinValue: 100, 
                            userCoinBalance: _userCoinBalance,
                            onTap: () => _sendGiftWithModalState('🔥', 100, setModalState)
                          ),
                          GiftCard(
                            icon: Icons.star, 
                            label: 'Star', 
                            coinValue: 200, 
                            userCoinBalance: _userCoinBalance,
                            onTap: () => _sendGiftWithModalState('⭐', 200, setModalState)
                          ),
                          GiftCard(
                            icon: Icons.emoji_events, 
                            label: 'Crown', 
                            coinValue: 250, 
                            userCoinBalance: _userCoinBalance,
                            onTap: () => _sendGiftWithModalState('👑', 250, setModalState)
                          ),
                          GiftCard(
                            icon: Icons.flash_on, 
                            label: 'Zap', 
                            coinValue: 300, 
                            userCoinBalance: _userCoinBalance,
                            onTap: () => _sendGiftWithModalState('⚡', 300, setModalState)
                          ),
                          GiftCard(
                            icon: Icons.favorite, 
                            label: 'Heart', 
                            coinValue: 400, 
                            userCoinBalance: _userCoinBalance,
                            onTap: () => _sendGiftWithModalState('❤️', 400, setModalState)
                          ),
                          GiftCard(
                            icon: Icons.rocket, 
                            label: 'Rocket', 
                            coinValue: 500, 
                            userCoinBalance: _userCoinBalance,
                            onTap: () => _sendGiftWithModalState('🚀', 500, setModalState)
                          ),
                          GiftCard(
                            icon: Icons.ac_unit, 
                            label: 'Ice', 
                            coinValue: 600, 
                            userCoinBalance: _userCoinBalance,
                            onTap: () => _sendGiftWithModalState('❄️', 600, setModalState)
                          ),
                          GiftCard(
                            icon: Icons.diamond, 
                            label: 'Diamond', 
                            coinValue: 750, 
                            userCoinBalance: _userCoinBalance,
                            onTap: () => _sendGiftWithModalState('💎', 750, setModalState)
                          ),
                          GiftCard(
                            icon: Icons.fort, 
                            label: 'Castle', 
                            coinValue: 1000, 
                            userCoinBalance: _userCoinBalance,
                            onTap: () => _sendGiftWithModalState('🏰', 1000, setModalState)
                          ),
                          GiftCard(
                            icon: Icons.language, 
                            label: 'Planet', 
                            coinValue: 1250, 
                            userCoinBalance: _userCoinBalance,
                            onTap: () => _sendGiftWithModalState('🪐', 1250, setModalState)
                          ),
                          GiftCard(
                            icon: Icons.pets, 
                            label: 'Dragon', 
                            coinValue: 2000, 
                            userCoinBalance: _userCoinBalance,
                            onTap: () => _sendGiftWithModalState('🐉', 2000, setModalState)
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _isDisposed = true;
    _liveUserSubscription?.cancel();
    _timerSubscription?.cancel();
    _chatController.dispose();
    _scrollController.dispose();
    _giftComboTimer?.cancel();
    _agoraService.dispose();
    _chatSubscription?.cancel(); // Cancel Firestore subscription
    super.dispose();
  }

  Widget _buildUserAvatar(String userId, String username) {
    if (userId.isEmpty) {
      return CircleAvatar(
        radius: 12,
        backgroundColor: Colors.grey,
        child: Text(
          username.isNotEmpty ? username[0].toUpperCase() : 'U',
          style: const TextStyle(color: Colors.white, fontSize: 10),
        ),
      );
    }

    return FutureBuilder<String?>(
      future: _getUserAvatar(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircleAvatar(
            radius: 12,
            backgroundColor: Colors.grey,
            child: const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          );
        }

        final avatarUrl = snapshot.data;
        if (avatarUrl != null && avatarUrl.isNotEmpty) {
          // Check if it's a local file path
          if (avatarUrl.startsWith('/')) {
            return CircleAvatar(
              radius: 12,
              backgroundImage: FileImage(File(avatarUrl)),
              backgroundColor: Colors.grey,
            );
          }
          
          // Network image
          return CircleAvatar(
            radius: 12,
            backgroundImage: CachedNetworkImageProvider(avatarUrl),
            backgroundColor: Colors.grey,
            onBackgroundImageError: (exception, stackTrace) {
              // Fallback to username initial if image fails to load
            },
          );
        }

        // Fallback to username initial
        return CircleAvatar(
          radius: 12,
          backgroundColor: Colors.grey,
          child: Text(
            username.isNotEmpty ? username[0].toUpperCase() : 'U',
            style: const TextStyle(color: Colors.white, fontSize: 10),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false,
      body: GestureDetector(
        onTap: () {
          // Dismiss keyboard when tapping outside
          FocusScope.of(context).unfocus();
        },
        child: Stack(
          children: [
            // Full-screen video background
            Positioned.fill(
              child: _isStreamer && _isStreamStarted
                  ? _agoraService.getLocalVideoView()
                  : _agoraService.getRemoteVideoView(),
            ),
            
            // Custom UI overlay
            SafeArea(
          child: Column(
            children: [
                  const SizedBox(height: 10),
              StreamerHeaderWidget(
                displayName: _currentLiveUserName,
                onFollowPressed: () {
                  // Handle follow action
                },
                onProfilePressed: () {
                      // Navigate to the live user's profile
                      if (_currentLiveUserId != null && _currentLiveUserId!.isNotEmpty) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProfilePage(userId: _currentLiveUserId!),
                          ),
                        );
                      } else {
                        // Show a snackbar if no live user is available
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('No live user profile available'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                },
                rightOverlay: StreamStatsOverlay(
                  viewerCount: "1.2K",
                  coinCount: _coinTotal,
                      timerStream: _queueService.timerStream,
                      liveUserStream: _queueService.liveUserStream,
                ),
              ),
                  
                  // Spacer to push chat to bottom
              const Spacer(),
                  
                  // Chat area overlay at bottom
                  Container(
                    height: 200, // Increased to show more chat history
                    child: Column(
                      children: [
                        // Chat messages
                        Expanded(
                child: ShaderMask(
                  shaderCallback: (Rect bounds) {
                    return LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black],
                      stops: const [0.0, 0.6], // Increased from 0.3 to 0.6 to show more chat history
                    ).createShader(bounds);
                  },
                  blendMode: BlendMode.dstIn,
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: _chatMessages.length,
                    itemBuilder: (context, index) {
                                final msg = _chatMessages[index];
                      final isGift = msg['isGift'] ?? false;
                      return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                        child: Row(
                          children: [
                            _buildUserAvatar(msg['userId'] ?? '', msg['displayName'] ?? ''),
                            const SizedBox(width: 6),
                            Container(
                              constraints: const BoxConstraints(maxWidth: 250),
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isGift ? const Color(0xFFFFB74D) : Colors.white12,
                                          borderRadius: BorderRadius.circular(8),
                              ),
                              child: RichText(
                                text: TextSpan(
                                            style: const TextStyle(fontSize: 12),
                                  children: [
                                              WidgetSpan(
                                                child: GestureDetector(
                                                  onTap: () {
                                                    // Navigate to profile page only if userId exists
                                                    final userId = msg['userId'];
                                                    if (userId != null && userId.isNotEmpty) {
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) => ProfilePage(userId: userId),
                                                        ),
                                                      );
                                                    } else {
                                                      // Show a snackbar if userId is not available
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        const SnackBar(
                                                          content: Text('User profile not available'),
                                                          duration: Duration(seconds: 2),
                                                        ),
                                                      );
                                                    }
                                                  },
                                                  child: Text(
                                                    msg['displayName'] + ': ',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        color: Colors.white,
                                                    ),
                                                  ),
                                      ),
                                    ),
                                    TextSpan(
                                      text: msg['message'],
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
                        // Chat input
              Container(
                          height: 50, // Increased from 32 to 50
                          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8), // Increased padding
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _chatController,
                                  style: const TextStyle(color: Colors.white, fontSize: 14), // Increased font size
                        decoration: InputDecoration(
                          hintText: 'Send a message...',
                                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14), // Increased font size
                          fillColor: Colors.white12,
                          filled: true,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // Increased padding
                          border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12), // Increased border radius
                            borderSide: BorderSide.none,
                          ),
                        ),
                                  onSubmitted: (text) => _sendChatMessage(text),
                      ),
                    ),
                              const SizedBox(width: 8), // Increased spacing
                    IconButton(
                                icon: const Icon(Icons.send, color: Color(0xFFFFB74D), size: 20), // Increased icon size
                                onPressed: () => _sendChatMessage(_chatController.text),
                    ),
                    IconButton(
                                icon: const Icon(FontAwesomeIcons.gift, color: Color(0xFFFFB74D), size: 20), // Increased icon size
                      onPressed: _openGiftMenu,
                    ),
                  ],
                ),
              ),
            ],
          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GiftCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final int coinValue;
  final int userCoinBalance;
  final VoidCallback onTap;

  const GiftCard({
    required this.icon,
    required this.label,
    required this.coinValue,
    required this.userCoinBalance,
    required this.onTap,
  });

  @override
  State<GiftCard> createState() => _GiftCardState();
}

class _GiftCardState extends State<GiftCard> {
  int _tapCount = 0;
  Timer? _timer;
  bool _wasTapped = false;

  Color _getBurnColor(int taps) {
    if (!_wasTapped) return Colors.grey[200]!;
    if (taps < 5) return Colors.yellow;
    if (taps < 10) return Colors.amber;
    if (taps < 20) return const Color(0xFFFFB74D);
    if (taps < 40) return Colors.deepOrange;
    if (taps < 80) return Colors.red;
    return Colors.black;
  }

  void _handleTap() {
    widget.onTap();
    HapticFeedback.mediumImpact();

    setState(() {
      _tapCount++;
      _wasTapped = true;
    });

    _timer?.cancel();
    _timer = Timer(const Duration(seconds: 1), () {
      setState(() {
        _tapCount = 0;
        _wasTapped = false;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final burnColor = _getBurnColor(_tapCount);
    final canAfford = widget.userCoinBalance >= widget.coinValue;
    final isDisabled = !canAfford;

    return GestureDetector(
      onTap: isDisabled ? null : _handleTap,
      child: Opacity(
        opacity: isDisabled ? 0.5 : 1.0,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDisabled ? Colors.grey[300] : burnColor,
                shape: BoxShape.circle,
              ),
              child: _tapCount > 1
                  ? Text(
                      '+$_tapCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    )
                  : Icon(
                      widget.icon, 
                      size: 18, 
                      color: isDisabled ? Colors.grey[600] : const Color(0xFFFFB74D)
                    ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.label, 
              style: TextStyle(
                fontSize: 12, 
                fontWeight: FontWeight.bold,
                color: isDisabled ? Colors.grey[600] : Colors.black,
              )
            ),
            Text(
              '${widget.coinValue}', 
              style: TextStyle(
                fontSize: 10,
                color: isDisabled ? Colors.grey[600] : Colors.black,
              )
            ),
          ],
        ),
      ),
    );
  }
}
