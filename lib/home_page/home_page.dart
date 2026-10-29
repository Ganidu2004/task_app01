import 'package:flutter/material.dart';
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home Page'), centerTitle: true, ),
      body: Column(
        mainAxisAlignment : MainAxisAlignment.center,
        crossAxisAlignment : CrossAxisAlignment.center,
        children : [
          
        ],
      ),
    );
  }
}