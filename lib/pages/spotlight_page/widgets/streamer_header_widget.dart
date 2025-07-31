import 'package:flutter/material.dart';

class StreamerHeaderWidget extends StatelessWidget {
  final String displayName;
  final String? username;
  final VoidCallback? onFollowPressed;
  final VoidCallback? onProfilePressed;
  final Widget? rightOverlay;

  const StreamerHeaderWidget({
    super.key,
    required this.displayName,
    this.username,
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: onProfilePressed,
                  child: Text(
                    displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (username != null && username!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  GestureDetector(
                    onTap: onProfilePressed,
                    child: Text(
                      "@${username!.toLowerCase().replaceAll(' ', '')}",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
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
          if (rightOverlay != null) ...[
            const SizedBox(width: 8),
            rightOverlay!,
          ],
        ],
      ),
    );
  }
} 