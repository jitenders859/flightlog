// lib/services/flight_overview_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/flight_overview_model.dart';

class FlightOverviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'flights';

  // Fetch all flights for a specific student
  Future<List<FlightOverviewModel>> getStudentFlights(String studentId) async {
    try {
      // Get flights from Firestore
      final querySnapshot =
          await _firestore
              .collection(_collection)
              .where('studentId', isEqualTo: studentId)
              .orderBy('startTime', descending: true)
              .get();

      return querySnapshot.docs
          .map((doc) => FlightOverviewModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error fetching student flights: $e');
      throw e;
    }
  }

  // For demo purposes: get flights from sample data
  Future<List<FlightOverviewModel>> getSampleFlights() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    return FlightOverviewModel.getSampleFlights();
  }

  // Filter flights by status (Opened, Closed, Cancelled)
  Future<List<FlightOverviewModel>> getFilteredFlights({
    required String studentId,
    required String status,
  }) async {
    try {
      // Get flights from Firestore with status filter
      final querySnapshot =
          await _firestore
              .collection(_collection)
              .where('studentId', isEqualTo: studentId)
              .where('status', isEqualTo: status)
              .orderBy('startTime', descending: true)
              .get();

      return querySnapshot.docs
          .map((doc) => FlightOverviewModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error fetching filtered flights: $e');
      throw e;
    }
  }

  // For demo purposes: filter sample flights by status
  Future<List<FlightOverviewModel>> filterSampleFlights(String status) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    // Get all sample flights
    List<FlightOverviewModel> allFlights =
        FlightOverviewModel.getSampleFlights();

    // Filter by status
    switch (status.toLowerCase()) {
      case 'opened':
        return allFlights.where((flight) => flight.status == 'OPEN').toList();
      case 'closed':
        return allFlights
            .where((flight) => flight.status == 'COMPLETED')
            .toList();
      case 'cancelled':
        return allFlights
            .where((flight) => flight.status == 'CANCELED')
            .toList();
      default:
        return allFlights;
    }
  }

  // Get flight details by ID
  Future<FlightOverviewModel?> getFlightDetails(String flightId) async {
    try {
      // Get flight document from Firestore
      final docSnapshot =
          await _firestore.collection(_collection).doc(flightId).get();

      if (docSnapshot.exists) {
        return FlightOverviewModel.fromFirestore(docSnapshot);
      }

      return null;
    } catch (e) {
      print('Error fetching flight details: $e');
      throw e;
    }
  }

  // For demo purposes: get flight details from sample data
  Future<FlightOverviewModel?> getSampleFlightDetails(String flightId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));

    // Get all sample flights
    List<FlightOverviewModel> allFlights =
        FlightOverviewModel.getSampleFlights();

    // Find flight by ID
    try {
      return allFlights.firstWhere((flight) => flight.id == flightId);
    } catch (e) {
      return null;
    }
  }
}
