// lib/services/dummy_data_service.dart

import 'package:navlog/models/student_scedule.dart';

class DummyDataService {
  // Generate a sample flight schedule event with the appearance from the screenshot
  static ScheduleEvent getSampleFlightEvent({
    required String studentId,
    required String studentName,
  }) {
    // Create a flight for March 25th, 2025 from 10:00 - 12:00
    final DateTime startTime = DateTime(2025, 3, 25, 10, 0);
    final DateTime endTime = DateTime(2025, 3, 25, 12, 0);

    return ScheduleEvent(
      id: 'sample-flight-1',
      title: 'Flight Lesson',
      startTime: startTime,
      endTime: endTime,
      instructor: 'Palak Pagaria',
      location: 'ICA',
      status: 'OPEN',
      type: 'Flight',
      aircraft: 'C-GBYZ',
      studentId: studentId,
      studentName: studentName,
      campus: 'Campus',
      createdBy: 'E-ICA-DISPATCHER3',
      createdAt: DateTime(2025, 3, 19, 8, 54),
      remarks: 'N/A',
      flightType: 'DUAL',
    );
  }

  // Generate another sample flight for March 24th
  static ScheduleEvent getAdditionalFlightEvent({
    required String studentId,
    required String studentName,
  }) {
    // Create a flight for March 24th, 2025 from 14:00 - 16:00
    final DateTime startTime = DateTime(2025, 3, 24, 14, 0);
    final DateTime endTime = DateTime(2025, 3, 24, 16, 0);

    return ScheduleEvent(
      id: 'sample-flight-2',
      title: 'Flight Lesson',
      startTime: startTime,
      endTime: endTime,
      instructor: 'Palak Pagaria',
      location: 'ICA',
      status: 'OPEN',
      type: 'Flight',
      aircraft: 'C-GBYZ',
      studentId: studentId,
      studentName: studentName,
      campus: 'Campus',
      createdBy: 'E-ICA-DISPATCHER3',
      createdAt: DateTime(2025, 3, 19, 9, 30),
      remarks: 'N/A',
      flightType: 'DUAL',
    );
  }
}
