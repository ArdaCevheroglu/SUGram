import 'package:flutter/material.dart';
import 'dart:io';
import '../services/event_service.dart';
import '../models/event_model.dart';

class EventViewModel extends ChangeNotifier {
  final EventService _eventService = EventService();
  
  List<EventModel> _upcomingEvents = [];
  List<EventModel> _userEvents = [];
  EventModel? _selectedEvent;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<EventModel> get upcomingEvents => _upcomingEvents;
  List<EventModel> get userEvents => _userEvents;
  EventModel? get selectedEvent => _selectedEvent;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Create a new event
  Future<bool> createEvent({
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
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      EventModel event = await _eventService.createEvent(
        title: title,
        description: description,
        startTime: startTime,
        endTime: endTime,
        location: location,
        organizer: organizer,
        organizerId: organizerId,
        category: category,
        imageFile: imageFile,
      );

      // Add to user events
      _userEvents.insert(0, event);
      
      // Add to upcoming events if applicable
      if (event.startTime.isAfter(DateTime.now())) {
        _upcomingEvents.add(event);
        _upcomingEvents.sort((a, b) => a.startTime.compareTo(b.startTime));
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Get all upcoming events
  Future<void> getUpcomingEvents() async {
    if (_isLoading) return;
    
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _upcomingEvents = await _eventService.getUpcomingEvents();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get events by category
  Future<List<EventModel>> getEventsByCategory(String category) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      List<EventModel> events = await _eventService.getEventsByCategory(category);
      _isLoading = false;
      notifyListeners();
      return events;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return [];
    }
  }

  // Get events organized by a user
  Future<void> getUserEvents(String userId) async {
    if (_isLoading) return;
    
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _userEvents = await _eventService.getUserEvents(userId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get a single event by ID
  Future<void> getEventById(String eventId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _selectedEvent = await _eventService.getEventById(eventId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Attend an event
  Future<bool> attendEvent(String eventId, String userId) async {
    try {
      await _eventService.attendEvent(eventId, userId);

      // Update event in lists
      _updateEventAttendance(eventId, userId, true);

      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Cancel attendance for an event
  Future<bool> cancelAttendance(String eventId, String userId) async {
    try {
      await _eventService.cancelAttendance(eventId, userId);

      // Update event in lists
      _updateEventAttendance(eventId, userId, false);

      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Mark interest in an event
  Future<bool> markInterested(String eventId, String userId) async {
    try {
      await _eventService.markInterested(eventId, userId);

      // Update event in lists
      _updateEventInterest(eventId, userId, true);

      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Remove interest from an event
  Future<bool> removeInterest(String eventId, String userId) async {
    try {
      await _eventService.removeInterest(eventId, userId);

      // Update event in lists
      _updateEventInterest(eventId, userId, false);

      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Update an event
  Future<bool> updateEvent(EventModel event) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _eventService.updateEvent(event);

      // Update event in lists
      _updateEventInLists(event);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Delete an event
  Future<bool> deleteEvent(String eventId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _eventService.deleteEvent(eventId);

      // Remove from lists
      _upcomingEvents.removeWhere((event) => event.id == eventId);
      _userEvents.removeWhere((event) => event.id == eventId);
      if (_selectedEvent?.id == eventId) {
        _selectedEvent = null;
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Helper method to update event attendance in lists
  void _updateEventAttendance(String eventId, String userId, bool attending) {
    // Update in upcoming events
    for (int i = 0; i < _upcomingEvents.length; i++) {
      if (_upcomingEvents[i].id == eventId) {
        List<String> updatedAttendees = List.from(_upcomingEvents[i].attendees);
        if (attending) {
          if (!updatedAttendees.contains(userId)) {
            updatedAttendees.add(userId);
          }
        } else {
          updatedAttendees.remove(userId);
        }
        _upcomingEvents[i] = _upcomingEvents[i].copyWith(attendees: updatedAttendees);
        break;
      }
    }

    // Update in user events
    for (int i = 0; i < _userEvents.length; i++) {
      if (_userEvents[i].id == eventId) {
        List<String> updatedAttendees = List.from(_userEvents[i].attendees);
        if (attending) {
          if (!updatedAttendees.contains(userId)) {
            updatedAttendees.add(userId);
          }
        } else {
          updatedAttendees.remove(userId);
        }
        _userEvents[i] = _userEvents[i].copyWith(attendees: updatedAttendees);
        break;
      }
    }

    // Update selected event
    if (_selectedEvent != null && _selectedEvent!.id == eventId) {
      List<String> updatedAttendees = List.from(_selectedEvent!.attendees);
      if (attending) {
        if (!updatedAttendees.contains(userId)) {
          updatedAttendees.add(userId);
        }
      } else {
        updatedAttendees.remove(userId);
      }
      _selectedEvent = _selectedEvent!.copyWith(attendees: updatedAttendees);
    }
  }

  // Helper method to update event interest in lists
  void _updateEventInterest(String eventId, String userId, bool interested) {
    // Update in upcoming events
    for (int i = 0; i < _upcomingEvents.length; i++) {
      if (_upcomingEvents[i].id == eventId) {
        List<String> updatedInterested = List.from(_upcomingEvents[i].interestedUsers);
        if (interested) {
          if (!updatedInterested.contains(userId)) {
            updatedInterested.add(userId);
          }
        } else {
          updatedInterested.remove(userId);
        }
        _upcomingEvents[i] = _upcomingEvents[i].copyWith(interestedUsers: updatedInterested);
        break;
      }
    }

    // Update in user events
    for (int i = 0; i < _userEvents.length; i++) {
      if (_userEvents[i].id == eventId) {
        List<String> updatedInterested = List.from(_userEvents[i].interestedUsers);
        if (interested) {
          if (!updatedInterested.contains(userId)) {
            updatedInterested.add(userId);
          }
        } else {
          updatedInterested.remove(userId);
        }
        _userEvents[i] = _userEvents[i].copyWith(interestedUsers: updatedInterested);
        break;
      }
    }

    // Update selected event
    if (_selectedEvent != null && _selectedEvent!.id == eventId) {
      List<String> updatedInterested = List.from(_selectedEvent!.interestedUsers);
      if (interested) {
        if (!updatedInterested.contains(userId)) {
          updatedInterested.add(userId);
        }
      } else {
        updatedInterested.remove(userId);
      }
      _selectedEvent = _selectedEvent!.copyWith(interestedUsers: updatedInterested);
    }
  }

  // Helper method to update event in lists
  void _updateEventInLists(EventModel updatedEvent) {
    // Update in upcoming events
    for (int i = 0; i < _upcomingEvents.length; i++) {
      if (_upcomingEvents[i].id == updatedEvent.id) {
        _upcomingEvents[i] = updatedEvent;
        break;
      }
    }

    // Update in user events
    for (int i = 0; i < _userEvents.length; i++) {
      if (_userEvents[i].id == updatedEvent.id) {
        _userEvents[i] = updatedEvent;
        break;
      }
    }

    // Update selected event
    if (_selectedEvent != null && _selectedEvent!.id == updatedEvent.id) {
      _selectedEvent = updatedEvent;
    }
  }

  // Clear selected event
  void clearSelectedEvent() {
    _selectedEvent = null;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}