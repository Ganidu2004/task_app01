import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_app/constants.dart';
import 'package:task_app/main.dart';
import 'package:task_app/user/forget_password.dart';
import 'package:task_app/user/loging_page.dart';
import 'package:task_app/widgets/bottom_nav_bar.dart';
import 'auth_services.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController(); // Added Phone Controller
  final _passwordController = TextEditingController();
  final _confirmPasswordController =
      TextEditingController(); // Added Confirm Password Controller

  final AuthService _authService = AuthService();
  bool _isLoading = false;

  // Image Picker variables
  File? _imageFile;
  Uint8List? _webImageBytes;
  final ImagePicker _picker = ImagePicker();

  // Function to pick image from gallery
  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      if (kIsWeb) {
        var bytes = await pickedFile.readAsBytes();
        setState(() {
          _webImageBytes = bytes;
        });
      } else {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    }
  }

  // Function to upload image to Cloudinary
  Future<String?> _uploadToCloudinary() async {
  try {
    CloudinaryResponse? response;

    if (kIsWeb || (_imageFile == null && _webImageBytes == null)) {
      Uint8List imageBytes;
      String identifierName;

      if (_imageFile == null && _webImageBytes == null) {
        final ByteData byteData = await rootBundle.load('assets/user.webp');
        imageBytes = byteData.buffer.asUint8List();
        identifierName = 'default_profile_${DateTime.now().millisecondsSinceEpoch}.png';
      } else {
        imageBytes = _webImageBytes!;
        identifierName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      }

      response = await cloudinary.uploadFile(
        CloudinaryFile.fromBytesData(
          imageBytes,
          identifier: identifierName,
          folder: 'profile_images',
          resourceType: CloudinaryResourceType.Image,
        ),
      );
    } else {
      response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          _imageFile!.path,
          identifier: 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg', 
          folder: 'profile_images',
          resourceType: CloudinaryResourceType.Image,
        ),
      );
    }

    return response.secureUrl;
  } catch (e) {
    debugPrint('Cloudinary Error: $e');
    rethrow;
  }
}

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Upload image to Cloudinary first (if selected)
      String? imageUrl;
        try {
          imageUrl = await _uploadToCloudinary();
        } catch (uploadError) {
          debugPrint('Image upload error: $uploadError');
          if (mounted) {
            AppConstants.showCustomSnackBar(
            context, 
            'Failed to upload image: $uploadError', 
            isError: true,
          );
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }

      // 2. Register user and pass the profile image URL to auth service / Firestore
      await _authService.registerUser(
        profileImageUrl: imageUrl,
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        password: _passwordController.text.trim(),
      );

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);

      if (mounted) {
        AppConstants.showCustomSnackBar(context, 'Registration Successful!');
        _nameController.clear();
        _emailController.clear();
        _phoneController.clear();
        _passwordController.clear();
        _confirmPasswordController.clear();

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const BottomNavBar()),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = 'An error occurred';
      if (e.code == 'weak-password') {
        message = 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        message = 'An account already exists for that email.';
      } else if (e.code == 'invalid-email') {
        message = 'The email address is not valid.';
      }

      if (mounted) {
        AppConstants.showCustomSnackBar(context, message, isError: true);
      }
    } catch (e) {
      if (mounted) {
        AppConstants.showCustomSnackBar(context, e.toString(), isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Register Page',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.lightBlue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20),
                const Text(
                  'Create Account',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                //Profile Image Picker Widget
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage: _imageFile != null
                            ? FileImage(_imageFile!)
                            : (_webImageBytes != null
                                  ? MemoryImage(_webImageBytes!)
                                        as ImageProvider
                                  : null),
                        child: (_imageFile == null && _webImageBytes == null)
                            ? const Icon(
                                Icons.person,
                                size: 50,
                                color: Colors.grey,
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          backgroundColor: Colors.lightBlue,
                          radius: 18,
                          child: IconButton(
                            icon: const Icon(
                              Icons.camera_alt,
                              size: 18,
                              color: Colors.white,
                            ),
                            onPressed: _pickImage,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Full Name Field
                TextFormField(
                  controller: _nameController,
                  decoration: AppDecorations.authInputDecoration(
                    labelText: 'Full Name', 
                    prefixIcon: Icons.person
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your full name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Email Field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: AppDecorations.authInputDecoration(
                    labelText: 'Email Address', 
                    prefixIcon: Icons.email
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!RegExp(
                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                    ).hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Phone Number Field (NEW)
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: AppDecorations.authInputDecoration(
                    labelText: 'Phone Number', 
                    prefixIcon: Icons.phone
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your phone number';
                    }
                    if (value.trim().length < 10) {
                      return 'Please enter a valid phone number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Password Field
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: AppDecorations.authInputDecoration(
                    labelText: 'Password', 
                    prefixIcon: Icons.lock
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Confirm Password Field (NEW)
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: AppDecorations.authInputDecoration(
                    labelText: 'Confirm Password', 
                    prefixIcon: Icons.lock_outline
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ForgotPasswordScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(color: Colors.lightBlue),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.lightBlue,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _isLoading ? null : _handleRegister,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Register',
                            style: TextStyle(fontSize: 18),
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Already have an account?"),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginPage(),
                          ),
                        );
                      },
                      child: const Text(
                        'Login',
                        style: TextStyle(color: Colors.lightBlue),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
