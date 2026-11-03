import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:task_app/database_services.dart';
import 'package:task_app/screens/event_page/event_model_page.dart';
import 'package:task_app/user/user_model.dart';

class EventDetailPage extends StatelessWidget {
  final String eventId;
  final DatabaseService databaseService;
  final EventModel? initialEvent;

  const EventDetailPage({
    super.key,
    required this.eventId,
    required this.databaseService,
    this.initialEvent,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: FutureBuilder<EventModel?>(
        future: databaseService.getEventById(eventId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            if (initialEvent != null) {
              return _buildEventContent(context, initialEvent!);
            }
            return const Center(
              child: CircularProgressIndicator(color: Colors.lightBlue),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading event details: ${snapshot.error}'),
            );
          }

          final event = snapshot.data ?? initialEvent;
          if (event == null) {
            return const Center(child: Text('Event details not found.'));
          }
          return _buildEventContent(context, event);
        },
      ),
    );
  }

  Widget _buildEventContent(BuildContext context, EventModel event) {
    return Stack(
      children: [
        // 1. Background Image & Header
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 320,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (event.imageUrl != null && event.imageUrl!.isNotEmpty)
                Image.network(
                  event.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey[300],
                    child: const Icon(
                      Icons.broken_image,
                      size: 60,
                      color: Colors.grey,
                    ),
                  ),
                )
              else
                Container(
                  color: Colors.lightBlue[100],
                  child: const Icon(
                    Icons.event,
                    size: 80,
                    color: Colors.lightBlue,
                  ),
                ),
              // Dark Gradient Overlay for better contrast
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.5),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.2),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // 2. Custom Floating Back Button
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: 16,
          child: CircleAvatar(
            backgroundColor: Colors.white.withValues(alpha: 0.9),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black87),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),

        // 3. Scrollable Details Sheet
        Positioned.fill(
          top: 280,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, -5),
                ),
              ],
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category Chip & Real-time Participants Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.lightBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          event.category,
                          style: const TextStyle(
                            color: Colors.lightBlue,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      // Real-time Joined Count Badge
                      StreamBuilder<int>(
                        stream: databaseService.streamEventParticipantsCount(
                          event.id,
                        ),
                        builder: (context, countSnapshot) {
                          int joinedCount = countSnapshot.data ?? 0;
                          return Row(
                            children: [
                              const Icon(
                                Icons.group,
                                size: 16,
                                color: Colors.orange,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$joinedCount / ${event.maxAttendees} Joined',
                                style: const TextStyle(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Title
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Date, Time & Location Cards Container
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        _buildInfoRow(
                          icon: Icons.calendar_today,
                          iconColor: Colors.green,
                          title: 'Date',
                          value: DateFormat(
                            'EEEE, dd MMM yyyy',
                          ).format(event.date),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 10),
                          child: Divider(height: 1),
                        ),
                        _buildInfoRow(
                          icon: Icons.access_time_rounded,
                          iconColor: Colors.lightBlue,
                          title: 'Time',
                          value: event.time,
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 10),
                          child: Divider(height: 1),
                        ),
                        _buildInfoRow(
                          icon: Icons.location_on_rounded,
                          iconColor: Colors.red,
                          title: 'Location',
                          value: event.place,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Organizer Profile Section
                  FutureBuilder<UserModel?>(
                    future: databaseService.getUserData(event.organizerId),
                    builder: (context, userSnapshot) {
                      final user = userSnapshot.data;
                      final userName = user?.fullName ?? 'Organizer';
                      final userImage = user?.profileImageUrl;

                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.lightBlue.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.lightBlue.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: Colors.lightBlue.withValues(
                                alpha: 0.2,
                              ),
                              backgroundImage:
                                  userImage != null && userImage.isNotEmpty
                                  ? NetworkImage(userImage)
                                  : null,
                              child: userImage == null || userImage.isEmpty
                                  ? const Icon(
                                      Icons.person,
                                      color: Colors.lightBlue,
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Organized by',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  userName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // About Event Description Section
                  const Text(
                    'About Event',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    event.description,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.6,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Helper Widget for structured rows
  Widget _buildInfoRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
