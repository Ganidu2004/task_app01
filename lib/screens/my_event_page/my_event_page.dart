import 'package:flutter/material.dart';
import 'package:task_app/screens/my_event_page/created_event_page.dart';
import 'package:task_app/screens/my_event_page/joined_event_page.dart';

class MyEventPage extends StatefulWidget {
  const MyEventPage({super.key});

  @override
  State<MyEventPage> createState() => _MyEventPageState();
}

class _MyEventPageState extends State<MyEventPage> {
  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'My Events',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          backgroundColor: isDarkMode
              ? const Color(0xFF00008B)
              : Colors.lightBlue,
          foregroundColor: Colors.white,
        ),
        body: Column(
          children: [
            // TabBar with Padding and Light Blue Styling
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Container(
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? const Color(0xFF00008B)
                      : Colors.lightBlue.shade800,
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
                    Tab(
                      text: 'Created Events',
                      icon: Icon(Icons.edit_calendar),
                    ),
                    Tab(
                      text: 'Joined Events',
                      icon: Icon(Icons.event_available),
                    ),
                  ],
                ),
              ),
            ),

            Expanded(
              child: TabBarView(
                children: [
                  MyCreatedEventsScreen(),
                  // 2. Joined Events Section
                  MyJoinedEventsScreen(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
