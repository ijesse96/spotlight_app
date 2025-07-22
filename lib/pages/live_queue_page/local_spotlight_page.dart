import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../services/queue_service.dart';
import 'package:spotlight_app/pages/profile_page/profile_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LocalSpotlightPage extends StatefulWidget {
  final String locationId;
  final String liveUserName;
  final int viewerCount;

  const LocalSpotlightPage({
    Key? key,
    required this.locationId,
    required this.liveUserName,
    required this.viewerCount,
  }) : super(key: key);

  @override
  State<LocalSpotlightPage> createState() => _LocalSpotlightPageState();
}

class _LocalSpotlightPageState extends State<LocalSpotlightPage> {
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

  // TODO: Local queues should use separate Firestore collection (e.g., 'local_queue_{event}')
  // Currently using mock data to avoid conflicts with spotlight_queue collection
  // Queue rotation variables
  Timer? _rotationTimer;
  Duration _countdown = const Duration(seconds: 15);
  String _currentLiveUserName = "";
  final List<Map<String, dynamic>> _queueUsers = [
    {"name": "Alex", "ready": true},
    {"name": "Bri", "ready": false},
    {"name": "Jordan", "ready": true},
  ];
  final QueueService _queueService = QueueService();

  @override
  void initState() {
    super.initState();
    _currentLiveUserName = widget.liveUserName;
    _scrollController.addListener(() {
      final atBottom = _scrollController.offset >= _scrollController.position.maxScrollExtent;
      setState(() {
        _shouldAutoScroll = atBottom;
      });
    });
    _startRotationTimer();
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

  void _startRotationTimer() {
    _rotationTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      try {
        final timerDoc = await _queueService.getLocalTimer(widget.locationId).first;
        
        if (timerDoc != null) {
          final currentCountdown = timerDoc['countdown'] ?? 15;
          final isActive = timerDoc['isActive'] ?? false;
          
          if (isActive && currentCountdown > 0) {
            setState(() {
              _countdown = Duration(seconds: currentCountdown - 1);
            });
            await _queueService.updateLocalTimer(widget.locationId, currentCountdown - 1, true);
          } else if (isActive && currentCountdown <= 0) {
            await _moveToNextStreamer();
          }
        }
      } catch (e) {
        print('Local timer error: $e');
      }
    });
  }

  Future<void> _moveToNextStreamer() async {
    final queueUsers = await _queueService.getLocalQueueUsers(widget.locationId).first;
    
    if (queueUsers.isNotEmpty) {
      final nextUser = queueUsers.first;
      await _queueService.setUserAsLocalLive(widget.locationId, nextUser['userId'], nextUser['name']);
      setState(() {
        _currentLiveUserName = nextUser['name'];
        _countdown = const Duration(seconds: 15);
        _coinTotal = 0;
        _chatMessages.clear();
      });
    } else {
      await _queueService.endLocalLiveSession(widget.locationId);
      setState(() {
        _currentLiveUserName = "Waiting...";
        _countdown = const Duration(seconds: 15);
      });
    }
    
    await _queueService.resetLocalTimer(widget.locationId);
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
    _giftComboTimer?.cancel();
    _rotationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: true,
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
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
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
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage()));
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Color(0xFFFFB74D),
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
                            Icon(Icons.remove_red_eye, color: Color(0xFFFFB74D), size: 16),
                            SizedBox(width: 4),
                            Text(
                              "${widget.viewerCount}",
                              style: TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.timer, color: Color(0xFFFFB74D), size: 16),
                            const SizedBox(width: 4),
                            StreamBuilder<Map<String, dynamic>?>(
                              stream: _queueService.getLocalTimer(widget.locationId),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) return SizedBox.shrink();
                                final data = snapshot.data!;
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
                                  style: const TextStyle(color: Colors.white, fontSize: 12),
                                );
                              },
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(FontAwesomeIcons.coins, color: Color(0xFFFFB74D), size: 16),
                            SizedBox(width: 4),
                            Text(
                              "$_coinTotal",
                              style: TextStyle(color: Colors.white, fontSize: 12),
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
                                color: isGift ? Color(0xFFFFB74D) : Colors.white12,
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
    if (taps < 20) return Color(0xFFFFB74D);
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
                : Icon(widget.icon, size: 18, color: Color(0xFFFFB74D)),
          ),
          const SizedBox(height: 4),
          Text(widget.label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          Text('${widget.coinValue}', style: const TextStyle(fontSize: 10)),
        ],
      ),
    );
  }
}
