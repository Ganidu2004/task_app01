import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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

  final List<String> _categories = [
    'Entertainment',
    'Technology',
    'Business',
    'Education',
    'Sports',
    'Other',
  ];

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

  // Submit and save event to Firestore
  Future<void> _submitEvent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please login first!'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
        return;
      }

      // Format time string (e.g., "10:30 AM")
      final String formattedTime = _selectedTime.format(context);

      DocumentReference docRef = FirebaseFirestore.instance
          .collection('events')
          .doc();

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
        organizerId: currentUser.uid, // Auto-saved current user UID!
      );

      // Save to Firestore 'events' collection
      await docRef.set(newEvent.toMap());

      setState(() => _isLoading = false);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Event created successfully!'),
          backgroundColor: Colors.lightBlue,
        ),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const BottomNavBar()),
        (route) => false,
      );
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create event: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Event'),
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

              // 1. Title Field
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Event Title',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title, color: Colors.lightBlue),
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
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description, color: Colors.lightBlue),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Please enter description'
                    : null,
              ),
              const SizedBox(height: 16),

              // 3. Place Field
              TextFormField(
                controller: _placeController,
                decoration: const InputDecoration(
                  labelText: 'Place / Location',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on, color: Colors.lightBlue),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Please enter event place'
                    : null,
              ),
              const SizedBox(height: 16),

              // 4. Category Dropdown
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category, color: Colors.lightBlue),
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
                decoration: const InputDecoration(
                  labelText: 'Max Attendees',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.group, color: Colors.lightBlue),
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
