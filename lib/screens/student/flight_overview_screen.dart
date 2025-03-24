// lib/screens/student/my_flights_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:navlog/dialog_components/flight_overview_detail.dart';
import 'package:provider/provider.dart';

import '../../models/flight_overview_model.dart';
import '../../providers/flight_overview_provider.dart';
import '../../services/auth_service.dart';

class MyFlightsOverviewScreen extends StatefulWidget {
  const MyFlightsOverviewScreen({Key? key}) : super(key: key);

  @override
  State<MyFlightsOverviewScreen> createState() =>
      _MyFlightsOverviewScreenState();
}

class _MyFlightsOverviewScreenState extends State<MyFlightsOverviewScreen>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;
  String _studentId = '';
  final DateFormat _timeFormat = DateFormat('HH:mm');

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 3, vsync: this, initialIndex: 2);

    _tabController!.addListener(() {
      if (!_tabController!.indexIsChanging) {
        _updateSelectedFilter();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authService = Provider.of<AuthService>(context, listen: false);
      final flightProvider = Provider.of<FlightOverviewProvider>(
        context,
        listen: false,
      );

      if (authService.currentUser != null) {
        setState(() {
          _studentId = authService.currentUser!.id;
        });

        flightProvider.initialize(_studentId);
      }
    });
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  void _updateSelectedFilter() {
    final flightProvider = Provider.of<FlightOverviewProvider>(
      context,
      listen: false,
    );
    String filter;

    switch (_tabController!.index) {
      case 0:
        filter = 'Opened';
        break;
      case 1:
        filter = 'Closed';
        break;
      case 2:
        filter = 'Cancelled';
        break;
      default:
        filter = 'All';
    }

    flightProvider.changeFilter(filter, _studentId);
  }

  @override
  Widget build(BuildContext context) {
    final flightProvider = Provider.of<FlightOverviewProvider>(context);

    return Scaffold(
      // appBar: AppBar(
      //   title: const Text('Flight Overview'),
      //   actions: [
      //     IconButton(
      //       icon: const Icon(Icons.close, color: Colors.red),
      //       onPressed: () {
      //         Navigator.pop(context);
      //       },
      //     ),
      //   ],
      // ),
      body: Column(
        children: [
          _buildHeader(),
          _buildTabBar(),
          Expanded(
            child:
                flightProvider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : flightProvider.flights.isEmpty
                    ? _buildEmptyState()
                    : _buildFlightTable(flightProvider),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 5, offset: Offset(0, 2)),
        ],
      ),
      child: const Text(
        'Ronit Tiwari(22121601) Flight Overview',
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildTabBar() {
    return Material(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.blue,
        unselectedLabelColor: Colors.grey,
        indicatorColor: Colors.blue,
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Text('Opened'),
                SizedBox(width: 5),
                Tooltip(
                  message: 'Flights that are scheduled and not yet completed',
                  child: Icon(Icons.info_outline, size: 16),
                ),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Text('Closed'),
                SizedBox(width: 5),
                Tooltip(
                  message: 'Flights that have been completed',
                  child: Icon(Icons.info_outline, size: 16),
                ),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Text('Cancelled'),
                SizedBox(width: 5),
                Tooltip(
                  message: 'Flights that were cancelled',
                  child: Icon(Icons.info_outline, size: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.flight_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No ${_tabController!.index == 0
                ? 'opened'
                : _tabController!.index == 1
                ? 'closed'
                : 'cancelled'} flights found',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Check back later for updates',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildFlightTable(FlightOverviewProvider provider) {
    return Column(
      children: [
        // Table header
        Container(
          color: Colors.grey[200],
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              _buildTableHeaderCell('Time', flex: 2),
              _buildTableHeaderCell('Type', flex: 1),
              _buildTableHeaderCell('Program', flex: 1),
              _buildTableHeaderCell('Instructor', flex: 2),
              _buildTableHeaderCell('Aircraft', flex: 1),
              _buildTableHeaderCell('Student', flex: 2),
              _buildTableHeaderCell('flight', flex: 1),
              _buildTableHeaderCell('air', flex: 1),
              _buildTableHeaderCell('briefing', flex: 1),
              _buildTableHeaderCell('Evaluation', flex: 5),
              _buildTableHeaderCell('Status', flex: 2),
              _buildTableHeaderCell('', flex: 1),
            ],
          ),
        ),

        // Table body
        Expanded(
          child: ListView.builder(
            itemCount: provider.flights.length,
            itemBuilder: (context, index) {
              final flight = provider.flights[index];
              return _buildFlightRow(flight, index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTableHeaderCell(String text, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildFlightRow(FlightOverviewModel flight, int index) {
    // Format the time range
    final startTime = _timeFormat.format(flight.startTime);
    final endTime = _timeFormat.format(flight.endTime);
    final timeRange =
        '${flight.startTime.year}-${flight.startTime.month.toString().padLeft(2, '0')}-${flight.startTime.day.toString().padLeft(2, '0')}\n$startTime ~ $endTime';

    return Container(
      decoration: BoxDecoration(
        color: index % 2 == 0 ? Colors.white : Colors.grey[50],
        border: const Border(
          bottom: BorderSide(color: Colors.grey, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          _buildTableCell(timeRange, flex: 2),
          _buildTableCell(flight.type, flex: 1),
          _buildTableCell(flight.program, flex: 1),
          _buildTableCell(flight.instructor, flex: 2),
          _buildTableCell(flight.aircraft, flex: 1),
          _buildTableCell(flight.student, flex: 2),
          _buildTableCell(flight.flight, flex: 1),
          _buildTableCell(flight.air, flex: 1),
          _buildTableCell(flight.briefing, flex: 1),
          _buildTableCell(flight.evaluation, flex: 5),
          _buildTableCell(
            flight.status,
            flex: 2,
            textColor:
                flight.status == 'CANCELED'
                    ? Colors.red
                    : flight.status == 'COMPLETED'
                    ? Colors.green
                    : Colors.blue,
            fontWeight: FontWeight.bold,
          ),
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: TextButton(
                onPressed: () {
                  _showFlightDetails(flight);
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                child: const Text('detail'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableCell(
    String text, {
    int flex = 1,
    Color? textColor,
    FontWeight fontWeight = FontWeight.normal,
  }) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Text(
          text,
          style: TextStyle(color: textColor, fontWeight: fontWeight),
        ),
      ),
    );
  }

  void _showFlightDetails(FlightOverviewModel flight) {
    // TODO: Implement flight details dialog
    // For now, just show a snackbar
    // ScaffoldMessenger.of(context).showSnackBar(
    //   SnackBar(
    //     content: Text('Flight details for ${flight.id} - ${flight.status}'),
    //     duration: const Duration(seconds: 2),
    //   ),
    // );

    // Example of how you could show a dialog:
    showDialog(
      context: context,
      builder: (context) => FlightOverviewDetailDialog(flight: flight),
    );
  }
}
