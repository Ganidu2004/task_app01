import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:task_app/screens/event_page/create_event_page.dart';
import 'package:task_app/screens/explore_page/explore_page.dart';
import 'package:task_app/screens/home_page/home_page.dart';
import 'package:task_app/screens/my_event_page/my_event_page.dart';
import 'package:task_app/screens/user_profile_page/user_profile_page.dart';
import 'package:task_app/user/user_model.dart';

class BottomNavBar extends StatefulWidget {
  final String? userImageUrl;
  const BottomNavBar({super.key, this.userImageUrl});

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  int _currentIndex = 0;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final List<Widget> _pages = [
    const HomePage(),
    const SearchPage(),
    const EventCreatePage(),
    const MyEventPage(),
    const UserProfilePage(),
  ];

  Stream<UserModel?> getUserData() {
    String uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty) return Stream.value(null);

    return _firestore.collection('users').doc(uid).snapshots().map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        return UserModel.fromMap(snapshot.data()!);
      }
      return null;
    });
  }
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UserModel?>(
      stream: getUserData(),
      builder: (context, snapshot) {
        String? profileImageUrl;
        if (snapshot.hasData && snapshot.data != null) {
          profileImageUrl = snapshot.data!.profileImageUrl;
        }
        if ((profileImageUrl == null || profileImageUrl.isEmpty) && 
            widget.userImageUrl != null) {
          profileImageUrl = widget.userImageUrl;
        }

        return Scaffold(
          backgroundColor: Colors.grey[100],
          body: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _pages[_currentIndex],
          ),
          bottomNavigationBar: CurvedNavigationBar(
            backgroundColor: Colors.transparent,
            color: Colors.lightBlue,
            buttonBackgroundColor: Colors.lightBlueAccent,
            height: 60,
            animationDuration: const Duration(milliseconds: 300),
            animationCurve: Curves.easeInOut,
            index: _currentIndex,
            items: <Widget>[
              const Icon(Icons.home, size: 28, color: Colors.white),
              const Icon(Icons.explore, size: 28, color: Colors.white),
              const Icon(Icons.add_circle, size: 32, color: Colors.white),
              const Icon(Icons.event, size: 28, color: Colors.white),
              
              // Dynamic CircleAvatar for User Profile Image
              CircleAvatar(
                radius: 22,
                backgroundColor: Colors.white24,
                backgroundImage: (profileImageUrl != null && profileImageUrl.isNotEmpty)
                    ? NetworkImage(profileImageUrl)
                    : null,
                child: (profileImageUrl == null || profileImageUrl.isEmpty)
                    ? const Icon(Icons.person, size: 20, color: Colors.white)
                    : null,
              ),
            ],
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
          ),
        );
      },
    );
  }
}



