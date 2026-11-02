import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:task_app/main.dart';
import 'package:task_app/screens/event_page/event_model_page.dart';
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
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return EventModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // Delete Event Function
  Future<void> deleteEvent(String eventId) async {
    try {
      await _firestore.collection('events').doc(eventId).delete();
    } catch (e) {
      throw Exception('Failed to delete event: $e');
    }
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
