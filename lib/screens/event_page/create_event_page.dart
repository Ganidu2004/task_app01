import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:task_app/constants.dart';
import 'package:task_app/main.dart';
import 'package:task_app/screens/event_page/event_model_page.dart';
import 'package:task_app/widgets/bottom_nav_bar.dart';

class EventCreatePage extends StatefulWidget {
  const EventCreatePage({super.key});

  @override
  State<EventCreatePage> createState() => _EventCreatePageState();
}

class _EventCreatePageState extends State<EventCreatePage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for text fields
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _placeController = TextEditingController();
  final TextEditingController _maxAttendeesController = TextEditingController();

  // Selected values for category, date, and time
  String _selectedCategory = 'Entertainment';
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isLoading = false;
  File? _imageFile;
  Uint8List? _webImageBytes;

  final List<String> _categories = [
    'Entertainment',
    'Technology',
    'Business',
    'Education',
    'Sports',
    'Other',
  ];

  // Image Picker function
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

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

  // Date Picker function
  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(DateTime.now().year + 5),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Colors.lightBlue,
            colorScheme: const ColorScheme.light(primary: Colors.lightBlue),
            buttonTheme: const ButtonThemeData(
              textTheme: ButtonTextTheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // Time Picker function
  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Colors.lightBlue,
            colorScheme: const ColorScheme.light(primary: Colors.lightBlue),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
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
          identifierName = 'default_event_${DateTime.now().millisecondsSinceEpoch}.png';
        } else {
          imageBytes = _webImageBytes!;
          identifierName = 'event_${DateTime.now().millisecondsSinceEpoch}.jpg';
        }

        response = await cloudinary.uploadFile(
          CloudinaryFile.fromBytesData(
            imageBytes,
            identifier: identifierName,
            folder: 'event_images',
            resourceType: CloudinaryResourceType.Image,
          ),
        );
      } else {
        response = await cloudinary.uploadFile(
          CloudinaryFile.fromFile(
            _imageFile!.path,
            identifier: 'event_${DateTime.now().millisecondsSinceEpoch}.jpg', 
            folder: 'event_images',
            resourceType: CloudinaryResourceType.Image,
          ),
        );
      }

      return response.secureUrl; 
    } catch (e) {
      throw Exception('Cloudinary upload error: $e');
    }
  }

  // Submit and save event to Firestore
  Future<void> _submitEvent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        AppConstants.showCustomSnackBar(context, 'Please login first!', isError: true);
        setState(() => _isLoading = false);
        return;
      }

      // Format time string (e.g., "10:30 AM")
      final String formattedTime = _selectedTime.format(context);

      DocumentReference docRef = FirebaseFirestore.instance
          .collection('events')
          .doc();

      String? imageUrl = await _uploadToCloudinary();

      // Create EventModel instance with auto-saved current user UID
      EventModel newEvent = EventModel(
        id: docRef.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        place: _placeController.text.trim(),
        category: _selectedCategory,
        date: _selectedDate,
        time: formattedTime,
        maxAttendees: int.parse(_maxAttendeesController.text.trim()),
        organizerId: currentUser.uid, 
        imageUrl: imageUrl,
      );

      // Save to Firestore 'events' collection
      await docRef.set(newEvent.toMap());

      setState(() => _isLoading = false);

      if (!mounted) return;
      AppConstants.showCustomSnackBar(context, 'Event created successfully!', isError: false);

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const BottomNavBar()),
        (route) => false,
      );
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      AppConstants.showCustomSnackBar(context, 'Failed to create event: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Event', style: TextStyle(fontWeight: FontWeight.bold),),
        centerTitle: true,
        backgroundColor: Colors.lightBlue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Body Header / Title Section ---
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.lightBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.event_note,
                      color: Colors.lightBlue,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Publish New Event',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Fill in the details to host your event',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: double.infinity,
                    height: 180,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.lightBlue, width: 1.5),
                    ),
                    child: _imageFile != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(_imageFile!, fit: BoxFit.cover),
                          )
                        : _webImageBytes != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.memory(_webImageBytes!, fit: BoxFit.cover),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.add_a_photo, size: 40, color: Colors.lightBlue),
                                  SizedBox(height: 8),
                                  Text(
                                    'Tap to add event banner image',
                                    style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 1. Title Field
              TextFormField(
                controller: _titleController,
                decoration: AppDecorations.authInputDecoration(
                    labelText: 'Event Title', 
                    prefixIcon: Icons.title
                  ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Please enter event title'
                    : null,
              ),
              const SizedBox(height: 16),

              // 2. Description Field
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: AppDecorations.authInputDecoration(
                    labelText: 'Description', 
                    prefixIcon: Icons.description
                  ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Please enter description'
                    : null,
              ),
              const SizedBox(height: 16),

              // 3. Place Field
              TextFormField(
                controller: _placeController,
                decoration: AppDecorations.authInputDecoration(
                    labelText: 'Place / Location', 
                    prefixIcon: Icons.location_on
                  ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Please enter event place'
                    : null,
              ),
              const SizedBox(height: 16),

              // 4. Category Dropdown
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: AppDecorations.authInputDecoration(
                    labelText: 'Category', 
                    prefixIcon: Icons.category
                  ),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value!;
                  });
                },
              ),
              const SizedBox(height: 16),

              // 5 & 6. Date and Time Pickers Row
              Row(
                children: [
                  // Date Picker Button
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Colors.grey),
                      ),
                      onPressed: _pickDate,
                      icon: const Icon(
                        Icons.calendar_today,
                        color: Colors.lightBlue,
                      ),
                      label: Text(
                        "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}",
                        style: const TextStyle(color: Colors.black87),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Time Picker Button
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Colors.grey),
                      ),
                      onPressed: _pickTime,
                      icon: const Icon(
                        Icons.access_time,
                        color: Colors.lightBlue,
                      ),
                      label: Text(
                        _selectedTime.format(context),
                        style: const TextStyle(color: Colors.black87),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 7. Max Attendees Field
              TextFormField(
                controller: _maxAttendeesController,
                keyboardType: TextInputType.number,
                decoration: AppDecorations.authInputDecoration(
                    labelText: 'Max Attendees', 
                    prefixIcon: Icons.group
                  ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter max attendees limit';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.lightBlue,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _isLoading ? null : _submitEvent,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Create Event',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
