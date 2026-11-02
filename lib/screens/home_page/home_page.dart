import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:task_app/constants.dart';
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
            child: StreamBuilder<List<String>>(
              stream: _databaseService.streamJoinedEventIds(currentUserId),
              builder: (context, joinedSnapshot) {
                if (joinedSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final joinedEventIds = joinedSnapshot.data ?? [];

                return StreamBuilder<List<EventModel>>(
                  stream: _databaseService.streamEvents(),
                  builder: (context, eventSnapshot) {
                    if (eventSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (eventSnapshot.hasError) {
                      return Center(
                        child: Text('Error: ${eventSnapshot.error}'),
                      );
                    }
                    if (!eventSnapshot.hasData || eventSnapshot.data!.isEmpty) {
                      return const Center(child: Text('No events found.'));
                    }

                    final allEvents = eventSnapshot.data!;
                    final otherEvents = allEvents.where((event) {
                      bool isOrganizer = event.organizerId == currentUserId;
                      bool isJoined = joinedEventIds.contains(event.id);

                      return !isOrganizer && !isJoined;
                    }).toList();

                    if (otherEvents.isEmpty) {
                      return const Center(
                        child: Text('No other events available to join.'),
                      );
                    }

                    return ListView.builder(
                      itemCount: otherEvents.length,
                      itemBuilder: (context, index) {
                        final event = otherEvents[index];

                        // **මෙතැනදී එක් එක් event එකේ real-time count එක බලලා button එක manage කරනු ලැබේ**
                        return StreamBuilder<int>(
                          stream: _databaseService.streamEventParticipantsCount(
                            event.id,
                          ),
                          builder: (context, countSnapshot) {
                            int joinedCount = countSnapshot.data ?? 0;
                            bool isEventFull =
                                joinedCount >= event.maxAttendees;

                            return EventCard(
                              event: event,
                              databaseService: _databaseService,
                              actionButton: ElevatedButton.icon(
                                onPressed: isEventFull
                                    ? null // Event එක Full නම් button එක disable වේ
                                    : () async {
                                        String message = await _databaseService
                                            .joinEventWithModel(
                                              eventId: event.id,
                                              userId: currentUserId,
                                            );

                                        if (!context.mounted) return;

                                        bool isSuccess = message.contains(
                                          'Successfully',
                                        );

                                        AppConstants.showCustomSnackBar(
                                          context,
                                          message,
                                          isError: !isSuccess,
                                        );
                                      },
                                icon: Icon(
                                  isEventFull ? Icons.block : Icons.person_add,
                                  size: 16,
                                ),
                                label: Text(
                                  isEventFull ? 'Event Full' : 'Join Event',
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isEventFull
                                      ? Colors.grey.shade400
                                      : Colors.lightBlue,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            );
                          },
                        );
                      },
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
