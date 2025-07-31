import 'dart:io';
import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:image_picker/image_picker.dart';
import './settings_page.dart';
import './widgets/settings_button.dart';
import './widgets/profile_header.dart';
import './widgets/social_links_section.dart';
import './edit_profile_page.dart';
import '../../../models/user_profile.dart';
import '../../../services/profile_service.dart';
import 'package:path_provider/path_provider.dart';

class ProfilePage extends StatefulWidget {
  final String? userId; // Optional userId to view other users' profiles
  
  const ProfilePage({super.key, this.userId});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ProfileService _profileService = ProfileService();
  final PageController _carouselController = PageController();
  UserProfile? _profile;
  bool _isLoading = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFB74D),
        title: Text(
          widget.userId != null ? 'User Profile' : 'Profile',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: widget.userId == null ? const [
          SettingsButton(),
        ] : null,
      ),
      body: StreamBuilder<UserProfile?>(
        stream: widget.userId != null 
            ? _profileService.getUserProfileStream(widget.userId!)
            : _profileService.getCurrentUserProfile(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFFFB74D),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading profile: ${snapshot.error}',
                    style: const TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final profile = snapshot.data;
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                ProfileHeader(
                  profile: profile,
                  onEditPressed: (widget.userId == null && profile != null) ? () => _navigateToEditProfile(profile) : null,
                ),
                SocialLinksSection(
                  profile: profile,
                  onEditPressed: (widget.userId == null && profile != null) ? () => _navigateToEditProfile(profile) : null,
                ),
                _buildMediaSection(profile),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMediaSection(UserProfile? profile) {
    // Get existing media URLs from profile - this is the single source of truth
    final existingMediaUrls = profile?.mediaUrls ?? [];
    
    print("🔍 [DEBUG] Profile media URLs: $existingMediaUrls");
    
    // Only use profile data to avoid duplicates
    final allMedia = existingMediaUrls.map((path) {
      print("🔍 [DEBUG] Adding image: $path");
      return _createImageProvider(path);
    }).toList();

    print("🔍 [DEBUG] Total media count: ${allMedia.length}");

    if (allMedia.isEmpty) {
      return GestureDetector(
        onTap: _pickImage,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            children: [
              Icon(Icons.photo_library, size: 48, color: Colors.grey[600]),
              const SizedBox(height: 12),
              Text(
                'No photos yet',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tap to add photos to showcase yourself!',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 360,
          child: PageView.builder(
            controller: _carouselController,
            itemCount: allMedia.length,
            itemBuilder: (context, index) {
              return Stack(
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      image: DecorationImage(
                        image: allMedia[index],
                        fit: BoxFit.cover,
                        onError: (exception, stackTrace) {
                          print("❌ [DEBUG] Error loading image at index $index: $exception");
                        },
                      ),
                    ),
                  ),
                  // Delete button for all images
                  Positioned(
                    top: 10,
                    left: 10,
                    child: GestureDetector(
                      onTap: () async {
                        try {
                          final imagePath = existingMediaUrls[index];
                          
                          // Remove from Firebase
                          final success = await _profileService.removeMediaUrl(imagePath);
                          
                          if (success) {
                            // Refresh the page to update the UI
                            setState(() {});
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Failed to remove image from profile.')),
                            );
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error removing image: $e')),
                          );
                        }
                      },
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        SmoothPageIndicator(
          controller: _carouselController,
          count: allMedia.length,
          effect: const WormEffect(
            dotColor: Colors.grey,
            activeDotColor: Color(0xFFFFA726),
            dotHeight: 10,
            dotWidth: 10,
          ),
        ),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            width: 58,
            height: 58,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFFFFA726), Color(0xFFFF7043)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Icon(Icons.add_photo_alternate_outlined, color: Colors.white),
          ),
        ),
      ],
    );
  }

  ImageProvider _createImageProvider(String path) {
    try {
      final file = File(path);
      if (file.existsSync()) {
        return FileImage(file);
      } else {
        print("❌ [DEBUG] File does not exist: $path");
        // Return a placeholder image
        return const AssetImage('assets/avatar_placeholder.png');
      }
    } catch (e) {
      print("❌ [DEBUG] Error creating image provider for $path: $e");
      // Return a placeholder image
      return const AssetImage('assets/avatar_placeholder.png');
    }
  }

  Future<void> _pickImage() async {
    // Get current profile to check existing images
    final currentProfile = await _profileService.getCurrentUserProfileFuture();
    final existingMediaUrls = currentProfile?.mediaUrls ?? [];
    
    if (existingMediaUrls.length >= 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can only upload up to 6 total photos.')),
      );
      return;
    }

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      try {
        // Show loading indicator
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Uploading image...')),
        );

        // Copy image to permanent storage
        final permanentPath = await _copyImageToPermanentLocation(pickedFile.path);
        
        // Save to user's profile in Firebase
        final success = await _profileService.addMediaUrl(permanentPath);
        
        if (success) {
          // Refresh the profile data to get the updated list
          setState(() {});
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image uploaded successfully!')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to save image. Please try again.')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading image: $e')),
        );
      }
    }
  }

  Future<String> _copyImageToPermanentLocation(String originalPath) async {
    try {
      final originalFile = File(originalPath);
      if (!await originalFile.exists()) {
        throw Exception('Original file does not exist');
      }

      // Get the app's documents directory for permanent storage
      final appDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${appDir.path}/profile_images');
      
      // Create the directory if it doesn't exist
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      // Generate a unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = originalPath.split('.').last;
      final newFileName = 'profile_image_$timestamp.$extension';
      final newPath = '${imagesDir.path}/$newFileName';

      // Copy the file to the permanent location
      await originalFile.copy(newPath);
      
      print("🔍 [DEBUG] Image copied from $originalPath to $newPath");
      return newPath;
    } catch (e) {
      print("❌ [DEBUG] Error copying image: $e");
      // Fallback to original path if copying fails
      return originalPath;
    }
  }

  void _navigateToEditProfile(UserProfile profile) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfilePage(profile: profile),
      ),
    );
  }
}
