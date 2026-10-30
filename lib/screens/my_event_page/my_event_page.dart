import 'package:flutter/material.dart';

class MyEventPage extends StatefulWidget {
  const MyEventPage({super.key});

  @override
  State<MyEventPage> createState() => _MyEventPageState();
}

class _MyEventPageState extends State<MyEventPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Event Page'), centerTitle: true),
      body: Column(
        children: [
          Center(child: Text('My Event Screen', style: TextStyle(fontSize: 24))),
        ],
      ),
    );
  }
}