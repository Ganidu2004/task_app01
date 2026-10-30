import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Make sure to import firebase_auth
import 'package:flutter/material.dart';
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

  bool _isEditing = false;
  bool _isLoading = true;
  bool _isDarkMode = false; // Theme switch state

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  // Real data fetch from Cloud Firestore using current user UID
  Future<void> _fetchUserData() async {
    try {
      // 1. Get currently logged in user from Firebase Auth
      final User? currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        // 2. Fetch document from Firestore 'users' collection using UID
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();

        if (userDoc.exists) {
          // 3. Convert document data to UserModel using fromMap factory
          UserModel userModel = UserModel.fromMap(
            userDoc.data() as Map<String, dynamic>,
          );

          setState(() {
            _nameController.text = userModel.fullName;
            _emailController.text = userModel.email;
            // Phone number eka database eke thiyenawanam methanin map karaganna puluwan
            _isLoading = false;
          });
        } else {
          // Document nathnam Auth email eka use karanna
          setState(() {
            _emailController.text = currentUser.email ?? '';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Update profile data in Cloud Firestore
  Future<void> _updateProfileData() async {
    setState(() => _isLoading = true);

    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        // Update user document fields in Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .update({'fullName': _nameController.text.trim()});

        setState(() {
          _isLoading = false;
          _isEditing = false;
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.lightBlue,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _isDarkMode ? ThemeData.dark() : ThemeData.light(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Profile'),
          centerTitle: true,
          backgroundColor: Colors.lightBlue,
          foregroundColor: Colors.white,
          actions: [
            // Dark Mode Switch Button
            IconButton(
              icon: Icon(_isDarkMode ? Icons.dark_mode : Icons.light_mode),
              onPressed: () {
                /*setState(() {
                  _isDarkMode = !_isDarkMode;
                });*/
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
                        const CircleAvatar(
                          radius: 55,
                          backgroundColor: Colors.lightBlueAccent,
                          child: CircleAvatar(
                            radius: 52,
                            backgroundImage: NetworkImage(
                              'https://thumbs.dreamstime.com/b/simple-user-profile-icon-bright-blue-color-isolated-transparent-background-image-shows-basic-contact-rendered-406359700.jpg',
                            ),
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
                              onPressed: () {
                                // Profile picture update logic (Firebase Storage)
                              },
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
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person, color: Colors.lightBlue),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _emailController,
                      enabled:
                          false, // Email eka normally profile eken direct change karanna denne na (security nisa)
                      decoration: const InputDecoration(
                        labelText: 'Email Address',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email, color: Colors.lightBlue),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _phoneController,
                      enabled: _isEditing,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone, color: Colors.lightBlue),
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
                                    if (!context.mounted) return;
                                    // Login Page ekata navigate wela anith okkoma screens stack eken ain karanawa
                                    Navigator.pushAndRemoveUntil(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const LoginPage(), // Oyage Login Page class eka me thanata danna
                                      ),
                                      (route) =>
                                          false, // Previous routes okkoma clear wei
                                    );
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
      ),
    );
  }
}
