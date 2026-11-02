import 'package:flutter/material.dart';
import 'package:task_app/screens/event_page/event_model_page.dart';
import 'package:task_app/screens/my_event_page/created_event_page.dart';

class MyEventPage extends StatefulWidget {
  const MyEventPage({super.key});

  @override
  State<MyEventPage> createState() => _MyEventPageState();
}

class _MyEventPageState extends State<MyEventPage> {
  final List<EventModel> joinedEvents = [];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'My Events',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          backgroundColor: Colors.lightBlue,
          foregroundColor: Colors.white,
        ),
        body: Column(
          children: [
            // TabBar with Padding and Light Blue Styling
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.lightBlue.shade800,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: Colors.lightBlueAccent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  tabs: const [
                    Tab(text: 'Created Events', icon: Icon(Icons.edit_calendar)),
                    Tab(text: 'Joined Events', icon: Icon(Icons.event_available)),
                  ],
                ),
              ),
            ),
            
            Expanded(
              child: TabBarView(
                children: [
                  MyCreatedEventsScreen(),
                  // 2. Joined Events Section
                  _buildEventList(joinedEvents, "You haven't joined any events yet!"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventList(List<EventModel> events, String emptyMessage) {
    if (events.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            emptyMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return Text(event.title); 
      },
    );
  }
}