import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:spotlight_app/pages/profile_page/profile_page.dart';
import '../live_queue_page/live_queue_page.dart';
import '../../main.dart';
import '../../services/queue_service.dart';
import 'widgets/gift_card.dart';
import 'widgets/chat_box_widget.dart';
import 'widgets/gift_panel_widget.dart';
import 'widgets/viewer_coin_overlay.dart';
import 'widgets/countdown_timer_widget.dart';

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
  int _coinTotal = 0;
  int _userCoinBalance = 1250;
  bool _shouldAutoScroll = true;

  Timer? _giftComboTimer;
  String? _comboGiftName;
  int _comboGiftCount = 0;

  // Main Spotlight queue rotation variables
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
      final atBottom = _scrollController.offset >= _scrollController.position.maxScrollExtent - 10;
      setState(() {
        _shouldAutoScroll = atBottom;
      });
    });
    _initializeMainSpotlightStream();
  }

  void _initializeMainSpotlightStream() async {
    // Don't initialize timer here - let the queue widget handle it
    // Just listen to the existing timer
    _listenToLiveUser();
    _listenToSpotlightTimer();
    
    // Ensure timer is active if there's a live user
    await _ensureTimerActive();
  }

  Future<void> _ensureTimerActive() async {
    // Check if there's a live user and timer should be active
    final liveUser = await _queueService.getCurrentLiveUser().first;
    if (liveUser != null) {
      final timerData = await _queueService.getSpotlightTimer().first;
      if (timerData != null) {
        final isActive = timerData['isActive'] ?? false;
        if (!isActive) {
          // Activate timer if there's a live user but timer is not active
          await _queueService.updateSpotlightTimer(timerData['countdown'] ?? 20, true);
        }
      }
    }
  }

  void _listenToLiveUser() {
    _liveUserSubscription = _queueService.getCurrentLiveUser().listen((liveUser) {
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

  void _listenToSpotlightTimer() {
    _timerSubscription = _queueService.getSpotlightTimer().listen((timerData) {
      if (timerData != null) {
        final countdown = timerData['countdown'] ?? 20;
        final isActive = timerData['isActive'] ?? false;
        
        print('Spotlight stream timer update - Countdown: $countdown, IsActive: $isActive');
        
        setState(() {
          _countdown = Duration(seconds: countdown);
        });
      }
    });
  }

  void _listenToSpotlightChat() {
    // This method is no longer needed as chat messages are managed locally
  }

  void _listenToSpotlightGiftTotal() {
    // This method is no longer needed as gift total is managed locally
  }

  Future<void> _addTestChatMessages() async {
    // This method is no longer needed as we use local messages
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
    _liveUserSubscription?.cancel();
    _timerSubscription?.cancel();
    _chatController.dispose();
    _scrollController.dispose();
    _giftComboTimer?.cancel();
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
        title: const Text(
          'Spotlight',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
                          Text(
                            "@${_currentLiveUserName.toLowerCase().replaceAll(' ', '')}",
                            style: const TextStyle(color: Colors.white),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
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
                              stream: _queueService.getSpotlightTimer(),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) {
                                  return const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFB74D)),
                                    ),
                                  );
                                }
                                
                                final data = snapshot.data!;
                                final countdown = data['countdown'] ?? 20;
                                final isActive = data['isActive'] ?? false;
                                
                                // Check if there's a live user to determine if timer should be active
                                return StreamBuilder<Map<String, dynamic>?>(
                                  stream: _queueService.getCurrentLiveUser(),
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

class GiftCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final int coinValue;
  final VoidCallback onTap;

  const GiftCard({
    required this.icon,
    required this.label,
    required this.coinValue,
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

    return GestureDetector(
      onTap: _handleTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: burnColor,
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
                : Icon(widget.icon, size: 18, color: const Color(0xFFFFB74D)),
          ),
          const SizedBox(height: 4),
          Text(widget.label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          Text('${widget.coinValue}', style: const TextStyle(fontSize: 10)),
        ],
      ),
    );
  }
}
