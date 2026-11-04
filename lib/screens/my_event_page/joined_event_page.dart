import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:task_app/constants.dart';
import 'package:task_app/database_services.dart';
import 'package:task_app/modles/event_modle.dart';
import 'package:task_app/widgets/event_card.dart';

class MyJoinedEventsScreen extends StatelessWidget {
  final DatabaseService _databaseService = DatabaseService();
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  MyJoinedEventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (currentUserId.isEmpty) {
      return const Center(
        child: Text('Please log in to view your joined events.'),
      );
    }
    return StreamBuilder<List<EventModel>>(
      stream: _databaseService.streamUserJoinedEvents(currentUserId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final joinedEvents = snapshot.data ?? [];

        if (joinedEvents.isEmpty) {
          return const Center(
            child: Text('You haven\'t joined any events yet!'),
          );
        }

        return ListView.builder(
          itemCount: joinedEvents.length,
          itemBuilder: (context, index) {
            final event = joinedEvents[index];

            final DateTime currentDate = DateTime.now();
            final DateTime eventDate = event.date;

            final bool isEventPassed =
                DateTime(
                  eventDate.year,
                  eventDate.month,
                  eventDate.day,
                ).isBefore(
                  DateTime(
                    currentDate.year,
                    currentDate.month,
                    currentDate.day,
                  ),
                );

            return EventCard(
              event: event,
              databaseService: _databaseService,
              actionButton: isEventPassed
                  ? Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text(
                          'Event Completed',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    )
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          bool? confirmLeave = await showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Leave Event'),
                              content: const Text(
                                'Are you sure you want to leave this event?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text(
                                    'Leave',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          );

                          if (confirmLeave == true) {
                            try {
                              await _databaseService.leaveEvent(
                                eventId: event.id,
                                userId: currentUserId,
                              );

                              if (context.mounted) {
                                AppConstants.showCustomSnackBar(
                                  context, 
                                  'Successfully left the event!',
                                  isError: false,
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                AppConstants.showCustomSnackBar(
                                  context, 
                                  'Failed to leave event: $e',
                                  isError: true,
                                );
                              }
                            }
                          }
                        },
                        icon: const Icon(Icons.exit_to_app, size: 16),
                        label: const Text('Leave Event'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
            );
          },
        );
      },
    );
  }
}
