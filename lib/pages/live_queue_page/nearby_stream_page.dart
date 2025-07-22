import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../services/queue_service.dart';
import '../spotlight_page/widgets/gift_card.dart';
import '../spotlight_page/widgets/chat_box_widget.dart';
import '../spotlight_page/widgets/gift_panel_widget.dart';
import '../spotlight_page/widgets/viewer_coin_overlay.dart';
import '../spotlight_page/widgets/countdown_timer_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NearbyStreamPage extends StatefulWidget {
  final String locationId;
  final String locationName;
  final double distance;

  const NearbyStreamPage({
    super.key,
    required this.locationId,
    required this.locationName,
    required this.distance,
  });

  @override
  State<NearbyStreamPage> createState() => _NearbyStreamPageState();
}

class _NearbyStreamPageState extends State<NearbyStreamPage> {
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _chatMessages = [];
  final Map<String, int> _giftCounts = {};
  int _coinTotal = 0;
  int _userCoinBalance = 1250;
  bool _shouldAutoScroll = true;

  Timer? _giftComboTimer;
  String? _comboGiftName;
  int _comboGiftCount = 0;

  // Nearby queue rotation variables
  Duration _countdown = const Duration(seconds: 20);
  String _currentLiveUserName = "Waiting...";
  final QueueService _queueService = QueueService();
  StreamSubscription<Map<String, dynamic>?>? _liveUserSubscription;
  StreamSubscription<Map<String, dynamic>?>? _timerSubscription;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      final atBottom = _scrollController.offset >= _scrollController.position.maxScrollExtent;
      setState(() {
        _shouldAutoScroll = atBottom;
      });
    });
    _initializeNearbyStream();
  }

  void _initializeNearbyStream() async {
    // Don't initialize timer here - let the queue list page handle it
    // Just listen to the existing timer
    _listenToNearbyLiveUser();
    _listenToNearbyTimer();
  }

  void _listenToNearbyLiveUser() {
    _liveUserSubscription = _queueService.getNearbyLiveUser(widget.locationId).listen((liveUser) {
      if (liveUser != null) {
        setState(() {
          _currentLiveUserName = liveUser['name'] ?? "Waiting...";
        });
      } else {
        setState(() {
          _currentLiveUserName = "Waiting...";
        });
      }
    });
  }

  void _listenToNearbyTimer() {
    _timerSubscription = _queueService.getNearbyTimer(widget.locationId).listen((timerData) {
      if (timerData != null) {
        final countdown = timerData['countdown'] ?? 20;
        final isActive = timerData['isActive'] ?? false;
        
        print('Nearby stream timer update - Countdown: $countdown, IsActive: $isActive');
        
        setState(() {
          _countdown = Duration(seconds: countdown);
        });
        
        // The persistent timer in QueueService handles user rotation
      }
    });
  }

  void _sendChatMessage(String username, String message, {bool isGift = false}) {
    if (message.trim().isEmpty) return;

    setState(() {
      _chatMessages.add({
        'username': username,
        'message': message,
        'isGift': isGift,
      });
    });

    _chatController.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients && _shouldAutoScroll) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  void _sendGiftWithModalState(String giftName, int coinAmount, void Function(void Function()) setModalState) {
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

      _sendChatMessage("GiftSender", comboMessage, isGift: true);

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
                          GiftCard(icon: Icons.local_florist, label: 'Rose', coinValue: 50, onTap: () => _sendGiftWithModalState('🌹', 50, setModalState)),
                          GiftCard(icon: Icons.whatshot, label: 'Fire', coinValue: 100, onTap: () => _sendGiftWithModalState('🔥', 100, setModalState)),
                          GiftCard(icon: Icons.star, label: 'Star', coinValue: 200, onTap: () => _sendGiftWithModalState('⭐', 200, setModalState)),
                          GiftCard(icon: Icons.emoji_events, label: 'Crown', coinValue: 250, onTap: () => _sendGiftWithModalState('👑', 250, setModalState)),
                          GiftCard(icon: Icons.flash_on, label: 'Zap', coinValue: 300, onTap: () => _sendGiftWithModalState('⚡', 300, setModalState)),
                          GiftCard(icon: Icons.favorite, label: 'Heart', coinValue: 400, onTap: () => _sendGiftWithModalState('❤️', 400, setModalState)),
                          GiftCard(icon: Icons.rocket, label: 'Rocket', coinValue: 500, onTap: () => _sendGiftWithModalState('🚀', 500, setModalState)),
                          GiftCard(icon: Icons.ac_unit, label: 'Ice', coinValue: 600, onTap: () => _sendGiftWithModalState('❄️', 600, setModalState)),
                          GiftCard(icon: Icons.diamond, label: 'Diamond', coinValue: 750, onTap: () => _sendGiftWithModalState('💎', 750, setModalState)),
                          GiftCard(icon: Icons.fort, label: 'Castle', coinValue: 1000, onTap: () => _sendGiftWithModalState('🏰', 1000, setModalState)),
                          GiftCard(icon: Icons.language, label: 'Planet', coinValue: 1250, onTap: () => _sendGiftWithModalState('🪐', 1250, setModalState)),
                          GiftCard(icon: Icons.pets, label: 'Dragon', coinValue: 2000, onTap: () => _sendGiftWithModalState('🐉', 2000, setModalState)),
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
    _giftComboTimer?.cancel();
    _liveUserSubscription?.cancel();
    _timerSubscription?.cancel();
    _chatController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFB74D),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Nearby Spotlight',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.white24,
                      child: Icon(Icons.person, size: 16, color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            flex: 2,
                            child: Text(
                            "@${_currentLiveUserName.toLowerCase().replaceAll(' ', '')}",
                            style: const TextStyle(color: Colors.white),
                            overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            flex: 0,
                            child: GestureDetector(
                            onTap: () {
                              // Navigate to profile page
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFB74D),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text("+Follow", style: TextStyle(color: Colors.white)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.remove_red_eye, color: Color(0xFFFFB74D), size: 16),
                            const SizedBox(width: 4),
                            const Text(
                              "1.2K",
                              style: TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.timer, color: Color(0xFFFFB74D), size: 16),
                            const SizedBox(width: 4),
                            StreamBuilder<Map<String, dynamic>?>(
                              stream: _queueService.getNearbyTimer(widget.locationId),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) return const SizedBox.shrink();
                                final data = snapshot.data!;
                                final countdown = data['countdown'] ?? 20;
                                final isActive = data['isActive'] ?? false;
                                
                                // Check if there's a live user to determine if timer should be active
                                return StreamBuilder<Map<String, dynamic>?>(
                                  stream: _queueService.getNearbyLiveUser(widget.locationId),
                                  builder: (context, liveUserSnapshot) {
                                    final hasLiveUser = liveUserSnapshot.hasData && liveUserSnapshot.data != null;
                                    // If there's a live user, show timer as active (white) regardless of isActive flag
                                    // Also show as active if timer is active (to prevent flickering during stream loading)
                                    // If live user stream is still loading, assume active if timer is active
                                    final shouldShowActive = hasLiveUser || isActive || (liveUserSnapshot.connectionState == ConnectionState.waiting && isActive);
                                    
                                    if (!shouldShowActive) return const SizedBox.shrink();
                                    
                                    return Text(
                                      '$countdown s',
                                      style: const TextStyle(color: Colors.white, fontSize: 12),
                                    );
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(FontAwesomeIcons.coins, color: Color(0xFFFFB74D), size: 16),
                            const SizedBox(width: 4),
                            Text(
                              "$_coinTotal",
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                height: 160,
                child: ShaderMask(
                  shaderCallback: (Rect bounds) {
                    return LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black],
                      stops: const [0.0, 0.3],
                    ).createShader(bounds);
                  },
                  blendMode: BlendMode.dstIn,
                  child: ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    itemCount: _chatMessages.length,
                    itemBuilder: (context, index) {
                      final msg = _chatMessages[_chatMessages.length - 1 - index];
                      final isGift = msg['isGift'] ?? false;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        child: Row(
                          children: [
                            const CircleAvatar(radius: 8, backgroundColor: Colors.white),
                            const SizedBox(width: 8),
                            Container(
                              constraints: const BoxConstraints(maxWidth: 250),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: isGift ? const Color(0xFFFFB74D) : Colors.white12,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: RichText(
                                text: TextSpan(
                                  style: const TextStyle(fontSize: 14),
                                  children: [
                                    TextSpan(
                                      text: msg['username'] + ': ',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
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
              Container(
                height: 40,
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _chatController,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Send a message...',
                          hintStyle: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13),
                          fillColor: Colors.white12,
                          filled: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onSubmitted: (text) => _sendChatMessage("User123", text),
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.send, color: Color(0xFFFFB74D), size: 18),
                      onPressed: () => _sendChatMessage("User123", _chatController.text),
                    ),
                    IconButton(
                      icon: const Icon(FontAwesomeIcons.gift, color: Color(0xFFFFB74D), size: 18),
                      onPressed: _openGiftMenu,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 