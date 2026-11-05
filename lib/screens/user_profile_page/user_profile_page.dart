import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_app/constants.dart';
import 'package:task_app/database_services.dart';
import 'package:task_app/modles/user_modle.dart';
import 'package:task_app/theme_provider.dart';
import 'package:task_app/user/loging_page.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  // Controllers for editing profile data
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  // Instantiate services
  final DatabaseService _databaseService = DatabaseService();
  final CloudinaryService _cloudinaryService = CloudinaryService();

  String? _profileImageUrl;
  bool _isEditing = false;
  bool _isLoading = true;
  bool _isUploadingImage = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  void logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('isLoggedIn');

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  }

  // Real data fetch from Cloud Firestore using current user UID
  Future<void> _fetchUserData() async {
    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        UserModel? userModel = await _databaseService.getUserData(
          currentUser.uid,
        );

        if (userModel != null) {
          setState(() {
            _nameController.text = userModel.fullName;
            _emailController.text = userModel.email;
            _phoneController.text = userModel.phoneNumber;
            _profileImageUrl = userModel.profileImageUrl;
            _isLoading = false;
          });
        } else {
          setState(() {
            _emailController.text = currentUser.email ?? '';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      AppConstants.showCustomSnackBar(
        context,
        'Error fetching data: $e',
        isError: true,
      );
    }
  }

  // Update profile picture using Cloudinary
  Future<void> _updateProfileImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    setState(() => _isUploadingImage = true);

    try {
      Uint8List? webBytes;
      File? imageFile;

      if (kIsWeb) {
        webBytes = await pickedFile.readAsBytes();
      } else {
        imageFile = File(pickedFile.path);
      }

      // 1. Upload to Cloudinary
      final uploadedUrl = await _cloudinaryService.uploadImage(
        imageFile: imageFile,
        webImageBytes: webBytes,
        folderName: 'profile_images',
        prefixName: 'profile',
      );

      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null && uploadedUrl != null) {
        // 2. Update in Firestore
        await _databaseService.updateUserData(currentUser.uid, {
          'profileImageUrl': uploadedUrl,
        });

        setState(() {
          _profileImageUrl = uploadedUrl;
          _isUploadingImage = false;
        });

        if (mounted) {
          AppConstants.showCustomSnackBar(
            context,
            'Profile picture updated successfully!',
          );
        }
      }
    } catch (e) {
      setState(() => _isUploadingImage = false);
      if (mounted) {
        AppConstants.showCustomSnackBar(
          context,
          'Failed to upload image: $e',
          isError: true,
        );
      }
    }
  }

  // Update profile data in Cloud Firestore
  Future<void> _updateProfileData() async {
    setState(() => _isLoading = true);

    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .update({'fullName': _nameController.text.trim()});

        setState(() {
          _isLoading = false;
          _isEditing = false;
        });

        if (!mounted) return;
        AppConstants.showCustomSnackBar(
          context,
          'Profile updated successfully!',
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      AppConstants.showCustomSnackBar(
        context,
        'Failed to update: $e',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // ThemeProvider eka haraha current theme state eka laba ganeema
    final themeProvider = Provider.of<ThemeProvider>(context);
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: isDarkMode
            ? const Color(0xFF00008B)
            : Colors.lightBlue,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
            ),
            onPressed: () {
              themeProvider.toggleTheme(!themeProvider.isDarkMode);
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.lightBlue),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  // Profile Avatar with Edit Icon badge
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 55,
                        backgroundColor: isDarkMode
                            ? Colors.grey[800]
                            : Colors.grey.shade200,
                        child: CircleAvatar(
                          radius: 52,
                          backgroundColor: Colors.grey.shade200,
                          backgroundImage:
                              (_profileImageUrl != null &&
                                  _profileImageUrl!.isNotEmpty)
                              ? NetworkImage(_profileImageUrl!)
                              : null,
                          child: _isUploadingImage
                              ? const CircularProgressIndicator(
                                  color: Colors.lightBlue,
                                )
                              : ((_profileImageUrl == null ||
                                        _profileImageUrl!.isEmpty)
                                    ? const Icon(
                                        Icons.person,
                                        size: 50,
                                        color: Colors.grey,
                                      )
                                    : null),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.lightBlue,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 20,
                            ),
                            onPressed: _isUploadingImage
                                ? null
                                : _updateProfileImage,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _nameController.text,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _emailController.text,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[400]
                          : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // User Details Form Fields
                  TextField(
                    controller: _nameController,
                    enabled: _isEditing,
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                    decoration: AppDecorations.authInputDecoration(
                      context,
                      labelText: 'Full Name',
                      prefixIcon: Icons.person,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _emailController,
                    enabled: false,
                    style: TextStyle(
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                    decoration: AppDecorations.authInputDecoration(
                      context,
                      labelText: 'Email Address',
                      prefixIcon: Icons.email,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _phoneController,
                    enabled: _isEditing,
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                    decoration: AppDecorations.authInputDecoration(
                      context,
                      labelText: 'Phone Number',
                      prefixIcon: Icons.phone,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Edit / Save Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDarkMode
                            ? const Color(0xFF00008B)
                            : Colors.lightBlue,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        if (_isEditing) {
                          _updateProfileData();
                        } else {
                          setState(() {
                            _isEditing = true;
                          });
                        }
                      },
                      child: Text(
                        _isEditing ? 'Save Changes' : 'Edit Profile',
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Sign Out Button at Bottom
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        backgroundColor: Colors.red.withValues(
                          alpha: isDarkMode ? 0.3 : 0.2,
                        ),
                        side: const BorderSide(color: Colors.red),
                      ),
                      onPressed: () async {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: isDarkMode
                                ? const Color(0xFF1E1E1E)
                                : Colors.white,
                            title: Text(
                              'Sign Out',
                              style: TextStyle(
                                color: isDarkMode
                                    ? Colors.white
                                    : Colors.black87,
                              ),
                            ),
                            content: Text(
                              'Are you sure you want to sign out?',
                              style: TextStyle(
                                color: isDarkMode
                                    ? Colors.grey[300]
                                    : Colors.black87,
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () async {
                                  Navigator.pop(context);
                                  await FirebaseAuth.instance.signOut();
                                  logout();
                                },
                                child: const Text(
                                  'Sign Out',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      icon: const Icon(Icons.logout),
                      label: const Text(
                        'Sign Out',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}
