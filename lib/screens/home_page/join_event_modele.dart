import 'package:cloud_firestore/cloud_firestore.dart';

class EventJoinModel {
  final String id;
  final String eventId;
  final String userId;
  final DateTime joinedAt;  

  EventJoinModel({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.joinedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'eventId': eventId,
      'userId': userId,
      'joinedAt': Timestamp.fromDate(joinedAt),
    };
  }

  factory EventJoinModel.fromMap(Map<String, dynamic> map, String documentId) {
    return EventJoinModel(
      id: documentId,
      eventId: map['eventId'] ?? '',
      userId: map['userId'] ?? '',
      joinedAt: map['joinedAt'] != null 
          ? (map['joinedAt'] as Timestamp).toDate() 
          : DateTime.now(),
    );
  }
}