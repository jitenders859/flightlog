// lib/providers/flight_overview_provider.dart

import 'package:flutter/material.dart';
import '../models/flight_overview_model.dart';
import '../services/flight_overview_service.dart';

class FlightOverviewProvider extends ChangeNotifier {
  final FlightOverviewService _flightService = FlightOverviewService();

  List<FlightOverviewModel> _flights = [];
  List<FlightOverviewModel> get flights => _flights;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Currently selected filter tab (Opened, Closed, Cancelled)
  String _selectedFilter = 'Cancelled';
  String get selectedFilter => _selectedFilter;

  // Initialize with student ID
  Future<void> initialize(String studentId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Using the sample data for demo
      // Note: In production, use this instead: await _flightService.getStudentFlights(studentId);
      _flights = await _flightService.getSampleFlights();
    } catch (e) {
      _errorMessage = 'Failed to load flights: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Change the selected filter
  Future<void> changeFilter(String filter, String studentId) async {
    if (_selectedFilter == filter) return;

    _selectedFilter = filter;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Using the sample data for demo with filter
      // Note: In production, use: await _flightService.getFilteredFlights(studentId: studentId, status: filter);
      _flights = await _flightService.filterSampleFlights(filter);
    } catch (e) {
      _errorMessage = 'Failed to filter flights: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get flight details by ID
  Future<FlightOverviewModel?> getFlightDetails(String flightId) async {
    try {
      // Using the sample data for demo
      // Note: In production, use: return await _flightService.getFlightDetails(flightId);
      return await _flightService.getSampleFlightDetails(flightId);
    } catch (e) {
      _errorMessage = 'Failed to get flight details: $e';
      notifyListeners();
      return null;
    }
  }

  // Refresh flights
  Future<void> refreshFlights(String studentId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Check if we're using a filter
      if (_selectedFilter != 'All') {
        _flights = await _flightService.filterSampleFlights(_selectedFilter);
      } else {
        _flights = await _flightService.getSampleFlights();
      }
    } catch (e) {
      _errorMessage = 'Failed to refresh flights: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
