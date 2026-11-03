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

  // --- USER METHODS ---

  Stream<UserModel?> streamUserData(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        return UserModel.fromMap(snapshot.data()!);
      }
      return null;
    });
  }

  Future<void> saveUserData(UserModel userModel) async {
    await _firestore
        .collection('users')
        .doc(userModel.uid)
        .set(userModel.toMap(), SetOptions(merge: true));
  }

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

  Future<void> updateUserData(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(uid).update(data);
    } catch (e) {
      throw Exception('Failed to update user data: $e');
    }
  }

  // --- EVENT METHODS ---

  Future<void> createEvent(EventModel eventModel) async {
    await _firestore
        .collection('events')
        .doc(eventModel.id)
        .set(eventModel.toMap());
  }

  Future<EventModel?> getEventById(String eventId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('events').doc(eventId).get();
      if (doc.exists && doc.data() != null) {
        return EventModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch event details: $e');
    }
  }

  Stream<List<EventModel>> streamEvents() {
    return _firestore.collection('events').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => EventModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Stream<List<EventModel>> streamUserEvents(String currentUserId) {
    return _firestore
        .collection('events')
        .where('organizerId', isEqualTo: currentUserId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => EventModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

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

  Future<void> deleteEvent(String eventId) async {
    try {
      await _firestore.collection('events').doc(eventId).delete();
    } catch (e) {
      throw Exception('Failed to delete event: $e');
    }
  }
  Future<String> joinEventWithModel({
    required String eventId,
    required String userId,
  }) async {
    try {
      return await _firestore.runTransaction((transaction) async {
        DocumentReference eventRef = _firestore.collection('events').doc(eventId);
        DocumentSnapshot eventDoc = await transaction.get(eventRef);

        if (!eventDoc.exists) {
          return 'Event not found';
        }

        Map<String, dynamic> eventData = eventDoc.data() as Map<String, dynamic>;
        int maxAttendees = eventData['maxAttendees'] ?? 0;
        int currentAttendees = eventData['currentAttendees'] ?? 0;

        // Check if user already joined using a composite doc ID: eventId_userId
        DocumentReference joinRef = _firestore
            .collection('event_participants')
            .doc('${eventId}_$userId');
            
        DocumentSnapshot joinDoc = await transaction.get(joinRef);

        if (joinDoc.exists) {
          return 'You have already joined this event!';
        }

        if (currentAttendees >= maxAttendees) {
          return 'Sorry, this event is full! No more slots available.';
        }

        // Save participant
        EventJoinModel joinModel = EventJoinModel(
          id: joinRef.id,
          eventId: eventId,
          userId: userId,
          joinedAt: DateTime.now(),
        );

        transaction.set(joinRef, joinModel.toMap());

        // Increment currentAttendees safely in transaction
        transaction.update(eventRef, {'currentAttendees': currentAttendees + 1});

        return 'Successfully joined the event!';
      });
    } catch (e) {
      throw Exception('Failed to join event: $e');
    }
  }

  // Stream participants count directly from the event document (Zero extra reads!)
  Stream<int> streamEventParticipantsCount(String eventId) {
    return _firestore.collection('events').doc(eventId).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return (doc.data() as Map<String, dynamic>)['currentAttendees'] ?? 0;
      }
      return 0;
    });
  }

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
      if (snapshot.docs.isEmpty) return [];

      List<String> eventIds = snapshot.docs
          .map((doc) => doc.data()['eventId'].toString())
          .toList();
      if (eventIds.isEmpty) return [];
      
      var eventsSnapshot = await _firestore
          .collection('events')
          .where(FieldPath.documentId, whereIn: eventIds)
          .get();

      return eventsSnapshot.docs
          .map((doc) => EventModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Future<void> leaveEvent({
    required String eventId,
    required String userId,
  }) async {
    DocumentReference eventRef = _firestore.collection('events').doc(eventId);
    DocumentReference joinRef = _firestore
        .collection('event_participants')
        .doc('${eventId}_$userId');

    await _firestore.runTransaction((transaction) async {
      DocumentSnapshot joinDoc = await transaction.get(joinRef);
      if (!joinDoc.exists) return;

      DocumentSnapshot eventDoc = await transaction.get(eventRef);
      if (eventDoc.exists) {
        int currentAttendees = (eventDoc.data() as Map<String, dynamic>)['currentAttendees'] ?? 1;
        transaction.update(eventRef, {
          'currentAttendees': currentAttendees > 0 ? currentAttendees - 1 : 0
        });
      }

      transaction.delete(joinRef);
    });
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
