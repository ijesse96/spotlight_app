import 'package:flutter/material.dart';

class StreamerHeaderWidget extends StatelessWidget {
  final String username;
  final VoidCallback? onFollowPressed;
  final VoidCallback? onProfilePressed;
  final Widget? rightOverlay;

  const StreamerHeaderWidget({
    super.key,
    required this.username,
    this.onFollowPressed,
    this.onProfilePressed,
    this.rightOverlay,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: onProfilePressed,
            child: const CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white24,
              child: Icon(Icons.person, size: 16, color: Colors.white),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  flex: 2,
                  child: GestureDetector(
                    onTap: onProfilePressed,
                    child: Text(
                      "@${username.toLowerCase().replaceAll(' ', '')}",
                      style: const TextStyle(color: Colors.white),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  flex: 0,
                  child: GestureDetector(
                    onTap: onFollowPressed,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFB74D),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        "+Follow", 
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (rightOverlay != null) ...[
            const SizedBox(width: 8),
            rightOverlay!,
          ],
        ],
      ),
    );
  }
} 