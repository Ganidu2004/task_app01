import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel {
  final String id;           // Firestore document ID eka (optional, update/delete waladi godak watinawa)
  final String title;
  final String description;
  final String place;
  final String category;
  final DateTime date;       // Event eka wena dawasa
  final String time;         // Event eka start wena welawa (e.g., "10:30 AM")
  final int maxAttendees;    // Samagama/events walata join wenna puluwan max limit eka
  final String organizerId;  // Event eka create karapu userge UID eka (optional)

  EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.place,
    required this.category,
    required this.date,
    required this.time,
    required this.maxAttendees,
    required this.organizerId,
  });

  // 1. Convert EventModel object into a Map 
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'place': place,
      'category': category,
      'date': Timestamp.fromDate(date),
      'time': time,
      'maxAttendees': maxAttendees,
      'organizerId': organizerId,
    };
  }

  // 2. Convert Firestore DocumentSnapshot / Map back into an EventModel object
  factory EventModel.fromMap(Map<String, dynamic> map, String documentId) {
    return EventModel(
      id: documentId,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      place: map['place'] ?? '',
      category: map['category'] ?? '',
      date: map['date'] != null ? (map['date'] as Timestamp).toDate() : DateTime.now(),
      time: map['time'] ?? '',
      maxAttendees: map['maxAttendees'] ?? 0,
      organizerId: map['organizerId'] ?? '',
    );
  }

  // 3. copyWith method 
  EventModel copyWith({
    String? id,
    String? title,
    String? description,
    String? place,
    String? category,
    DateTime? date,
    String? time,
    int? maxAttendees,
    String? organizerId,
  }) {
    return EventModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      place: place ?? this.place,
      category: category ?? this.category,
      date: date ?? this.date,
      time: time ?? this.time,
      maxAttendees: maxAttendees ?? this.maxAttendees,
      organizerId: organizerId ?? this.organizerId,
    );
  }
}