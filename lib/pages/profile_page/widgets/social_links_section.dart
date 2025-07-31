import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
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
    
    print('🔗 [DEBUG] Social links section - Profile: ${profile?.username}');
    print('🔗 [DEBUG] Social links count: ${socialLinks.length}');
    print('🔗 [DEBUG] Social links: $socialLinks');
    
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
          print('🔗 [DEBUG] Building social link: ${entry.key} = ${entry.value}');
          return Column(
            children: [
              _socialButton(
                platform: entry.key,
                url: entry.value,
                onTap: () {
                  print('🔗 [DEBUG] Social link tapped: ${entry.key} = ${entry.value}');
                  _launchUrl(entry.value, context);
                },
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

  Future<void> _launchUrl(String url, BuildContext context) async {
    try {
      print('🔗 [DEBUG] Attempting to launch URL: $url');
      print('🔗 [DEBUG] URL type: ${url.runtimeType}');
      print('🔗 [DEBUG] URL length: ${url.length}');
      
      // Validate URL format
      if (url.isEmpty) {
        print('❌ [DEBUG] URL is empty');
        _showUrlLaunchError('URL is empty', context);
        return;
      }
      
      // Try to launch the URL directly first
      final uri = Uri.parse(url);
      print('🔗 [DEBUG] Parsed URI: $uri');
      print('🔗 [DEBUG] URI scheme: ${uri.scheme}');
      print('🔗 [DEBUG] URI host: ${uri.host}');
      print('🔗 [DEBUG] URI path: ${uri.path}');
      
      if (await canLaunchUrl(uri)) {
        print('🔗 [DEBUG] Direct launch possible for: $url');
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      } else {
        print('❌ [DEBUG] Direct launch not possible for: $url');
      }
      
      // If direct launch fails, try platform-specific handling
      final platform = _getPlatformFromUrl(url);
      if (platform != null) {
        print('🔗 [DEBUG] Platform detected: $platform');
        final success = await _launchSocialMediaUrl(platform, url);
        if (success) return;
      } else {
        print('❌ [DEBUG] No platform detected for URL: $url');
      }
      
      // Final fallback: try launching in browser with different modes
      print('🔗 [DEBUG] Trying browser fallback for: $url');
      final browserUri = Uri.parse(url);
      
      // Try different launch modes
      final modes = [LaunchMode.externalApplication, LaunchMode.platformDefault, LaunchMode.inAppWebView];
      
      for (final mode in modes) {
        try {
          if (await canLaunchUrl(browserUri)) {
            print('🔗 [DEBUG] Launching with mode: $mode');
            await launchUrl(browserUri, mode: mode);
            return;
          } else {
            print('❌ [DEBUG] Cannot launch with mode: $mode');
          }
        } catch (e) {
          print('🔗 [DEBUG] Failed to launch with mode $mode: $e');
          continue;
        }
      }
      
      // If url_launcher fails completely, try system intent (Android only)
      if (Platform.isAndroid) {
        print('🔗 [DEBUG] Trying system intent for Android');
        final success = await _launchWithSystemIntent(url);
        if (success) return;
      }
      
      // If all else fails, show error message to user
      print('❌ [DEBUG] Could not launch $url with any method');
      _showUrlLaunchError('Unable to open link. Please try opening it manually in your browser.', context);
      
    } catch (e) {
      print('❌ [DEBUG] Error launching URL: $e');
      _showUrlLaunchError('Error opening link: $e', context);
    }
  }
  
  Future<bool> _launchWithSystemIntent(String url) async {
    try {
      // This is a fallback method that uses the system's intent system
      // It's more likely to work when url_launcher fails
      print('🔗 [DEBUG] Attempting system intent launch for: $url');
      
      // Try multiple approaches
      final approaches = [
        () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
        () => launchUrl(Uri.parse(url), mode: LaunchMode.platformDefault),
        () => launchUrl(Uri.parse(url), mode: LaunchMode.inAppWebView),
      ];
      
      for (int i = 0; i < approaches.length; i++) {
        try {
          print('🔗 [DEBUG] Trying system intent approach $i');
          await approaches[i]();
          print('🔗 [DEBUG] System intent approach $i succeeded');
          return true;
        } catch (e) {
          print('❌ [DEBUG] System intent approach $i failed: $e');
          continue;
        }
      }
      
      return false;
    } catch (e) {
      print('❌ [DEBUG] System intent launch failed: $e');
      return false;
    }
  }
  
  void _showUrlLaunchError(String message, BuildContext context) {
    print('❌ [USER] $message');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }
  
  String? _getPlatformFromUrl(String url) {
    final lowerUrl = url.toLowerCase();
    if (lowerUrl.contains('instagram.com')) return 'instagram';
    if (lowerUrl.contains('twitter.com') || lowerUrl.contains('x.com')) return 'twitter';
    if (lowerUrl.contains('youtube.com')) return 'youtube';
    if (lowerUrl.contains('twitch.tv')) return 'twitch';
    if (lowerUrl.contains('tiktok.com')) return 'tiktok';
    if (lowerUrl.contains('discord.gg') || lowerUrl.contains('discord.com')) return 'discord';
    return null;
  }
  
  Future<bool> _launchSocialMediaUrl(String platform, String url) async {
    try {
      switch (platform.toLowerCase()) {
        case 'instagram':
          return await _launchInstagramUrl(url);
        case 'twitter':
          return await _launchTwitterUrl(url);
        case 'youtube':
          return await _launchYouTubeUrl(url);
        default:
          return await _launchGenericUrl(url);
      }
    } catch (e) {
      print('❌ [DEBUG] Error launching $platform URL: $e');
      return false;
    }
  }
  
  Future<bool> _launchInstagramUrl(String url) async {
    try {
      final username = _extractUsername(url);
      print('🔗 [DEBUG] Instagram username: $username');
      
      // Try multiple Instagram app URL formats
      final instagramUrls = [
        'instagram://user?username=$username',
        'instagram://user/$username',
        'instagram://profile/$username',
      ];
      
      for (final appUrl in instagramUrls) {
        try {
          final uri = Uri.parse(appUrl);
          if (await canLaunchUrl(uri)) {
            print('🔗 [DEBUG] Launching Instagram app with: $appUrl');
            await launchUrl(uri);
            return true;
          }
        } catch (e) {
          print('🔗 [DEBUG] Instagram app URL failed: $appUrl - $e');
          continue;
        }
      }
      
      // Fallback to browser
      print('🔗 [DEBUG] Instagram app not available, trying browser');
      return await _launchGenericUrl(url);
      
    } catch (e) {
      print('❌ [DEBUG] Error in Instagram launch: $e');
      return false;
    }
  }
  
  Future<bool> _launchTwitterUrl(String url) async {
    try {
      final username = _extractUsername(url);
      print('🔗 [DEBUG] Twitter username: $username');
      
      // Try Twitter app URL
      final twitterAppUrl = 'twitter://user?screen_name=$username';
      final uri = Uri.parse(twitterAppUrl);
      
      if (await canLaunchUrl(uri)) {
        print('🔗 [DEBUG] Launching Twitter app');
        await launchUrl(uri);
        return true;
      }
      
      // Fallback to browser
      print('🔗 [DEBUG] Twitter app not available, trying browser');
      return await _launchGenericUrl(url);
      
    } catch (e) {
      print('❌ [DEBUG] Error in Twitter launch: $e');
      return false;
    }
  }
  
  Future<bool> _launchYouTubeUrl(String url) async {
    try {
      final path = _extractYouTubePath(url);
      print('🔗 [DEBUG] YouTube path: $path');
      
      // Try YouTube app URL
      final youtubeAppUrl = 'youtube://$path';
      final uri = Uri.parse(youtubeAppUrl);
      
      if (await canLaunchUrl(uri)) {
        print('🔗 [DEBUG] Launching YouTube app');
        await launchUrl(uri);
        return true;
      }
      
      // Fallback to browser
      print('🔗 [DEBUG] YouTube app not available, trying browser');
      return await _launchGenericUrl(url);
      
    } catch (e) {
      print('❌ [DEBUG] Error in YouTube launch: $e');
      return false;
    }
  }
  
  Future<bool> _launchGenericUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      
      // Try different launch modes for browser
      final modes = [LaunchMode.externalApplication, LaunchMode.platformDefault];
      
      for (final mode in modes) {
        try {
          if (await canLaunchUrl(uri)) {
            print('🔗 [DEBUG] Launching generic URL with mode: $mode');
            await launchUrl(uri, mode: mode);
            return true;
          }
        } catch (e) {
          print('🔗 [DEBUG] Generic URL launch failed with mode $mode: $e');
          continue;
        }
      }
      
      return false;
    } catch (e) {
      print('❌ [DEBUG] Error in generic URL launch: $e');
      return false;
    }
  }
  
  String _extractUsername(String url) {
    try {
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;
      if (pathSegments.isNotEmpty) {
        return pathSegments.first;
      }
    } catch (e) {
      print('Error extracting username: $e');
    }
    return '';
  }
  
  String _extractYouTubePath(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.path;
    } catch (e) {
      print('Error extracting YouTube path: $e');
    }
    return '';
  }
} 