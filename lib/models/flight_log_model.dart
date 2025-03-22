import 'package:cloud_firestore/cloud_firestore.dart';

class LocationPoint {
  final double latitude;
  final double longitude;
  final double? altitude;
  final DateTime timestamp;

  LocationPoint({
    required this.latitude,
    required this.longitude,
    this.altitude,
    required this.timestamp,
  });

  factory LocationPoint.fromMap(Map<String, dynamic> map) {
    return LocationPoint(
      latitude: map['latitude'] ?? 0.0,
      longitude: map['longitude'] ?? 0.0,
      altitude: map['altitude'],
      timestamp:
          (map['timestamp'] != null)
              ? DateTime.fromMillisecondsSinceEpoch(map['timestamp'])
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'altitude': altitude,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }
}

class FlightLogModel {
  final String id;
  final String studentId;
  final String? teacherId;
  final DateTime startTime;
  final DateTime? endTime;
  final String status; // 'scheduled', 'in-progress', 'completed', 'cancelled'
  final List<LocationPoint> flightPath;
  final String? notes;
  final Map<String, dynamic>? additionalData;
  final DateTime createdAt;
  final DateTime updatedAt;

  FlightLogModel({
    required this.id,
    required this.studentId,
    this.teacherId,
    required this.startTime,
    this.endTime,
    required this.status,
    required this.flightPath,
    this.notes,
    this.additionalData,
    required this.createdAt,
    required this.updatedAt,
  });

  Duration? get duration {
    if (endTime == null) return null;
    return endTime!.difference(startTime);
  }

  String get durationString {
    final duration = this.duration;
    if (duration == null) return 'In Progress';

    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    return '${hours}h ${minutes}m';
  }

  factory FlightLogModel.fromMap(Map<String, dynamic> map, String id) {
    List<LocationPoint> flightPath = [];
    if (map['flightPath'] != null) {
      flightPath = List<LocationPoint>.from(
        (map['flightPath'] as List).map(
          (point) => LocationPoint.fromMap(point),
        ),
      );
    }

    return FlightLogModel(
      id: id,
      studentId: map['studentId'] ?? '',
      teacherId: map['teacherId'],
      startTime:
          (map['startTime'] != null)
              ? DateTime.fromMillisecondsSinceEpoch(map['startTime'])
              : DateTime.now(),
      endTime:
          (map['endTime'] != null)
              ? DateTime.fromMillisecondsSinceEpoch(map['endTime'])
              : null,
      status: map['status'] ?? 'scheduled',
      flightPath: flightPath,
      notes: map['notes'],
      additionalData: map['additionalData'],
      createdAt:
          (map['createdAt'] != null)
              ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'])
              : DateTime.now(),
      updatedAt:
          (map['updatedAt'] != null)
              ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt'])
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'teacherId': teacherId,
      'startTime': startTime.millisecondsSinceEpoch,
      'endTime': endTime?.millisecondsSinceEpoch,
      'status': status,
      'flightPath': flightPath.map((point) => point.toMap()).toList(),
      'notes': notes,
      'additionalData': additionalData,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  // Create a new flight log
  factory FlightLogModel.create({
    required String studentId,
    String? teacherId,
    required DateTime startTime,
  }) {
    String id = FirebaseFirestore.instance.collection('flight_logs').doc().id;

    return FlightLogModel(
      id: id,
      studentId: studentId,
      teacherId: teacherId,
      startTime: startTime,
      endTime: null,
      status: 'in-progress',
      flightPath: [],
      notes: null,
      additionalData: null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  // Add location to flight path
  FlightLogModel addLocation(LocationPoint location) {
    List<LocationPoint> newFlightPath = List.from(flightPath);
    newFlightPath.add(location);

    return FlightLogModel(
      id: this.id,
      studentId: this.studentId,
      teacherId: this.teacherId,
      startTime: this.startTime,
      endTime: this.endTime,
      status: this.status,
      flightPath: newFlightPath,
      notes: this.notes,
      additionalData: this.additionalData,
      createdAt: this.createdAt,
      updatedAt: DateTime.now(),
    );
  }

  // Complete flight log
  FlightLogModel complete({DateTime? endTime, String? notes}) {
    return FlightLogModel(
      id: this.id,
      studentId: this.studentId,
      teacherId: this.teacherId,
      startTime: this.startTime,
      endTime: endTime ?? DateTime.now(),
      status: 'completed',
      flightPath: this.flightPath,
      notes: notes ?? this.notes,
      additionalData: this.additionalData,
      createdAt: this.createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
