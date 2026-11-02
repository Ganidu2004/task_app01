import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:task_app/database_services.dart';
import 'package:task_app/screens/event_page/event_model_page.dart';
import 'package:task_app/widgets/event_card.dart'; 

class MyCreatedEventsScreen extends StatelessWidget {
  final DatabaseService _databaseService = DatabaseService();
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  MyCreatedEventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (currentUserId.isEmpty) {
      return const Center(child: Text('Please log in to view your events.'));
    }

    return StreamBuilder<List<EventModel>>(
      stream: _databaseService.streamUserEvents(currentUserId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text('You haven\'t created any events yet!'),
          );
        }

        final myEvents = snapshot.data!;

        return ListView.builder(
          itemCount: myEvents.length,
          itemBuilder: (context, index) {
            final event = myEvents[index];
            
            return EventCard(
              event: event, 
              databaseService: _databaseService,
              actionButton: Row(
                children: [
                  // 1. Edit Button
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                       
                      },
                      icon: const Icon(Icons.edit, size: 16, color: Colors.blue),
                      label: const Text('Edit', style: TextStyle(color: Colors.blue)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.blue),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  
                  // 2. Delete Button
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        bool? confirmDelete = await showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Event'),
                            content: const Text('Are you sure you want to delete this event?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Delete', style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );

                        if (confirmDelete == true) {
                          try {
                            await _databaseService.deleteEvent(event.id);
                            
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Event deleted successfully!')),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed to delete event: $e')),
                              );
                            }
                          }
                        }
                      },
                      icon: const Icon(Icons.delete, size: 16),
                      label: const Text('Delete'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}