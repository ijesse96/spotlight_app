import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../models/user_profile.dart';

class SocialLinksSection extends StatelessWidget {
  final UserProfile? profile;
  final VoidCallback? onEditPressed;

  const SocialLinksSection({
    super.key,
    this.profile,
    this.onEditPressed,
  });

  @override
  Widget build(BuildContext context) {
    final socialLinks = profile?.socialLinks ?? {};
    
    if (socialLinks.isEmpty) {
      return Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                Icon(Icons.link, color: Colors.grey[600], size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No social links yet',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                ),
                if (onEditPressed != null)
                  TextButton(
                    onPressed: onEditPressed,
                    child: const Text(
                      'Add',
                      style: TextStyle(
                        color: Color(0xFFFFB74D),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 30),
        ],
      );
    }

    return Column(
      children: [
        ...socialLinks.entries.map((entry) {
          return Column(
            children: [
              _socialButton(
                platform: entry.key,
                url: entry.value,
                onTap: () => _launchUrl(entry.value),
              ),
              const SizedBox(height: 16),
            ],
          );
        }).toList(),
        if (onEditPressed != null) ...[
          _editButton(onEditPressed!),
          const SizedBox(height: 16),
        ],
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _socialButton({
    required String platform,
    required String url,
    required VoidCallback onTap,
  }) {
    final icon = _getPlatformIcon(platform);
    final label = _getPlatformLabel(platform);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            FaIcon(icon, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 16),
              ),
            ),
            Icon(Icons.open_in_new, size: 16, color: Colors.grey[600]),
          ],
        ),
      ),
    );
  }

  Widget _editButton(VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFFFB74D)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          children: [
            Icon(Icons.edit, color: Color(0xFFFFB74D), size: 22),
            SizedBox(width: 14),
            Text(
              'Edit Social Links',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFFFFB74D),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getPlatformIcon(String platform) {
    switch (platform.toLowerCase()) {
      case 'instagram':
        return FontAwesomeIcons.instagram;
      case 'twitch':
        return FontAwesomeIcons.twitch;
      case 'youtube':
        return FontAwesomeIcons.youtube;
      case 'twitter':
        return FontAwesomeIcons.twitter;
      case 'tiktok':
        return FontAwesomeIcons.tiktok;
      case 'discord':
        return FontAwesomeIcons.discord;
      case 'website':
        return FontAwesomeIcons.globe;
      default:
        return FontAwesomeIcons.link;
    }
  }

  String _getPlatformLabel(String platform) {
    switch (platform.toLowerCase()) {
      case 'instagram':
        return 'Instagram';
      case 'twitch':
        return 'Twitch';
      case 'youtube':
        return 'YouTube';
      case 'twitter':
        return 'Twitter';
      case 'tiktok':
        return 'TikTok';
      case 'discord':
        return 'Discord';
      case 'website':
        return 'Website';
      default:
        return platform;
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      print('Could not launch $url');
    }
  }
} 