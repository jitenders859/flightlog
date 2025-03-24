// lib/services/schedule_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:navlog/models/student_scedule.dart';

class ScheduleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'schedules';

  // Get all events for a specific student
  Stream<List<ScheduleEvent>> getStudentScheduleStream(String studentId) {
    return _firestore
        .collection(_collection)
        .where('studentId', isEqualTo: studentId)
        .orderBy('startTime')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => ScheduleEvent.fromFirestore(doc))
                  .toList(),
        );
  }

  // Get events for a specific student within a date range
  Stream<List<ScheduleEvent>> getStudentScheduleRangeStream(
    String studentId,
    DateTime startDate,
    DateTime endDate,
  ) {
    // Convert to Timestamp for Firestore query
    final Timestamp startTimestamp = Timestamp.fromDate(startDate);
    final Timestamp endTimestamp = Timestamp.fromDate(endDate);

    return _firestore
        .collection(_collection)
        .where('studentId', isEqualTo: studentId)
        .where('startTime', isGreaterThanOrEqualTo: startTimestamp)
        .where('startTime', isLessThanOrEqualTo: endTimestamp)
        .orderBy('startTime')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => ScheduleEvent.fromFirestore(doc))
                  .toList(),
        );
  }

  // Get events for a specific student on a specific date
  Future<List<ScheduleEvent>> getStudentScheduleForDate(
    String studentId,
    DateTime date,
  ) async {
    // Create start and end of the day
    final DateTime startOfDay = DateTime(
      date.year,
      date.month,
      date.day,
      0,
      0,
      0,
    );
    final DateTime endOfDay = DateTime(
      date.year,
      date.month,
      date.day,
      23,
      59,
      59,
    );

    // Convert to Timestamp for Firestore query
    final Timestamp startTimestamp = Timestamp.fromDate(startOfDay);
    final Timestamp endTimestamp = Timestamp.fromDate(endOfDay);

    final snapshot =
        await _firestore
            .collection(_collection)
            .where('studentId', isEqualTo: studentId)
            .where('startTime', isGreaterThanOrEqualTo: startTimestamp)
            .where('startTime', isLessThanOrEqualTo: endTimestamp)
            .orderBy('startTime')
            .get();

    return snapshot.docs
        .map((doc) => ScheduleEvent.fromFirestore(doc))
        .toList();
  }

  // Get events for a specific student for a week
  Future<List<ScheduleEvent>> getStudentScheduleForWeek(
    String studentId,
    DateTime weekStart,
  ) async {
    // Calculate the end of the week (weekStart + 6 days)
    final DateTime weekEnd = weekStart.add(
      const Duration(days: 6, hours: 23, minutes: 59, seconds: 59),
    );

    // Convert to Timestamp for Firestore query
    final Timestamp startTimestamp = Timestamp.fromDate(weekStart);
    final Timestamp endTimestamp = Timestamp.fromDate(weekEnd);

    final snapshot =
        await _firestore
            .collection(_collection)
            .where('studentId', isEqualTo: studentId)
            .where('startTime', isGreaterThanOrEqualTo: startTimestamp)
            .where('startTime', isLessThanOrEqualTo: endTimestamp)
            .orderBy('startTime')
            .get();

    return snapshot.docs
        .map((doc) => ScheduleEvent.fromFirestore(doc))
        .toList();
  }

  // Add a new schedule event
  Future<String> addScheduleEvent(ScheduleEvent event) async {
    final docRef = await _firestore
        .collection(_collection)
        .add(event.toFirestore());

    return docRef.id;
  }

  // Update an existing schedule event
  Future<void> updateScheduleEvent(ScheduleEvent event) async {
    await _firestore
        .collection(_collection)
        .doc(event.id)
        .update(event.toFirestore());
  }

  // Delete a schedule event
  Future<void> deleteScheduleEvent(String eventId) async {
    await _firestore.collection(_collection).doc(eventId).delete();
  }
}
