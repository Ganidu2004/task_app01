import 'package:flutter/material.dart';

class EventCreatePage extends StatefulWidget {
  const EventCreatePage({super.key});

  @override
  State<EventCreatePage> createState() => _EventCreatePageState();
}

class _EventCreatePageState extends State<EventCreatePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Event Page'), centerTitle: true),
      body: Column(
        children: [
          Center(child: Text('Event Screen', style: TextStyle(fontSize: 24))),
        ],
      ),
    );
  }
}