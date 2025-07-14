import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ViewerCoinOverlay extends StatelessWidget {
  final String viewerCount;
  final int totalCoins;

  const ViewerCoinOverlay({
    super.key,
    required this.viewerCount,
    required this.totalCoins,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          children: [
            const Icon(Icons.remove_red_eye, color: Color(0xFFFFB74D), size: 16),
            const SizedBox(width: 4),
            Text(viewerCount, style: const TextStyle(color: Colors.white)),
          ],
        ),
        Row(
          children: [
            const Icon(FontAwesomeIcons.coins, color: Color(0xFFFFB74D), size: 16),
            const SizedBox(width: 4),
            Text("$totalCoins", style: const TextStyle(color: Colors.white)),
          ],
        ),
      ],
    );
  }
} 