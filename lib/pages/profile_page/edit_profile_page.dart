import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../models/user_profile.dart';
import '../../../services/profile_service.dart';

class EditProfilePage extends StatefulWidget {
  final UserProfile profile;

  const EditProfilePage({
    super.key,
    required this.profile,
  });

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  
  final Map<String, TextEditingController> _socialControllers = {};
  final List<String> _availablePlatforms = [
    'instagram', 'twitch', 'youtube', 'twitter', 'tiktok', 'discord', 'website'
  ];
  
  File? _selectedImage;
  bool _isLoading = false;
  bool _isUsernameAvailable = true;
  String? _usernameError;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.profile.name;
    _usernameController.text = widget.profile.username;
    _bioController.text = widget.profile.bio ?? '';
    
    // Initialize social link controllers
    for (final platform in _availablePlatforms) {
      _socialControllers[platform] = TextEditingController(
        text: widget.profile.getSocialLink(platform) ?? '',
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    for (final controller in _socialControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFB74D),
        title: const Text(
          'Edit Profile',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveProfile,
              child: const Text(
                'Save',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAvatarSection(),
              const SizedBox(height: 30),
              _buildBasicInfoSection(),
              const SizedBox(height: 30),
              _buildSocialLinksSection(),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarSection() {
    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 60,
                backgroundImage: _selectedImage != null
                    ? FileImage(_selectedImage!)
                    : (widget.profile.avatarUrl != null
                        ? NetworkImage(widget.profile.avatarUrl!) as ImageProvider
                        : const AssetImage('assets/avatar_placeholder.png')),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFB74D),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _pickImage,
            child: const Text(
              'Change Photo',
              style: TextStyle(
                color: Color(0xFFFFB74D),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Basic Information',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Display Name',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.person),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter your name';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _usernameController,
          decoration: InputDecoration(
            labelText: 'Username',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.alternate_email),
            errorText: _usernameError,
            suffixIcon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : null,
          ),
          onChanged: _checkUsernameAvailability,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a username';
            }
            if (value.length < 3) {
              return 'Username must be at least 3 characters';
            }
            if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
              return 'Username can only contain letters, numbers, and underscores';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _bioController,
          decoration: const InputDecoration(
            labelText: 'Bio',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.description),
            hintText: 'Tell us about yourself...',
          ),
          maxLines: 3,
          maxLength: 200,
        ),
      ],
    );
  }

  Widget _buildSocialLinksSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Social Links',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),
        ..._availablePlatforms.map((platform) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: TextFormField(
              controller: _socialControllers[platform],
              decoration: InputDecoration(
                labelText: _getPlatformLabel(platform),
                border: const OutlineInputBorder(),
                prefixIcon: Icon(_getPlatformIcon(platform)),
                hintText: 'https://${platform}.com/yourusername',
              ),
              keyboardType: TextInputType.url,
            ),
          );
        }).toList(),
      ],
    );
  }

  String _getPlatformLabel(String platform) {
    switch (platform) {
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

  IconData _getPlatformIcon(String platform) {
    switch (platform) {
      case 'instagram':
        return Icons.camera_alt;
      case 'twitch':
        return Icons.tv;
      case 'youtube':
        return Icons.play_circle;
      case 'twitter':
        return Icons.flutter_dash;
      case 'tiktok':
        return Icons.music_note;
      case 'discord':
        return Icons.chat;
      case 'website':
        return Icons.language;
      default:
        return Icons.link;
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
    );

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _checkUsernameAvailability(String username) async {
    if (username.length < 3) {
      setState(() {
        _usernameError = null;
        _isUsernameAvailable = true;
      });
      return;
    }

    if (username == widget.profile.username) {
      setState(() {
        _usernameError = null;
        _isUsernameAvailable = true;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _usernameError = null;
    });

    try {
      final isAvailable = await ProfileService().isUsernameAvailable(username);
      setState(() {
        _isUsernameAvailable = isAvailable;
        _usernameError = isAvailable ? null : 'Username is already taken';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_isUsernameAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose a different username')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final profileService = ProfileService();
      bool success = true;

      // Update basic info
      success &= await profileService.updateName(_nameController.text.trim());
      success &= await profileService.updateUsername(_usernameController.text.trim());
      success &= await profileService.updateBio(_bioController.text.trim());

      // Update social links
      final socialLinks = <String, String>{};
      for (final entry in _socialControllers.entries) {
        final url = entry.value.text.trim();
        if (url.isNotEmpty) {
          socialLinks[entry.key] = url;
        }
      }
      success &= await profileService.updateSocialLinks(socialLinks);

      // TODO: Handle avatar upload to Firebase Storage
      // For now, we'll skip avatar upload

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully!')),
          );
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to update profile. Please try again.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
} 