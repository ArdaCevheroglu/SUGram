import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/event_model.dart';

class EventService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Create a new event
  Future<EventModel> createEvent({
    required String title,
    required String description,
    required DateTime startTime,
    required DateTime endTime,
    required String location,
    required String organizer,
    required String organizerId,
    required String category,
    File? imageFile,
  }) async {
    try {
      String imageUrl = '';

      // Upload image to Firebase Storage if provided
      if (imageFile != null) {
        String fileName = '${DateTime.now().millisecondsSinceEpoch}_$organizerId';
        Reference storageRef =
            _storage.ref().child('events').child('$fileName.jpg');

        UploadTask uploadTask = storageRef.putFile(imageFile);
        TaskSnapshot taskSnapshot = await uploadTask;
        imageUrl = await taskSnapshot.ref.getDownloadURL();
      }

      // Create event document reference
      DocumentReference eventRef = _firestore.collection('events').doc();

      // Create event object
      EventModel event = EventModel(
        id: eventRef.id,
        title: title,
        description: description,
        startTime: startTime,
        endTime: endTime,
        location: location,
        organizer: organizer,
        organizerId: organizerId,
        imageUrl: imageUrl,
        category: category,
      );

      // Save event to Firestore
      await eventRef.set(event.toJson());

      return event;
    } catch (e) {
      rethrow;
    }
  }

  // Get all upcoming events
  Future<List<EventModel>> getUpcomingEvents() async {
    try {
      QuerySnapshot eventSnapshot = await _firestore
          .collection('events')
          .where('startTime', isGreaterThanOrEqualTo: Timestamp.now())
          .orderBy('startTime')
          .get();

      List<EventModel> events = eventSnapshot.docs
          .map((doc) => EventModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();

      return events;
    } catch (e) {
      rethrow;
    }
  }

  // Get events by category
  Future<List<EventModel>> getEventsByCategory(String category) async {
    try {
      QuerySnapshot eventSnapshot = await _firestore
          .collection('events')
          .where('category', isEqualTo: category)
          .where('startTime', isGreaterThanOrEqualTo: Timestamp.now())
          .orderBy('startTime')
          .get();

      List<EventModel> events = eventSnapshot.docs
          .map((doc) => EventModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();

      return events;
    } catch (e) {
      rethrow;
    }
  }

  // Get events organized by a user
  Future<List<EventModel>> getUserEvents(String userId) async {
    try {
      QuerySnapshot eventSnapshot = await _firestore
          .collection('events')
          .where('organizerId', isEqualTo: userId)
          .orderBy('startTime', descending: true)
          .get();

      List<EventModel> events = eventSnapshot.docs
          .map((doc) => EventModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();

      return events;
    } catch (e) {
      rethrow;
    }
  }

  // Get a single event by ID
  Future<EventModel?> getEventById(String eventId) async {
    try {
      DocumentSnapshot eventSnapshot =
          await _firestore.collection('events').doc(eventId).get();

      if (!eventSnapshot.exists) return null;

      return EventModel.fromJson(
          eventSnapshot.data() as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  // Mark user as attending an event
  Future<void> attendEvent(String eventId, String userId) async {
    try {
      await _firestore.collection('events').doc(eventId).update({
        'attendees': FieldValue.arrayUnion([userId])
      });
    } catch (e) {
      rethrow;
    }
  }

  // Remove user from attending an event
  Future<void> cancelAttendance(String eventId, String userId) async {
    try {
      await _firestore.collection('events').doc(eventId).update({
        'attendees': FieldValue.arrayRemove([userId])
      });
    } catch (e) {
      rethrow;
    }
  }

  // Mark user as interested in an event
  Future<void> markInterested(String eventId, String userId) async {
    try {
      await _firestore.collection('events').doc(eventId).update({
        'interestedUsers': FieldValue.arrayUnion([userId])
      });
    } catch (e) {
      rethrow;
    }
  }

  // Remove user from interested list
  Future<void> removeInterest(String eventId, String userId) async {
    try {
      await _firestore.collection('events').doc(eventId).update({
        'interestedUsers': FieldValue.arrayRemove([userId])
      });
    } catch (e) {
      rethrow;
    }
  }

  // Update an event
  Future<void> updateEvent(EventModel event) async {
    try {
      await _firestore
          .collection('events')
          .doc(event.id)
          .update(event.toJson());
    } catch (e) {
      rethrow;
    }
  }

  // Delete an event
  Future<void> deleteEvent(String eventId) async {
    try {
      // Get the event to access the image URL
      DocumentSnapshot eventSnapshot =
          await _firestore.collection('events').doc(eventId).get();
      
      if (!eventSnapshot.exists) return;

      EventModel event =
          EventModel.fromJson(eventSnapshot.data() as Map<String, dynamic>);

      // Delete event document from Firestore
      await _firestore.collection('events').doc(eventId).delete();

      // Delete event image from Storage if it exists
      if (event.imageUrl.isNotEmpty) {
        try {
          await _storage.refFromURL(event.imageUrl).delete();
        } catch (e) {
          // Ignore if image doesn't exist
        }
      }
    } catch (e) {
      rethrow;
    }
  }
}