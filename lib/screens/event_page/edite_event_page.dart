import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:task_app/constants.dart';
import 'package:task_app/database_services.dart';
import 'package:task_app/screens/event_page/event_model_page.dart';
import 'package:task_app/widgets/bottom_nav_bar.dart';

class EventEditPage extends StatefulWidget {
  final EventModel event;

  const EventEditPage({super.key, required this.event});

  @override
  State<EventEditPage> createState() => _EventEditPageState();
}

class _EventEditPageState extends State<EventEditPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for text fields
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _placeController;
  late TextEditingController _maxAttendeesController;

  // Instantiate the services
  final DatabaseService _eventService = DatabaseService();
  final CloudinaryService _cloudinaryService = CloudinaryService();

  // Selected values (initialize with existing event data)
  late String _selectedCategory;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;

  bool _isLoading = false;
  File? _imageFile;
  Uint8List? _webImageBytes;
  late String? _existingImageUrl;

  final List<String> _categories = [
    'Entertainment',
    'Technology',
    'Business',
    'Education',
    'Sports',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.event.title);
    _descriptionController = TextEditingController(
      text: widget.event.description,
    );
    _placeController = TextEditingController(text: widget.event.place);
    _maxAttendeesController = TextEditingController(
      text: widget.event.maxAttendees.toString(),
    );
    _selectedCategory = widget.event.category;
    _selectedDate = widget.event.date;
    _existingImageUrl = widget.event.imageUrl;
    _selectedTime = _parseTimeOfDay(widget.event.time);
  }

  TimeOfDay _parseTimeOfDay(String timeString) {
    try {
      final format = DateFormat.jm();
      final parsedDate = format.parse(timeString);
      return TimeOfDay.fromDateTime(parsedDate);
    } catch (e) {
      return TimeOfDay.now();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _placeController.dispose();
    _maxAttendeesController.dispose();
    super.dispose();
  }

  // Image Picker function
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      if (kIsWeb) {
        var bytes = await pickedFile.readAsBytes();
        setState(() {
          _webImageBytes = bytes;
          _imageFile = null;
        });
      } else {
        setState(() {
          _imageFile = File(pickedFile.path);
          _webImageBytes = null;
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

  // Update and save changes to Firestore
  Future<void> _updateEvent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final String formattedTime = _selectedTime.format(context);
      String? imageUrl = _existingImageUrl;

      if (_imageFile != null || _webImageBytes != null) {
        imageUrl = await _cloudinaryService.uploadImage(
          imageFile: _imageFile,
          webImageBytes: _webImageBytes,
          folderName: 'event_images',
          prefixName: 'event',
        );
      }

      EventModel updatedEvent = widget.event.copyWith(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        place: _placeController.text.trim(),
        category: _selectedCategory,
        date: _selectedDate,
        time: formattedTime,
        maxAttendees: int.parse(_maxAttendeesController.text.trim()),
        imageUrl: imageUrl,
      );

      await _eventService.updateEvent(updatedEvent);

      setState(() => _isLoading = false);

      if (!mounted) return;
      AppConstants.showCustomSnackBar(
        context,
        'Event updated successfully!',
        isError: false,
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const BottomNavBar()),
        (route) => false,
      );
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      AppConstants.showCustomSnackBar(
        context,
        'Failed to update event: $e',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Edit Event',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
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
              // Image Picker Section
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
                            child: Image.memory(
                              _webImageBytes!,
                              fit: BoxFit.cover,
                            ),
                          )
                        : (_existingImageUrl != null &&
                              _existingImageUrl!.isNotEmpty)
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              _existingImageUrl!,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(
                                Icons.add_a_photo,
                                size: 40,
                                color: Colors.lightBlue,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Tap to change event banner image',
                                style: TextStyle(
                                  color: Colors.black54,
                                  fontWeight: FontWeight.w500,
                                ),
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
                  prefixIcon: Icons.title,
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
                  prefixIcon: Icons.description,
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
                  prefixIcon: Icons.location_on,
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
                  prefixIcon: Icons.category,
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
                  prefixIcon: Icons.group,
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

              // Update Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.lightBlue,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _isLoading ? null : _updateEvent,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Update Event',
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
