import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:task_app/screens/event_page/create_event_page.dart';
import 'package:task_app/screens/explore_page/explore_page.dart';
import 'package:task_app/screens/home_page/home_page.dart';
import 'package:task_app/screens/my_event_page/my_event_page.dart';
import 'package:task_app/screens/user_profile_page/user_profile_page.dart';

class BottomNavBar extends StatefulWidget {
  const BottomNavBar({super.key});

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomePage(),
    const SearchPage(),
    const EventCreatePage(),
    const MyEventPage(),
    const UserProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      // Animated Body Transition
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _pages[_currentIndex],
      ),
      
      // Smooth Animated Bottom Navigation Bar (Light Blue Theme)
      bottomNavigationBar: CurvedNavigationBar(
        backgroundColor: Colors.transparent,
        color: Colors.lightBlue, // Light Blue color for nav bar
        buttonBackgroundColor: Colors.lightBlueAccent, // Highlight color for active button
        height: 60,
        animationDuration: const Duration(milliseconds: 300),
        animationCurve: Curves.easeInOut,
        index: _currentIndex,
        items: const <Widget>[
          Icon(Icons.home, size: 28, color: Colors.white),
          Icon(Icons.explore, size: 28, color: Colors.white),
          Icon(Icons.add_circle, size: 32, color: Colors.white), // Create icon
          Icon(Icons.event, size: 28, color: Colors.white),     // My Event
          Icon(Icons.person, size: 28, color: Colors.white),    // Profile
        ],
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}

