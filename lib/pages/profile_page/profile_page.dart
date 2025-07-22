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

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final PageController _carouselController = PageController();
  final List<String> mediaUrls = [
    'assets/dummy1.png',
    'assets/dummy2.png',
    'assets/dummy3.png',
  ];
  final List<File> _uploadedImages = [];
  final ProfileService _profileService = ProfileService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFB74D),
        title: const Text(
          'Profile',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: const [
          SettingsButton(),
        ],
      ),
      body: StreamBuilder<UserProfile?>(
        stream: _profileService.getCurrentUserProfile(),
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
                  onEditPressed: profile != null ? () => _navigateToEditProfile(profile) : null,
                ),
                SocialLinksSection(
                  profile: profile,
                  onEditPressed: profile != null ? () => _navigateToEditProfile(profile) : null,
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
    final allMedia = [
      ..._uploadedImages.map((file) => FileImage(file) as ImageProvider),
      ...mediaUrls.map((path) => AssetImage(path) as ImageProvider),
    ];

    if (allMedia.isEmpty) {
      return Container(
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
              'Add some photos to showcase yourself!',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
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
              final isUploaded = index < _uploadedImages.length;
              return Stack(
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      image: DecorationImage(
                        image: allMedia[index],
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  if (isUploaded)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _uploadedImages.removeAt(index);
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 12),
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

  Future<void> _pickImage() async {
    if (_uploadedImages.length + mediaUrls.length >= 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can only upload up to 6 total photos.')),
      );
      return;
    }

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _uploadedImages.add(File(pickedFile.path));
      });
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
