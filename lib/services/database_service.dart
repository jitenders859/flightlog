import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../constants/app_constants.dart';
import '../models/flight_log_model.dart';
import '../models/notification_mode.dart';
import '../models/user_model.dart';


class DatabaseService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  String? _currentUserId;
  String? _currentUserRole;
  
  String? get currentUserId => _currentUserId;
  String? get currentUserRole => _currentUserRole;
  
  // Initialize with user ID and role
  void initialize(String userId, String userRole) {
    _currentUserId = userId;
    _currentUserRole = userRole;
  }
  
  // Get a single user
  Future<UserModel?> getUser(String userId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection(AppConstants.usersCollection).doc(userId).get();
      
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      
      return null;
    } catch (e) {
      print('Error getting user: $e');
      return null;
    }
  }
  
  // Get users by role
  Stream<List<UserModel>> getUsersByRole(String role) {
    return _firestore
        .collection(AppConstants.usersCollection)
        .where('role', isEqualTo: role)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserModel.fromMap(doc.data(), doc.id))
            .toList());
  }
  
  // Get all flight logs for a student
  Stream<List<FlightLogModel>> getStudentFlightLogs(String studentId) {
    return _firestore
        .collection(AppConstants.flightLogsCollection)
        .where('studentId', isEqualTo: studentId)
        .orderBy('startTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FlightLogModel.fromMap(doc.data(), doc.id))
            .toList());
  }
  
  // Get all flight logs for a teacher
  Stream<List<FlightLogModel>> getTeacherFlightLogs(String teacherId) {
    return _firestore
        .collection(AppConstants.flightLogsCollection)
        .where('teacherId', isEqualTo: teacherId)
        .orderBy('startTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FlightLogModel.fromMap(doc.data(), doc.id))
            .toList());
  }
  
  // Get all active flight logs (for dispatch)
  Stream<List<FlightLogModel>> getActiveFlightLogs() {
    return _firestore
        .collection(AppConstants.flightLogsCollection)
        .where('status', isEqualTo: 'in-progress')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FlightLogModel.fromMap(doc.data(), doc.id))
            .toList());
  }
  
  // Get a single flight log
  Future<FlightLogModel?> getFlightLog(String flightLogId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection(AppConstants.flightLogsCollection).doc(flightLogId).get();
      
      if (doc.exists) {
        return FlightLogModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      
      return null;
    } catch (e) {
      print('Error getting flight log: $e');
      return null;
    }
  }
  
  // Create a new flight log
  Future<String?> createFlightLog({
    required String studentId,
    String? teacherId,
    required DateTime startTime,
  }) async {
    try {
      FlightLogModel flightLog = FlightLogModel.create(
        studentId: studentId,
        teacherId: teacherId,
        startTime: startTime,
      );
      
      await _firestore
          .collection(AppConstants.flightLogsCollection)
          .doc(flightLog.id)
          .set(flightLog.toMap());
      
      return flightLog.id;
    } catch (e) {
      print('Error creating flight log: $e');
      return null;
    }
  }
  
  // Update flight log (complete flight)
  Future<bool> completeFlightLog({
    required String flightLogId,
    DateTime? endTime,
    String? notes,
  }) async {
    try {
      // Get current flight log
      FlightLogModel? flightLog = await getFlightLog(flightLogId);
      
      if (flightLog != null) {
        // Complete flight log
        FlightLogModel completedLog = flightLog.complete(
          endTime: endTime ?? DateTime.now(),
          notes: notes,
        );
        
        // Update in Firestore
        await _firestore
            .collection(AppConstants.flightLogsCollection)
            .doc(flightLogId)
            .update(completedLog.toMap());
        
        return true;
      }
      
      return false;
    } catch (e) {
      print('Error completing flight log: $e');
      return false;
    }
  }
  
  // Add location to flight path
  Future<bool> addLocationToFlightLog({
    required String flightLogId,
    required double latitude,
    required double longitude,
    double? altitude,
  }) async {
    try {
      LocationPoint locationPoint = LocationPoint(
        latitude: latitude,
        longitude: longitude,
        altitude: altitude,
        timestamp: DateTime.now(),
      );
      
      await _firestore
          .collection(AppConstants.flightLogsCollection)
          .doc(flightLogId)
          .update({
        'flightPath': FieldValue.arrayUnion([locationPoint.toMap()]),
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
      
      return true;
    } catch (e) {
      print('Error adding location to flight log: $e');
      return false;
    }
  }
  
  // Get notifications for a user
  Stream<List<NotificationModel>> getUserNotifications(String userId) {
    return _firestore
        .collection(AppConstants.notificationsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationModel.fromMap(doc.data(), doc.id))
            .toList());
  }
  
  // Send a notification to a user
  Future<bool> sendNotification({
    required String userId,
    required String title,
    required String body,
    String type = 'custom',
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      NotificationModel notification = NotificationModel.createCustom(
        userId: userId,
        title: title,
        body: body,
        additionalData: additionalData,
      );
      
      await _firestore
          .collection(AppConstants.notificationsCollection)
          .doc(notification.id)
          .set(notification.toMap());
      
      return true;
    } catch (e) {
      print('Error sending notification: $e');
      return false;
    }
  }
  
  // Get all students (for admin and teachers)
  Future<List<UserModel>> getAllStudents() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .where('role', isEqualTo: AppConstants.roleStudent)
          .get();
      
      return snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      print('Error getting students: $e');
      return [];
    }
  }
  
  // Get all teachers (for admin)
  Future<List<UserModel>> getAllTeachers() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .where('role', isEqualTo: AppConstants.roleTeacher)
          .get();
      
      return snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      print('Error getting teachers: $e');
      return [];
    }
  }
  
  // Update a user's status (active/inactive)
  Future<bool> updateUserStatus(String userId, bool isActive) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update({
        'isActive': isActive,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
      
      return true;
    } catch (e) {
      print('Error updating user status: $e');
      return false;
    }
  }
  
  // Get school location from settings collection
  Future<Map<String, double>?> getSchoolLocation() async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection(AppConstants.settingsCollection)
          .doc('location')
          .get();
      
      if (doc.exists && doc.data() != null) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return {
          'latitude': data['schoolLatitude'] ?? AppConstants.defaultSchoolLatitude,
          'longitude': data['schoolLongitude'] ?? AppConstants.defaultSchoolLongitude,
        };
      }
      
      return {
        'latitude': AppConstants.defaultSchoolLatitude,
        'longitude': AppConstants.defaultSchoolLongitude,
      };
    } catch (e) {
      print('Error getting school location: $e');
      return null;
    }
  }
  
  // Update school location (admin only)
  Future<bool> updateSchoolLocation(double latitude, double longitude) async {
    try {
      await _firestore
          .collection(AppConstants.settingsCollection)
          .doc('location')
          .set({
        'schoolLatitude': latitude,
        'schoolLongitude': longitude,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      }, SetOptions(merge: true));
      
      return true;
    } catch (e) {
      print('Error updating school location: $e');
      return false;
    }
  }
}