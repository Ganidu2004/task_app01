import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:task_app/main.dart';
import 'package:task_app/modles/comment_modle.dart';
import 'package:task_app/modles/event_modle.dart';
import 'package:task_app/modles/join_event_modle.dart';
import 'package:task_app/modles/user_modle.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream user details from Firestore in real-time
  Stream<UserModel?> streamUserData(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        return UserModel.fromMap(snapshot.data()!);
      }
      return null;
    });
  }

  // Save user details to Firestore
  Future<void> saveUserData(UserModel userModel) async {
    await _firestore
        .collection('users')
        .doc(userModel.uid)
        .set(userModel.toMap());
  }

  // Fetch user details from Firestore by UID
  Future<UserModel?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(uid)
          .get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch user data: $e');
    }
  }

  // Update user profile details in Firestore (e.g., fullName)
  Future<void> updateUserData(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(uid).update(data);
    } catch (e) {
      throw Exception('Failed to update user data: $e');
    }
  }

  // Create and save the event document in Firestore
  Future<void> createEvent(EventModel eventModel) async {
    await _firestore
        .collection('events')
        .doc(eventModel.id)
        .set(eventModel.toMap());
  }

  // Get single event details by ID
  Future<EventModel?> getEventById(String eventId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('events')
          .doc(eventId)
          .get();

      if (doc.exists && doc.data() != null) {
        return EventModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch event details: $e');
    }
  }

  // Stream all events from Firestore in real-time
  Stream<List<EventModel>> streamEvents() {
    return _firestore.collection('events').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return EventModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // Stream events created by a specific user (Current User)
  Stream<List<EventModel>> streamUserEvents(String currentUserId) {
    return _firestore
        .collection('events')
        .where('organizerId', isEqualTo: currentUserId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return EventModel.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }

  // Stream joined participants count for a specific event in real-time
  Stream<int> streamEventParticipantsCount(String eventId) {
    return _firestore
        .collection('event_participants')
        .where('eventId', isEqualTo: eventId)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Edite Event Function
  Future<void> updateEvent(EventModel eventModel) async {
    try {
      await _firestore
          .collection('events')
          .doc(eventModel.id)
          .update(eventModel.toMap());
    } catch (e) {
      throw Exception('Failed to update event: $e');
    }
  }

  // Delete Event Function
  Future<void> deleteEvent(String eventId) async {
    try {
      await _firestore.collection('events').doc(eventId).delete();
    } catch (e) {
      throw Exception('Failed to delete event: $e');
    }
  }

  //Event Join Function
  Future<String> joinEventWithModel({
    required String eventId,
    required String userId,
  }) async {
    try {
      return await _firestore.runTransaction((transaction) async {
        DocumentReference eventRef = _firestore
            .collection('events')
            .doc(eventId);
        DocumentSnapshot eventDoc = await transaction.get(eventRef);

        if (!eventDoc.exists) {
          return 'Event not found';
        }

        Map<String, dynamic> eventData =
            eventDoc.data() as Map<String, dynamic>;
        int maxAttendees = eventData['maxAttendees'] ?? 0;

        QuerySnapshot participantsSnapshot = await _firestore
            .collection('event_participants')
            .where('eventId', isEqualTo: eventId)
            .get();

        int currentAttendeesCount = participantsSnapshot.docs.length;

        bool alreadyJoined = participantsSnapshot.docs.any(
          (doc) => doc['userId'] == userId,
        );
        if (alreadyJoined) {
          return 'You have already joined this event!';
        }

        if (currentAttendeesCount >= maxAttendees) {
          return 'Sorry, this event is full! No more slots available.';
        }

        DocumentReference joinRef = _firestore
            .collection('event_participants')
            .doc();
        EventJoinModel joinModel = EventJoinModel(
          id: joinRef.id,
          eventId: eventId,
          userId: userId,
          joinedAt: DateTime.now(),
        );

        transaction.set(joinRef, joinModel.toMap());

        return 'Successfully joined the event!';
      });
    } catch (e) {
      throw Exception('Failed to join event: $e');
    }
  }

  //Get The Join Event Id
  Stream<List<String>> streamJoinedEventIds(String userId) {
    return _firestore
        .collection('event_participants')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => doc.data()['eventId'].toString())
              .toList();
        });
  }

  Stream<List<EventModel>> streamUserJoinedEvents(String userId) {
    return _firestore
        .collection('event_participants')
        .where('userId', isEqualTo: userId)
        .orderBy('joinedAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          List<EventModel> events = [];
          for (var doc in snapshot.docs) {
            String eventId = doc['eventId'];
            var eventDoc = await _firestore
                .collection('events')
                .doc(eventId)
                .get();
            if (eventDoc.exists) {
              events.add(EventModel.fromMap(eventDoc.data()!, eventDoc.id));
            }
          }
          return events;
        });
  }

  // leave the event method
  Future<void> leaveEvent({
    required String eventId,
    required String userId,
  }) async {
    var querySnapshot = await _firestore
        .collection('event_participants')
        .where('eventId', isEqualTo: eventId)
        .where('userId', isEqualTo: userId)
        .get();

    for (var doc in querySnapshot.docs) {
      await doc.reference.delete();
    }
  }

  //comment save method
  Future<void> addComment({
    required String uid,
    required String eventId,
    required String commentText,
  }) async {
    await _firestore.collection('comments').add({
      'uid': uid,
      'eventId': eventId,
      'commentText': commentText,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  //fetch the comment method
  Stream<List<CommentModel>> streamEventComments(String eventId) {
    return _firestore
        .collection('comments')
        .where('eventId', isEqualTo: eventId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => CommentModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  //delete the comment method
  Future<void> deleteComment(String eventId, String commentId) async {
    try {
      await FirebaseFirestore.instance
          .collection('comments')
          .doc(commentId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete comment: $e');
    }
  }

  Future<int> getRemainingSlots(String eventId, int maxAttendees) async {
    QuerySnapshot participantsSnapshot = await _firestore
        .collection('event_participants')
        .where('eventId', isEqualTo: eventId)
        .get();

    int currentCount = participantsSnapshot.docs.length;
    int remaining = maxAttendees - currentCount;
    return remaining > 0 ? remaining : 0;
  }
}

// Ensure this points to your cloudinary instance/constants

class CloudinaryService {
  // Generic image upload method for both Profile and Event images
  Future<String?> uploadImage({
    File? imageFile,
    Uint8List? webImageBytes,
    required String folderName,
    required String prefixName,
  }) async {
    try {
      CloudinaryResponse? response;

      if (kIsWeb || (imageFile == null && webImageBytes == null)) {
        Uint8List imageBytes;
        String identifierName;

        if (imageFile == null && webImageBytes == null) {
          final ByteData byteData = await rootBundle.load('assets/user.webp');
          imageBytes = byteData.buffer.asUint8List();
          identifierName =
              'default_${prefixName}_${DateTime.now().millisecondsSinceEpoch}.png';
        } else {
          imageBytes = webImageBytes!;
          identifierName =
              '${prefixName}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        }

        response = await cloudinary.uploadFile(
          CloudinaryFile.fromBytesData(
            imageBytes,
            identifier: identifierName,
            folder: folderName,
            resourceType: CloudinaryResourceType.Image,
          ),
        );
      } else {
        response = await cloudinary.uploadFile(
          CloudinaryFile.fromFile(
            imageFile!.path,
            identifier:
                '${prefixName}_${DateTime.now().millisecondsSinceEpoch}.jpg',
            folder: folderName,
            resourceType: CloudinaryResourceType.Image,
          ),
        );
      }

      return response.secureUrl;
    } catch (e) {
      debugPrint('Cloudinary Error: $e');
      rethrow;
    }
  }
}
