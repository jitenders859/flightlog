// lib/providers/schedule_provider.dart

import 'package:flutter/material.dart';
import 'package:navlog/dummy_data/dummy_my_scedule.dart';
import 'package:navlog/models/student_scedule.dart';
import 'package:navlog/services/shedule_service.dart';
import 'dart:async';

class ScheduleProvider extends ChangeNotifier {
  final ScheduleService _scheduleService = ScheduleService();

  List<ScheduleEvent> _events = [];
  List<ScheduleEvent> get events => _events;

  DateTime _selectedDate = DateTime(
    2025,
    3,
    24,
  ); // Set to March 24, 2025 to match screenshot
  DateTime get selectedDate => _selectedDate;

  // Set week start to match the screenshot (week of March 24-30, 2025)
  DateTime _weekStartDate = DateTime(2025, 3, 24);
  DateTime get weekStartDate => _weekStartDate;

  bool _isWeekView = true;
  bool get isWeekView => _isWeekView;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  StreamSubscription? _eventsSubscription;

  // Dummy flights for demo
  List<ScheduleEvent> _dummyEvents = [];

  // Initialize with student ID
  void initialize(String studentId, {String studentName = 'Ronit Tiwari'}) {
    // Create dummy flights for demo
    _dummyEvents = [
      DummyDataService.getSampleFlightEvent(
        studentId: studentId,
        studentName: studentName,
      ),
      DummyDataService.getAdditionalFlightEvent(
        studentId: studentId,
        studentName: studentName,
      ),
    ];

    // Add dummy events to the list
    _events = [..._dummyEvents];

    notifyListeners();
  }

  // Toggle between week view and day view
  void toggleView() {
    _isWeekView = !_isWeekView;
    notifyListeners();
  }

  // Set to day view and select a specific date
  void selectDate(String studentId, DateTime date) {
    _selectedDate = date;
    _isWeekView = false;
    notifyListeners();
  }

  // Navigate to next day
  void nextDay(String studentId) {
    _selectedDate = _selectedDate.add(const Duration(days: 1));
    notifyListeners();
  }

  // Navigate to previous day
  void previousDay(String studentId) {
    _selectedDate = _selectedDate.subtract(const Duration(days: 1));
    notifyListeners();
  }

  // Navigate to next week
  void nextWeek(String studentId) {
    _weekStartDate = _weekStartDate.add(const Duration(days: 7));
    notifyListeners();
  }

  // Navigate to previous week
  void previousWeek(String studentId) {
    _weekStartDate = _weekStartDate.subtract(const Duration(days: 7));
    notifyListeners();
  }

  // Get events for a specific day (filtered from events data)
  List<ScheduleEvent> getEventsForDay(DateTime date) {
    return _events.where((event) => event.isOnDate(date)).toList();
  }

  // Add a new event
  Future<void> addEvent(ScheduleEvent event) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // For demo, just add to local list
      _events.add(event);
    } catch (error) {
      _errorMessage = 'Failed to add event: $error';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update an existing event
  Future<void> updateEvent(ScheduleEvent event) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // For demo, update in local list
      final index = _events.indexWhere((e) => e.id == event.id);
      if (index >= 0) {
        _events[index] = event;
      }
    } catch (error) {
      _errorMessage = 'Failed to update event: $error';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete an event
  Future<void> deleteEvent(String eventId, String studentId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // For demo, remove from local list
      _events.removeWhere((event) => event.id == eventId);
    } catch (error) {
      _errorMessage = 'Failed to delete event: $error';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _eventsSubscription?.cancel();
    super.dispose();
  }
}
