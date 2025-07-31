import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
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
                backgroundImage: _getAvatarImage(),
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

  ImageProvider _getAvatarImage() {
    // If user selected a new image, show that
    if (_selectedImage != null) {
      return FileImage(_selectedImage!);
    }
    
    // If user has an existing avatar, show that
    if (widget.profile.avatarUrl != null && widget.profile.avatarUrl!.isNotEmpty) {
      final avatarUrl = widget.profile.avatarUrl!;
      
      // Check if it's a local file path (starts with /)
      if (avatarUrl.startsWith('/')) {
        return FileImage(File(avatarUrl));
      }
      
      // Otherwise, treat it as a network URL
      return NetworkImage(avatarUrl);
    }
    
    // Default placeholder
    return const AssetImage('assets/avatar_placeholder.png');
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

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
    );

    if (pickedFile != null) {
      try {
        // Copy image to permanent storage
        final permanentPath = await _copyImageToPermanentLocation(pickedFile.path);
        
        setState(() {
          _selectedImage = File(permanentPath);
        });
      } catch (e) {
        print("❌ [DEBUG] Error picking image: $e");
        // Fallback to original path
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
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

      // Handle avatar upload
      if (_selectedImage != null) {
        // For now, save the local file path
        // In a real app, you'd upload to Firebase Storage and get a URL
        final avatarPath = _selectedImage!.path;
        success &= await profileService.updateAvatarUrl(avatarPath);
      }

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