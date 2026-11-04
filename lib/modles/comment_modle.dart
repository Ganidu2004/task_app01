import 'package:cloud_firestore/cloud_firestore.dart';

class CommentModel {
  final String commentId;
  final String uid;
  final String eventId;
  final String commentText;
  final DateTime timestamp;

  CommentModel({
    required this.commentId,
    required this.uid,
    required this.eventId,
    required this.commentText,
    required this.timestamp,
  });

  factory CommentModel.fromMap(Map<String, dynamic> map, String id) {
    return CommentModel(
      commentId: id,
      uid: map['uid'] ?? '',
      eventId: map['eventId'] ?? '',
      commentText: map['commentText'] ?? '',
      timestamp: map['timestamp'] != null
          ? (map['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'eventId': eventId,
      'commentText': commentText,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }
}