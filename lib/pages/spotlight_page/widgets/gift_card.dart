import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

class GiftCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final int coinValue;
  final VoidCallback onTap;

  const GiftCard({
    super.key,
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