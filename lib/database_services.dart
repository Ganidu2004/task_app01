import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:task_app/main.dart';
import 'package:task_app/screens/event_page/event_model_page.dart';
import 'package:task_app/screens/home_page/join_event_modele.dart';
import 'package:task_app/user/user_model.dart';

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
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
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
      DocumentSnapshot eventDoc = await _firestore.collection('events').doc(eventId).get();
      if (!eventDoc.exists) {
        return 'Event not found';
      }
      
      Map<String, dynamic> eventData = eventDoc.data() as Map<String, dynamic>;
      int maxAttendees = eventData['maxAttendees'] ?? 0;

      QuerySnapshot participantsSnapshot = await _firestore
          .collection('event_participants')
          .where('eventId', isEqualTo: eventId)
          .get();

      int currentAttendeesCount = participantsSnapshot.docs.length;

      bool alreadyJoined = participantsSnapshot.docs.any((doc) => doc['userId'] == userId);
      if (alreadyJoined) {
        return 'You have already joined this event!';
      }

      if (currentAttendeesCount >= maxAttendees) {
        return 'Sorry, this event is full! No more slots available.';
      }

      String joinId = _firestore.collection('event_participants').doc().id;
      EventJoinModel joinModel = EventJoinModel(
        id: joinId,
        eventId: eventId,
        userId: userId,
        joinedAt: DateTime.now(),
      );

      await _firestore.collection('event_participants').doc(joinId).set(joinModel.toMap());

      return 'Successfully joined the event!';
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
    required String folderName, // e.g., 'profile_images' or 'event_images'
    required String prefixName, // e.g., 'profile' or 'event'
  }) async {
    try {
      CloudinaryResponse? response;

      if (kIsWeb || (imageFile == null && webImageBytes == null)) {
        Uint8List imageBytes;
        String identifierName;

        if (imageFile == null && webImageBytes == null) {
          final ByteData byteData = await rootBundle.load('assets/user.webp');
          imageBytes = byteData.buffer.asUint8List();
          identifierName = 'default_${prefixName}_${DateTime.now().millisecondsSinceEpoch}.png';
        } else {
          imageBytes = webImageBytes!;
          identifierName = '${prefixName}_${DateTime.now().millisecondsSinceEpoch}.jpg';
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
            identifier: '${prefixName}_${DateTime.now().millisecondsSinceEpoch}.jpg',
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
