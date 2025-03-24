// lib/models/schedule_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class ScheduleEvent {
  final String id;
  final String title;
  final DateTime startTime;
  final DateTime endTime;
  final String instructor;
  final String location;
  final String status; // e.g., 'OPEN', 'DONE', 'CANCELED'
  final String type; // e.g., 'Flight', 'Ground Class', 'Simulator'
  final String aircraft;
  final String studentId;
  final String studentName;
  final String campus;
  final String program;
  final String createdBy;
  final DateTime createdAt;
  final String remarks;

  // Flight specific data
  final String flightType; // e.g., 'DUAL', 'SOLO'
  final String content;
  final String exercise;
  final String nightFlight;
  final String weight;
  final String fuel;
  final String route;
  final String eta;
  final String instrumentTime;
  final String groundBriefingTime;
  final String hobbsStart;
  final String hobbsStop;
  final String engineStart;
  final String engineOff;
  final String airUp;
  final String airDown;
  final String flightTime;
  final String airTime;
  final String studentNote;
  final String instructorNote;
  final String cx;
  final String cxTime;

  ScheduleEvent({
    required this.id,
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.instructor,
    required this.location,
    required this.status,
    required this.type,
    required this.aircraft,
    required this.studentId,
    this.studentName = '',
    this.campus = 'ICA',
    this.program = 'PPL',
    this.createdBy = '',
    DateTime? createdAt,
    this.remarks = 'N/A',
    this.flightType = 'DUAL',
    this.content = 'N/A',
    this.exercise = 'N/A',
    this.nightFlight = 'N/A',
    this.weight = 'N/A lb',
    this.fuel = 'N/A gal',
    this.route = 'N/A',
    this.eta = 'N/A',
    this.instrumentTime = 'N/A h',
    this.groundBriefingTime = 'N/A h',
    this.hobbsStart = 'N/A',
    this.hobbsStop = 'N/A',
    this.engineStart = 'N/A',
    this.engineOff = 'N/A',
    this.airUp = 'N/A',
    this.airDown = 'N/A',
    this.flightTime = 'N/A h',
    this.airTime = 'N/A h',
    this.studentNote = 'N/A',
    this.instructorNote = 'N/A',
    this.cx = 'N/A',
    this.cxTime = 'N/A h',
  }) : createdAt = createdAt ?? DateTime.now();

  // Create from Firestore document
  factory ScheduleEvent.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return ScheduleEvent(
      id: doc.id,
      title: data['title'] ?? '',
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: (data['endTime'] as Timestamp).toDate(),
      instructor: data['instructor'] ?? '',
      location: data['location'] ?? '',
      status: data['status'] ?? 'OPEN',
      type: data['type'] ?? 'Flight',
      aircraft: data['aircraft'] ?? '',
      studentId: data['studentId'] ?? '',
      studentName: data['studentName'] ?? '',
      campus: data['campus'] ?? 'ICA',
      program: data['program'] ?? 'PPL',
      createdBy: data['createdBy'] ?? '',
      createdAt:
          data['createdAt'] != null
              ? (data['createdAt'] as Timestamp).toDate()
              : DateTime.now(),
      remarks: data['remarks'] ?? 'N/A',
      flightType: data['flightType'] ?? 'DUAL',
      content: data['content'] ?? 'N/A',
      exercise: data['exercise'] ?? 'N/A',
      nightFlight: data['nightFlight'] ?? 'N/A',
      weight: data['weight'] ?? 'N/A lb',
      fuel: data['fuel'] ?? 'N/A gal',
      route: data['route'] ?? 'N/A',
      eta: data['eta'] ?? 'N/A',
      instrumentTime: data['instrumentTime'] ?? 'N/A h',
      groundBriefingTime: data['groundBriefingTime'] ?? 'N/A h',
      hobbsStart: data['hobbsStart'] ?? 'N/A',
      hobbsStop: data['hobbsStop'] ?? 'N/A',
      engineStart: data['engineStart'] ?? 'N/A',
      engineOff: data['engineOff'] ?? 'N/A',
      airUp: data['airUp'] ?? 'N/A',
      airDown: data['airDown'] ?? 'N/A',
      flightTime: data['flightTime'] ?? 'N/A h',
      airTime: data['airTime'] ?? 'N/A h',
      studentNote: data['studentNote'] ?? 'N/A',
      instructorNote: data['instructorNote'] ?? 'N/A',
      cx: data['cx'] ?? 'N/A',
      cxTime: data['cxTime'] ?? 'N/A h',
    );
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'instructor': instructor,
      'location': location,
      'status': status,
      'type': type,
      'aircraft': aircraft,
      'studentId': studentId,
      'studentName': studentName,
      'campus': campus,
      'program': program,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'remarks': remarks,
      'flightType': flightType,
      'content': content,
      'exercise': exercise,
      'nightFlight': nightFlight,
      'weight': weight,
      'fuel': fuel,
      'route': route,
      'eta': eta,
      'instrumentTime': instrumentTime,
      'groundBriefingTime': groundBriefingTime,
      'hobbsStart': hobbsStart,
      'hobbsStop': hobbsStop,
      'engineStart': engineStart,
      'engineOff': engineOff,
      'airUp': airUp,
      'airDown': airDown,
      'flightTime': flightTime,
      'airTime': airTime,
      'studentNote': studentNote,
      'instructorNote': instructorNote,
      'cx': cx,
      'cxTime': cxTime,
    };
  }

  // Helper method to check if event falls on a specific date
  bool isOnDate(DateTime date) {
    return startTime.year == date.year &&
        startTime.month == date.month &&
        startTime.day == date.day;
  }

  // Create a sample flight event for testing/demo
  static ScheduleEvent createSampleFlight({
    required String studentId,
    required String studentName,
    DateTime? startTime,
  }) {
    final start =
        startTime ?? DateTime.now().add(const Duration(days: 1, hours: 10));
    final end = start.add(const Duration(hours: 2));

    return ScheduleEvent(
      id: 'sample-flight-${DateTime.now().millisecondsSinceEpoch}',
      title: 'Flight Lesson',
      startTime: start,
      endTime: end,
      instructor: 'Palak Pagaria',
      location: 'ICA',
      status: 'OPEN',
      type: 'Flight',
      aircraft: 'C-GBYZ',
      studentId: studentId,
      studentName: studentName,
      campus: 'Campus',
      program: 'PPL',
      createdBy: 'E-ICA-DISPATCHER3',
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      flightType: 'DUAL',
    );
  }
}
