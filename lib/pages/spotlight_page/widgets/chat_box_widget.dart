import 'package:flutter/material.dart';
import 'dart:async';

class ChatBoxWidget extends StatefulWidget {
  final List<Map<String, dynamic>> chatMessages;
  final ScrollController scrollController;
  final Function(String username, String message, {bool isGift}) onSendMessage;
  final VoidCallback onGiftButtonPressed;
  final bool shouldAutoScroll;

  const ChatBoxWidget({
    super.key,
    required this.chatMessages,
    required this.scrollController,
    required this.onSendMessage,
    required this.onGiftButtonPressed,
    required this.shouldAutoScroll,
  });

  @override
  State<ChatBoxWidget> createState() => _ChatBoxWidgetState();
}

class _ChatBoxWidgetState extends State<ChatBoxWidget> with TickerProviderStateMixin {
  final TextEditingController _chatController = TextEditingController();
  final List<GiftToastData> _giftToasts = [];
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(_fadeController);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_chatController.text.trim().isNotEmpty) {
      widget.onSendMessage("User123", _chatController.text, isGift: false);
      _chatController.clear();
    }
  }

  void _addGiftToast(String username, String giftName, int quantity) {
    final toast = GiftToastData(
      id: DateTime.now().millisecondsSinceEpoch,
      username: username,
      giftName: giftName,
      quantity: quantity,
    );
    
    setState(() {
      _giftToasts.add(toast);
    });

    // Remove toast after 3 seconds
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _giftToasts.removeWhere((t) => t.id == toast.id);
        });
      }
    });
  }

  List<Map<String, dynamic>> get _visibleMessages {
    final startIndex = widget.chatMessages.length > 5 
        ? widget.chatMessages.length - 5 
        : 0;
    return widget.chatMessages.sublist(startIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Chat messages area
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          bottom: 60, // Leave space for input field
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              children: [
                // Gift toasts area (top half)
                Expanded(
                  flex: 1,
                  child: Stack(
                    children: _giftToasts.map((toast) {
                      final index = _giftToasts.indexOf(toast);
                      return Positioned(
                        top: index * 80.0, // Stack vertically
                        right: 8,
                        child: AnimatedOpacity(
                          opacity: 1.0,
                          duration: const Duration(milliseconds: 300),
                          child: GiftToastBubble(
                            username: toast.username,
                            giftName: toast.giftName,
                            quantity: toast.quantity,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                // Chat messages area (bottom half)
                Expanded(
                  flex: 1,
                  child: ListView.builder(
                    controller: widget.scrollController,
                    reverse: true,
                    itemCount: _visibleMessages.length,
                    itemBuilder: (context, index) {
                      final msg = _visibleMessages[_visibleMessages.length - 1 - index];
                      final isGift = msg['isGift'] ?? false;
                      
                      // Add gift toast for gift messages
                      if (isGift && msg['displayName'] == 'GiftSender') {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _addGiftToast('GiftSender', msg['message'], 1);
                        });
                      }

                      return AnimatedOpacity(
                        opacity: 1.0,
                        duration: const Duration(milliseconds: 200),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 12,
                                backgroundColor: Colors.white,
                                child: Text(
                                  msg['displayName'][0].toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Container(
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
                                          text: msg['displayName'] + ': ',
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
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        // Fixed input field at bottom
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 60,
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.0),
                  Colors.black.withOpacity(0.8),
                ],
              ),
            ),
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
                    onSubmitted: (text) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.send, color: Color(0xFFFFB74D), size: 18),
                  onPressed: _sendMessage,
                ),
                IconButton(
                  icon: const Icon(Icons.card_giftcard, color: Color(0xFFFFB74D), size: 18),
                  onPressed: widget.onGiftButtonPressed,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class GiftToastBubble extends StatelessWidget {
  final String username;
  final String giftName;
  final int quantity;

  const GiftToastBubble({
    super.key,
    required this.username,
    required this.giftName,
    required this.quantity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFB74D),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: Colors.white,
            child: Text(
              username[0].toUpperCase(),
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            username,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            giftName,
            style: const TextStyle(fontSize: 16),
          ),
          if (quantity > 1) ...[
            const SizedBox(width: 4),
            Text(
              'x$quantity',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class GiftToastData {
  final int id;
  final String username;
  final String giftName;
  final int quantity;

  GiftToastData({
    required this.id,
    required this.username,
    required this.giftName,
    required this.quantity,
  });
} 