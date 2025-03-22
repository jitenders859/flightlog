import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../constants/app_constants.dart';
import 'database_service.dart';
import '../models/flight_log_model.dart';
import 'location_service.dart';
import '../location_utils.dart';
import 'notification_service.dart';
import '../models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FlightLogService extends ChangeNotifier {
  final DatabaseService _databaseService;
  final LocationService _locationService;
  final NotificationService _notificationService;

  FlightLogModel? _currentFlightLog;
  Timer? _flightTimer;
  Timer? _proximityTimer;
  String? _currentUserId;

  FlightLogModel? get currentFlightLog => _currentFlightLog;
  bool get hasActiveFlightLog => _currentFlightLog != null;
  Duration get currentFlightDuration =>
      _currentFlightLog != null
          ? DateTime.now().difference(_currentFlightLog!.startTime)
          : Duration.zero;

  FlightLogService({
    required DatabaseService databaseService,
    required LocationService locationService,
    required NotificationService notificationService,
  }) : _databaseService = databaseService,
       _locationService = locationService,
       _notificationService = notificationService;

  Future<void> initialize(String userId) async {
    _currentUserId = userId;
    await _checkForActiveFlightLog();
  }

  Future<void> _checkForActiveFlightLog() async {
    if (_currentUserId == null) return;

    try {
      // Query for active flight logs for the current user
      final activeFlightLogs =
          await _databaseService.getStudentFlightLogs(_currentUserId!).first;

      for (var flightLog in activeFlightLogs) {
        if (flightLog.status == 'in-progress') {
          _currentFlightLog = flightLog;
          _startFlightTracking();
          notifyListeners();
          break;
        }
      }
    } catch (e) {
      print('Error checking for active flight log: $e');
    }
  }

  Future<bool> startFlight({String? teacherId}) async {
    if (_currentUserId == null) return false;
    if (_currentFlightLog != null) return false; // Already has an active flight

    try {
      // Create a new flight log
      String? flightLogId = await _databaseService.createFlightLog(
        studentId: _currentUserId!,
        teacherId: teacherId,
        startTime: DateTime.now(),
      );

      if (flightLogId != null) {
        // Get the created flight log
        _currentFlightLog = await _databaseService.getFlightLog(flightLogId);

        if (_currentFlightLog != null) {
          // Start tracking
          _startFlightTracking();

          notifyListeners();
          return true;
        }
      }

      return false;
    } catch (e) {
      print('Error starting flight: $e');
      return false;
    }
  }

  Future<bool> endFlight({String? notes}) async {
    if (_currentFlightLog == null) return false;

    try {
      // Stop tracking
      _stopFlightTracking();

      // Complete the flight log
      bool completed = await _databaseService.completeFlightLog(
        flightLogId: _currentFlightLog!.id,
        endTime: DateTime.now(),
        notes: notes,
      );

      if (completed) {
        // Update the current flight log
        _currentFlightLog = await _databaseService.getFlightLog(
          _currentFlightLog!.id,
        );

        notifyListeners();
        return true;
      }

      return false;
    } catch (e) {
      print('Error ending flight: $e');
      return false;
    } finally {
      // Ensure tracking is stopped even if there's an error
      _stopFlightTracking();
    }
  }

  void _startFlightTracking() async {
    if (_currentFlightLog == null || _currentUserId == null) return;

    // Start location tracking
    await _locationService.startTracking(flightLogId: _currentFlightLog!.id);

    // Set up flight timer for periodic checks (every 5 minutes)
    _flightTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _checkFlightDuration();
    });

    // Set up proximity timer for checking distance from school (every minute)
    _proximityTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _checkProximityToSchool();
    });

    // Schedule flight alarm for 1 hour before expected end time
    // This is just an example - you may want to adjust based on expected flight duration
    DateTime expectedEndTime = _currentFlightLog!.startTime.add(
      const Duration(hours: 2),
    );

    await _notificationService.scheduleFlightAlarm(
      userId: _currentUserId!,
      flightLogId: _currentFlightLog!.id,
      endTime: expectedEndTime,
    );
  }

  void _stopFlightTracking() {
    // Cancel timers
    _flightTimer?.cancel();
    _flightTimer = null;

    _proximityTimer?.cancel();
    _proximityTimer = null;

    // Stop location tracking
    _locationService.stopTracking();
  }

  void _checkFlightDuration() async {
    if (_currentFlightLog == null || _currentUserId == null) return;

    final duration = DateTime.now().difference(_currentFlightLog!.startTime);

    // If flight has been active for more than 1 hour, send a reminder
    if (duration.inHours >= 1) {
      await _notificationService.sendFlightAlarm(
        userId: _currentUserId!,
        flightLogId: _currentFlightLog!.id,
        body:
            'Your flight has been active for ${duration.inHours} hours. Please consider returning soon.',
      );
    }
  }

  void _checkProximityToSchool() async {
    if (_currentFlightLog == null || _currentUserId == null) return;

    // Get current position
    Position? position = await _locationService.getCurrentPosition();
    if (position == null) return;

    // Get school location
    Map<String, double>? schoolLocation =
        await _databaseService.getSchoolLocation();
    if (schoolLocation == null) return;

    // Calculate distance
    double distance = LocationUtils.calculateDistance(
      position.latitude,
      position.longitude,
      schoolLocation['latitude']!,
      schoolLocation['longitude']!,
    );

    // If distance is greater than the threshold, send a warning
    if (distance > AppConstants.schoolProximityThreshold) {
      String formattedDistance = LocationUtils.formatDistance(distance);

      await _notificationService.sendProximityWarning(
        userId: _currentUserId!,
        flightLogId: _currentFlightLog!.id,
        distanceFromSchool: distance,
        body: 'You are $formattedDistance from school. Please return soon.',
      );
    }
  }

  Future<List<FlightLogModel>> getStudentFlightHistory() async {
    if (_currentUserId == null) return [];

    try {
      return await _databaseService.getStudentFlightLogs(_currentUserId!).first;
    } catch (e) {
      print('Error getting flight history: $e');
      return [];
    }
  }

  Future<List<UserModel>> getAvailableTeachers() async {
    try {
      return await _databaseService.getAllTeachers();
    } catch (e) {
      print('Error getting available teachers: $e');
      return [];
    }
  }

  @override
  void dispose() {
    _stopFlightTracking();
    super.dispose();
  }
}
