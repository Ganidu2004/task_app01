import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:task_app/database_services.dart';
import 'package:task_app/screens/event_page/event_model_page.dart';
import 'package:task_app/widgets/event_card.dart';

class HomePage extends StatelessWidget {
  HomePage({super.key});

  final DatabaseService _databaseService = DatabaseService();
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Home Page',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.lightBlue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
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
                      size: 38,
                    ),
                  ),
                  const SizedBox(width: 16.0),
                  const Text(
                    'Available Events',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<EventModel>>(
              stream: _databaseService.streamEvents(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No events found.'));
                }

                final allEvents = snapshot.data!;

                // Current user create karapu events arenna anith serama events filter කිරීම
                final otherEvents = allEvents
                    .where((event) => event.organizerId != currentUserId)
                    .toList();

                if (otherEvents.isEmpty) {
                  return const Center(
                    child: Text('No other events available to join.'),
                  );
                }

                return ListView.builder(
                  itemCount: otherEvents.length,
                  itemBuilder: (context, index) {
                    final event = otherEvents[index];
                    return EventCard(
                      event: event,
                      databaseService: _databaseService,
                      actionButton: ElevatedButton.icon(
                        onPressed: () {
                          // Join Button Action
                          print("Joined event: ${event.title}");
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Joined event: ${event.title}'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.person_add, size: 16),
                        label: const Text('Join Event'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.lightBlue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
