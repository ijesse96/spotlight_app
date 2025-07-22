import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../models/user_profile.dart';
import '../../../services/profile_service.dart';

class ProfileHeader extends StatelessWidget {
  final UserProfile? profile;
  final VoidCallback? onEditPressed;

  const ProfileHeader({
    super.key,
    this.profile,
    this.onEditPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: 60,
              backgroundImage: _getProfileImage(),
            ),
            if (onEditPressed != null)
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: onEditPressed,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFB74D),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.edit,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          profile?.displayName ?? 'User',
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Text(
          profile?.bio ?? "No bio yet. Tap the edit button to add one!",
          style: TextStyle(
            fontSize: 16,
            color: profile?.bio != null ? Colors.black87 : Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  ImageProvider _getProfileImage() {
    if (profile?.avatarUrl != null && profile!.avatarUrl!.isNotEmpty) {
      return CachedNetworkImageProvider(
        profile!.avatarUrl!,
        errorListener: (error) => print('Error loading avatar: $error'),
      );
    }
    return const AssetImage('assets/avatar_placeholder.png');
  }
} 