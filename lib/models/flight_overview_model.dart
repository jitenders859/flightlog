// lib/models/flight_overview_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class FlightOverviewModel {
  final String id;
  final DateTime startTime;
  final DateTime endTime;
  final String type; // DUAL, SOLO, etc.
  final String program; // PPL, etc.
  final String instructor;
  final String aircraft;
  final String student;
  final String flight;
  final String air;
  final String briefing;
  final String evaluation;
  final String status; // CANCELED, COMPLETED, etc.
  final String cancelReason;

  FlightOverviewModel({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.type,
    required this.program,
    required this.instructor,
    required this.aircraft,
    required this.student,
    this.flight = '',
    this.air = '',
    this.briefing = '',
    required this.evaluation,
    required this.status,
    this.cancelReason = '',
  });

  factory FlightOverviewModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return FlightOverviewModel(
      id: doc.id,
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: (data['endTime'] as Timestamp).toDate(),
      type: data['type'] ?? '',
      program: data['program'] ?? '',
      instructor: data['instructor'] ?? '',
      aircraft: data['aircraft'] ?? '',
      student: data['student'] ?? '',
      flight: data['flight'] ?? '',
      air: data['air'] ?? '',
      briefing: data['briefing'] ?? '',
      evaluation: data['evaluation'] ?? '',
      status: data['status'] ?? '',
      cancelReason: data['cancelReason'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'type': type,
      'program': program,
      'instructor': instructor,
      'aircraft': aircraft,
      'student': student,
      'flight': flight,
      'air': air,
      'briefing': briefing,
      'evaluation': evaluation,
      'status': status,
      'cancelReason': cancelReason,
    };
  }

  // Sample flight data for demonstration
  static List<FlightOverviewModel> getSampleFlights() {
    return [
      FlightOverviewModel(
        id: '1',
        startTime: DateTime(2025, 2, 23, 12, 0),
        endTime: DateTime(2025, 2, 23, 14, 0),
        type: 'DUAL',
        program: 'PPL',
        instructor: 'Palak Pagaria',
        aircraft: 'C-GMUF',
        student: 'Ronit Tiwari',
        evaluation:
            '02-18 14:13 E-ICA-DISPATCHER4 studentReason cancel detail: Low funds',
        status: 'CANCELED',
      ),
      FlightOverviewModel(
        id: '2',
        startTime: DateTime(2025, 2, 20, 14, 0),
        endTime: DateTime(2025, 2, 20, 16, 0),
        type: 'DUAL',
        program: 'PPL',
        instructor: 'Palak Pagaria',
        aircraft: 'C-FEFY',
        student: 'Ronit Tiwari',
        evaluation:
            '02-18 14:13 E-ICA-DISPATCHER4 studentReason cancel detail: Low funds',
        status: 'CANCELED',
      ),
      FlightOverviewModel(
        id: '3',
        startTime: DateTime(2025, 2, 16, 16, 0),
        endTime: DateTime(2025, 2, 16, 18, 0),
        type: 'SOLO',
        program: 'PPL',
        instructor: 'Palak Pagaria',
        aircraft: 'C-GEMI',
        student: 'Ronit Tiwari',
        evaluation:
            '02-16 13:49 E-ICA-DISPATCHER3 weather cancel detail: low vis',
        status: 'CANCELED',
      ),
      FlightOverviewModel(
        id: '4',
        startTime: DateTime(2025, 2, 16, 14, 0),
        endTime: DateTime(2025, 2, 16, 16, 0),
        type: 'DUAL',
        program: 'PPL',
        instructor: 'Palak Pagaria',
        aircraft: 'C-FEFY',
        student: 'Ronit Tiwari',
        evaluation:
            '02-15 16:42 E-ICA-DISPATCHER3 studentReason cancel detail: Low fund',
        status: 'CANCELED',
      ),
      FlightOverviewModel(
        id: '5',
        startTime: DateTime(2025, 2, 7, 12, 0),
        endTime: DateTime(2025, 2, 7, 14, 0),
        type: 'DUAL',
        program: 'PPL',
        instructor: 'Palak Pagaria',
        aircraft: 'C-GEJK',
        student: 'Ronit Tiwari',
        evaluation:
            '02-03 18:25 E-ICA-DISPATCHER3 studentReason cancel detail: student not available',
        status: 'CANCELED',
      ),
      FlightOverviewModel(
        id: '6',
        startTime: DateTime(2025, 2, 6, 12, 0),
        endTime: DateTime(2025, 2, 6, 14, 0),
        type: 'DUAL',
        program: 'PPL',
        instructor: 'Palak Pagaria',
        aircraft: 'C-GEMI',
        student: 'Ronit Tiwari',
        evaluation: '02-06 07:53 E-ICA-DISPATCHER3 weather cancel detail: snow',
        status: 'CANCELED',
      ),
    ];
  }
}
