import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:task_app/database_services.dart';
import 'package:task_app/screens/event_page/event_model_page.dart';
import 'package:task_app/user/user_model.dart'; 

class EventFeedScreen extends StatelessWidget {
  final DatabaseService _databaseService = DatabaseService();

  EventFeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Events'),
      ),
      body: StreamBuilder<List<EventModel>>(
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

          final events = snapshot.data!;

          return ListView.builder(
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              return EventCard(
                event: event,
                databaseService: _databaseService,
                actionButton: ElevatedButton.icon(
                  onPressed: () {
                    print("Joined event: ${event.title}");
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
    );
  }
}

// Separate Event Card Widget with dynamic Action Button support
class EventCard extends StatelessWidget {
  final EventModel event;
  final DatabaseService databaseService;
  final Widget? actionButton; 

  const EventCard({
    super.key,
    required this.event,
    required this.databaseService,
    this.actionButton, 
  });

  @override
  Widget build(BuildContext context) {
    String formattedDate = DateFormat('dd MMM yyyy').format(event.date);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Event Image
          if (event.imageUrl != null && event.imageUrl!.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(
                event.imageUrl!,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 180,
                  color: Colors.grey[300],
                  child: const Icon(Icons.image_not_supported, size: 50),
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category & Max Attendees Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Chip(
                      label: Text(event.category),
                      backgroundColor: Colors.blue.withValues(alpha: 0.1),
                      labelStyle: const TextStyle(color: Colors.blue),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.group, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text('Max: ${event.maxAttendees}', style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // 2. Title
                Text(
                  event.title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),

                // 3. Place
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.red),
                    const SizedBox(width: 4),
                    Text(event.place, style: const TextStyle(color: Colors.black54)),
                  ],
                ),
                const SizedBox(height: 4),

                // 4. Date and Time
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 16, color: Colors.green),
                    const SizedBox(width: 4),
                    Text('$formattedDate • ${event.time}', style: const TextStyle(color: Colors.black54)),
                  ],
                ),
                const Divider(height: 24),

                // 5. Organizer Profile (User Info from database)
                FutureBuilder<UserModel?>(
                  future: databaseService.getUserData(event.organizerId),
                  builder: (context, userSnapshot) {
                    if (userSnapshot.connectionState == ConnectionState.waiting) {
                      return const Row(
                        children: [
                          CircleAvatar(radius: 16, backgroundColor: Colors.grey),
                          SizedBox(width: 8),
                          Text('Loading organizer...', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      );
                    }

                    final user = userSnapshot.data;
                    final userName = user != null ? user.fullName : 'Unknown User'; 
                    final userImage = user?.profileImageUrl;

                    return Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundImage: userImage != null && userImage.isNotEmpty
                              ? NetworkImage(userImage)
                              : null,
                          child: userImage == null || userImage.isEmpty
                              ? const Icon(Icons.person, size: 18)
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Created by $userName',
                          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                        ),
                      ],
                    );
                  },
                ),

                if (actionButton != null) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: actionButton!,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}