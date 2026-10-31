import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_app/constants.dart';
import 'package:task_app/main.dart';
import 'package:task_app/user/loging_page.dart';
import 'package:task_app/user/user_model.dart';

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
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();

        if (userDoc.exists) {
          UserModel userModel = UserModel.fromMap(
            userDoc.data() as Map<String, dynamic>,
          );

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
      CloudinaryResponse response;
      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        response = await cloudinary.uploadFile(
          CloudinaryFile.fromBytesData(
            bytes,
            identifier: 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg',
            folder: 'profile_images',
            resourceType: CloudinaryResourceType.Image,
          ),
        );
      } else {
        response = await cloudinary.uploadFile(
          CloudinaryFile.fromFile(
            pickedFile.path,
            identifier: 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg',
            folder: 'profile_images',
            resourceType: CloudinaryResourceType.Image,
          ),
        );
      }

      final uploadedUrl = response.secureUrl;
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .update({'profileImageUrl': uploadedUrl});

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
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.lightBlue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.light_mode),
            onPressed: () {
              // Dark mode functionality removed
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
                        backgroundColor: Colors.lightBlueAccent,
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
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _emailController.text,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 30),

                  // User Details Form Fields
                  TextField(
                    controller: _nameController,
                    enabled: _isEditing,
                    decoration: AppDecorations.authInputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: Icons.person,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _emailController,
                    enabled: false,
                    decoration: AppDecorations.authInputDecoration(
                      labelText: 'Email Address',
                      prefixIcon: Icons.email,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _phoneController,
                    enabled: _isEditing,
                    decoration: AppDecorations.authInputDecoration(
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
                        backgroundColor: Colors.lightBlue,
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
                        backgroundColor: Colors.red.withValues(alpha: 0.2),
                        side: const BorderSide(color: Colors.red),
                      ),
                      onPressed: () async {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Sign Out'),
                            content: const Text(
                              'Are you sure you want to sign out?',
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
