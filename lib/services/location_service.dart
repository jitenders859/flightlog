import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../constants/app_constants.dart';
import '../models/flight_log_model.dart';
import '../location_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class LocationService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  Position? _currentPosition;
  StreamSubscription<Position>? _positionStreamSubscription;
  bool _isTracking = false;
  String? _activeFlightLogId;
  double? _distanceFromSchool;
  double _schoolLatitude = AppConstants.defaultSchoolLatitude;
  double _schoolLongitude = AppConstants.defaultSchoolLongitude;
  
  Position? get currentPosition => _currentPosition;
  bool get isTracking => _isTracking;
  String? get activeFlightLogId => _activeFlightLogId;
  double? get distanceFromSchool => _distanceFromSchool;
  bool get isNearSchool => _distanceFromSchool != null && _distanceFromSchool! <= AppConstants.schoolProximityThreshold;
  
  LocationService() {
    _init();
  }
  
  void _init() async {
    // Load school coordinates from shared preferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _schoolLatitude = prefs.getDouble(AppConstants.prefsSchoolLatitude) ?? AppConstants.defaultSchoolLatitude;
    _schoolLongitude = prefs.getDouble(AppConstants.prefsSchoolLongitude) ?? AppConstants.defaultSchoolLongitude;
  }
  
  Future<bool> checkPermissions() async {
    bool serviceEnabled;
    LocationPermission permission;
    
    // Test if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }
    
    // Check location permissions
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      return false;
    }
    
    // Permissions are granted, proceed
    return true;
  }
  
  Future<Position?> getCurrentPosition() async {
    try {
      if (!await checkPermissions()) {
        return null;
      }
      
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );
      
      _currentPosition = position;
      _calculateDistanceFromSchool();
      notifyListeners();
      
      return position;
    } catch (e) {
      print('Error getting current position: $e');
      return null;
    }
  }
  
  Future<void> startTracking({String? flightLogId}) async {
    if (_isTracking) return;
    
    if (!await checkPermissions()) {
      return;
    }
    
    _activeFlightLogId = flightLogId;
    _isTracking = true;
    notifyListeners();
    
    // Set up location stream
    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update at least every 10 meters
        timeLimit: Duration(seconds: AppConstants.locationUpdateInterval),
      ),
    ).listen(_onPositionUpdate);
  }
  
  void _onPositionUpdate(Position position) async {
    _currentPosition = position;
    _calculateDistanceFromSchool();
    notifyListeners();
    
    // Update flight log if active
    if (_activeFlightLogId != null) {
      try {
        LocationPoint locationPoint = LocationPoint(
          latitude: position.latitude,
          longitude: position.longitude,
          altitude: position.altitude,
          timestamp: DateTime.now(),
        );
        
        await _firestore.collection(AppConstants.flightLogsCollection)
            .doc(_activeFlightLogId)
            .update({
          'flightPath': FieldValue.arrayUnion([locationPoint.toMap()]),
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
        });
      } catch (e) {
        print('Error updating flight path: $e');
      }
    }
  }
  
  void _calculateDistanceFromSchool() {
    if (_currentPosition == null) return;
    
    _distanceFromSchool = LocationUtils.calculateDistance(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      _schoolLatitude,
      _schoolLongitude,
    );
  }
  
  Future<void> stopTracking() async {
    if (!_isTracking) return;
    
    await _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    _isTracking = false;
    _activeFlightLogId = null;
    notifyListeners();
  }
  
  Future<void> updateSchoolLocation(double latitude, double longitude) async {
    _schoolLatitude = latitude;
    _schoolLongitude = longitude;
    
    // Save to shared preferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setDouble(AppConstants.prefsSchoolLatitude, latitude);
    prefs.setDouble(AppConstants.prefsSchoolLongitude, longitude);
    
    // Recalculate distance
    _calculateDistanceFromSchool();
    notifyListeners();
  }
  
  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    super.dispose();
  }
}