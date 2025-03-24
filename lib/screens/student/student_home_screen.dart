import 'dart:async';
import 'package:flutter/material.dart';
import 'package:navlog/screens/student/flight_overview_screen.dart';
import 'package:navlog/screens/student/my_schedule_screen.dart';
import 'package:navlog/screens/student/student_wallet_screen.dart';
import '../../constants/colors.dart';
import '../../location_utils.dart';
import '../../login_screen.dart';
import '../../models/flight_log_model.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../services/flight_log_service.dart';
import '../../services/location_service.dart';
import '../../services/notification_service.dart';
import '../../widgets/custom_button.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';

import 'flight_detail_screen.dart';
import 'profile_screen.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({Key? key}) : super(key: key);

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  int _selectedIndex = 0;
  final List<String> _pages = [
    'Home',
    'My Schedule',
    'My Flights',
    'Wallet',
    'Profile',
  ];
  bool _locationPermissionsGranted = false;
  String? _locationErrorMessage;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _checkLocationPermissions();

    // Start a timer to refresh UI every minute
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeServices() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final databaseService = Provider.of<DatabaseService>(
      context,
      listen: false,
    );
    final notificationService = Provider.of<NotificationService>(
      context,
      listen: false,
    );
    final flightLogService = Provider.of<FlightLogService>(
      context,
      listen: false,
    );

    if (authService.currentUser != null) {
      databaseService.initialize(
        authService.currentUser!.id,
        authService.currentUser!.role,
      );

      await notificationService.initialize(userId: authService.currentUser!.id);

      await flightLogService.initialize(authService.currentUser!.id);
    }
  }

  Future<void> _checkLocationPermissions() async {
    final locationService = Provider.of<LocationService>(
      context,
      listen: false,
    );

    try {
      bool permissionsGranted = await locationService.checkPermissions();

      setState(() {
        _locationPermissionsGranted = permissionsGranted;
        _locationErrorMessage =
            permissionsGranted
                ? null
                : 'Location permissions are required to use this app.';
      });

      if (permissionsGranted) {
        // Get the current position
        await locationService.getCurrentPosition();
      }
    } catch (e) {
      setState(() {
        _locationPermissionsGranted = false;
        _locationErrorMessage = 'Error checking location permissions: $e';
      });
    }
  }

  Future<void> _startFlight() async {
    if (!_locationPermissionsGranted) {
      _checkLocationPermissions();
      return;
    }

    final flightLogService = Provider.of<FlightLogService>(
      context,
      listen: false,
    );

    bool success = await flightLogService.startFlight();

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Flight started successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to start flight. Please try again.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _endFlight() async {
    final flightLogService = Provider.of<FlightLogService>(
      context,
      listen: false,
    );

    // Show dialog to confirm ending flight
    bool? confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('End Flight'),
            content: const Text('Are you sure you want to end this flight?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('End Flight'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      bool success = await flightLogService.endFlight();

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Flight ended successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to end flight. Please try again.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _signOut() async {
    final authService = Provider.of<AuthService>(context, listen: false);

    await authService.signOut();

    // Navigate to login screen
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  Widget _buildHomePage() {
    final flightLogService = Provider.of<FlightLogService>(context);
    final locationService = Provider.of<LocationService>(context);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Location Error Message
            if (_locationErrorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.error),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.error),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Location Error',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.error,
                            ),
                          ),
                          Text(
                            _locationErrorMessage!,
                            style: const TextStyle(color: AppColors.error),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: AppColors.error),
                      onPressed: _checkLocationPermissions,
                    ),
                  ],
                ),
              ),

            // Student Dashboard Overview
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Flight Training Status',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Progress indicators
                    LinearProgressIndicator(
                      value: 0.65,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '65% Complete',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        Text(
                          '35 of 50 hours',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Stats grid
                    Row(
                      children: [
                        _buildStatCard(
                          icon: Icons.flight_takeoff,
                          title: 'Total Flights',
                          value: '24',
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        _buildStatCard(
                          icon: Icons.access_time,
                          title: 'Flight Hours',
                          value: '35h',
                          color: AppColors.accent,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildStatCard(
                          icon: Icons.calendar_today,
                          title: 'Next Flight',
                          value: 'Today, 3PM',
                          color: Colors.green,
                        ),
                        const SizedBox(width: 8),
                        _buildStatCard(
                          icon: Icons.account_balance_wallet,
                          title: 'Balance',
                          value: '\$350.00',
                          color: Colors.indigo,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Current Flight Status Card
            if (flightLogService.hasActiveFlightLog)
              Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Active Flight',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: AppColors.success,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Text(
                                  'In Progress',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Icon(Icons.access_time, color: Colors.white70),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Started',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                DateFormat('MMM dd, yyyy • hh:mm a').format(
                                  flightLogService.currentFlightLog!.startTime,
                                ),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.timer_outlined,
                            color: Colors.white70,
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Duration',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                _formatDuration(
                                  flightLogService.currentFlightDuration,
                                ),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      // Show location info if available
                      if (locationService.currentPosition != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                color: Colors.white70,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Current Location',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      '${locationService.currentPosition!.latitude.toStringAsFixed(6)}, ${locationService.currentPosition!.longitude.toStringAsFixed(6)}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 16),

                      // End Flight Button
                      CustomButton(
                        text: 'End Flight',
                        backgroundColor: Colors.white,
                        textColor: AppColors.primary,
                        icon: Icons.flight_land,
                        onPressed: _endFlight,
                        borderRadius: 30,
                      ),

                      const SizedBox(height: 8),

                      // View Details Button
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => FlightDetailScreen(
                                    flightLogId:
                                        flightLogService.currentFlightLog!.id,
                                  ),
                            ),
                          );
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('View Details'),
                      ),
                    ],
                  ),
                ),
              )
            else
              // No Active Flight
              Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(
                        Icons.flight_takeoff,
                        size: 60,
                        color: AppColors.primary.withOpacity(0.7),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No Active Flight',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Start a new flight to begin tracking your location and flight time.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 24),
                      CustomButton(
                        text: 'Start New Flight',
                        icon: Icons.flight_takeoff,
                        onPressed: _startFlight,
                        isLoading: false,
                        borderRadius: 30,
                      ),
                    ],
                  ),
                ),
              ),

            // Location Status Card
            if (locationService.currentPosition != null)
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Current Location',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildLocationInfoRow(
                        icon: Icons.location_on,
                        title: 'Coordinates',
                        value:
                            '${locationService.currentPosition!.latitude.toStringAsFixed(6)}, ${locationService.currentPosition!.longitude.toStringAsFixed(6)}',
                      ),
                      if (locationService.distanceFromSchool != null)
                        _buildLocationInfoRow(
                          icon: Icons.school,
                          title: 'Distance from School',
                          value: LocationUtils.formatDistance(
                            locationService.distanceFromSchool!,
                          ),
                          valueColor:
                              locationService.isNearSchool
                                  ? AppColors.success
                                  : AppColors.warning,
                        ),
                      _buildLocationInfoRow(
                        icon: Icons.speed,
                        title: 'Speed',
                        value:
                            '${(locationService.currentPosition!.speed * 3.6).toStringAsFixed(1)} km/h',
                      ),
                      if (locationService.currentPosition!.altitude != 0)
                        _buildLocationInfoRow(
                          icon: Icons.height,
                          title: 'Altitude',
                          value:
                              '${locationService.currentPosition!.altitude!.toStringAsFixed(1)} m',
                        ),
                      const SizedBox(height: 8),
                      Center(
                        child: TextButton.icon(
                          onPressed: () async {
                            await locationService.getCurrentPosition();
                            setState(() {});
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Refresh'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationInfoRow({
    required IconData icon,
    required String title,
    required String value,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: valueColor ?? AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: color.withOpacity(0.8),
                    ),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMySchedulePage() {
    return const MyScheduleScreen();
  }

  Widget _buildMyFlightsPage() {
    return MyFlightsOverviewScreen();
    // final flightLogService = Provider.of<FlightLogService>(context);

    // return SizedBox(
    //   height: MediaQuery.sizeOf(context).height,
    //   width: MediaQuery.sizeOf(context).width,
    //   child: SingleChildScrollView(
    //     child: FutureBuilder<List<FlightLogModel>>(
    //       future: flightLogService.getStudentFlightHistory(),
    //       builder: (context, snapshot) {
    //         if (snapshot.connectionState == ConnectionState.waiting) {
    //           return const Center(child: CircularProgressIndicator());
    //         }

    //         if (snapshot.hasError) {
    //           return Center(
    //             child: Text(
    //               'Error loading flight history: ${snapshot.error}',
    //               style: const TextStyle(color: AppColors.error),
    //             ),
    //           );
    //         }

    //         final flightLogs = snapshot.data ?? [];

    //         if (flightLogs.isEmpty) {
    //           return Center(
    //             child: Column(
    //               mainAxisAlignment: MainAxisAlignment.start,
    //               children: [
    //                 Icon(
    //                   Icons.flight,
    //                   size: 64,
    //                   color: AppColors.textSecondary.withOpacity(0.5),
    //                 ),
    //                 const SizedBox(height: 16),
    //                 const Text(
    //                   'No Flight History',
    //                   style: TextStyle(
    //                     fontSize: 18,
    //                     fontWeight: FontWeight.bold,
    //                     color: AppColors.textPrimary,
    //                   ),
    //                 ),
    //                 const SizedBox(height: 8),
    //                 const Text(
    //                   'Your flights will appear here once you complete them.',
    //                   style: TextStyle(color: AppColors.textSecondary),
    //                 ),
    //               ],
    //             ),
    //           );
    //         }

    //         return ListView.builder(
    //           physics: const NeverScrollableScrollPhysics(),
    //           shrinkWrap: true,
    //           padding: const EdgeInsets.all(16),
    //           itemCount: flightLogs.length,
    //           itemBuilder: (context, index) {
    //             final flightLog = flightLogs[index];
    //             final isActive = flightLog.status == 'in-progress';

    //             return Card(
    //               margin: const EdgeInsets.only(bottom: 12),
    //               shape: RoundedRectangleBorder(
    //                 borderRadius: BorderRadius.circular(12),
    //               ),
    //               elevation: isActive ? 4 : 2,
    //               child: InkWell(
    //                 onTap: () {
    //                   Navigator.push(
    //                     context,
    //                     MaterialPageRoute(
    //                       builder:
    //                           (context) =>
    //                               FlightDetailScreen(flightLogId: flightLog.id),
    //                     ),
    //                   );
    //                 },
    //                 borderRadius: BorderRadius.circular(12),
    //                 child: Container(
    //                   decoration: BoxDecoration(
    //                     borderRadius: BorderRadius.circular(12),
    //                     border:
    //                         isActive
    //                             ? Border.all(color: AppColors.primary, width: 2)
    //                             : null,
    //                   ),
    //                   child: Padding(
    //                     padding: const EdgeInsets.all(16),
    //                     child: Column(
    //                       crossAxisAlignment: CrossAxisAlignment.start,
    //                       children: [
    //                         Row(
    //                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
    //                           children: [
    //                             Text(
    //                               DateFormat(
    //                                 'MMM dd, yyyy',
    //                               ).format(flightLog.startTime),
    //                               style: const TextStyle(
    //                                 fontWeight: FontWeight.bold,
    //                                 fontSize: 16,
    //                               ),
    //                             ),
    //                             Container(
    //                               padding: const EdgeInsets.symmetric(
    //                                 horizontal: 8,
    //                                 vertical: 4,
    //                               ),
    //                               decoration: BoxDecoration(
    //                                 color:
    //                                     isActive
    //                                         ? AppColors.primary.withOpacity(0.1)
    //                                         : AppColors.success.withOpacity(
    //                                           0.1,
    //                                         ),
    //                                 borderRadius: BorderRadius.circular(20),
    //                               ),
    //                               child: Text(
    //                                 isActive ? 'In Progress' : 'Completed',
    //                                 style: TextStyle(
    //                                   fontSize: 12,
    //                                   fontWeight: FontWeight.bold,
    //                                   color:
    //                                       isActive
    //                                           ? AppColors.primary
    //                                           : AppColors.success,
    //                                 ),
    //                               ),
    //                             ),
    //                           ],
    //                         ),
    //                         const SizedBox(height: 12),
    //                         Row(
    //                           children: [
    //                             _buildFlightInfoItem(
    //                               icon: Icons.access_time,
    //                               title: 'Start Time',
    //                               value: DateFormat(
    //                                 'hh:mm a',
    //                               ).format(flightLog.startTime),
    //                             ),
    //                             const SizedBox(width: 24),
    //                             _buildFlightInfoItem(
    //                               icon: Icons.timer,
    //                               title: 'Duration',
    //                               value: flightLog.durationString,
    //                             ),
    //                           ],
    //                         ),
    //                         const SizedBox(height: 12),
    //                         Row(
    //                           children: [
    //                             _buildFlightInfoItem(
    //                               icon: Icons.place,
    //                               title: 'Locations',
    //                               value:
    //                                   '${flightLog.flightPath.length} points',
    //                             ),
    //                             const SizedBox(width: 24),
    //                             if (flightLog.notes != null &&
    //                                 flightLog.notes!.isNotEmpty)
    //                               _buildFlightInfoItem(
    //                                 icon: Icons.notes,
    //                                 title: 'Notes',
    //                                 value: 'Available',
    //                               ),
    //                           ],
    //                         ),
    //                       ],
    //                     ),
    //                   ),
    //                 ),
    //               ),
    //             );
    //           },
    //         );
    //       },
    //     ),
    //   ),
    // );
  }

  Widget _buildWalletPage() {
    return const WalletScreen();
  }

  Widget _buildTransactionItem({
    required String title,
    required String date,
    required String amount,
    required bool isDebit,
  }) {
    return ListTile(
      title: Text(title),
      subtitle: Text(date),
      trailing: Text(
        amount,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: isDebit ? Colors.red : Colors.green,
        ),
      ),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: (isDebit ? Colors.red : Colors.green).withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          isDebit ? Icons.remove : Icons.add,
          color: isDebit ? Colors.red : Colors.green,
        ),
      ),
    );
  }

  Widget _buildPaymentMethodItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDefault,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        if (isDefault)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Default',
              style: TextStyle(
                color: AppColors.success,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildProfilePage() {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;

    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Profile Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Profile Image
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: AppColors.primary,
                      child: Text(
                        user.firstName[0] + user.lastName[0],
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // User Name
                    Text(
                      user.fullName,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // User Email
                    Text(
                      user.email,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 8),

                    // Role Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.studentColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Student',
                        style: TextStyle(
                          color: AppColors.studentColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Edit Profile Button
                    CustomButton(
                      text: 'Edit Profile',
                      icon: Icons.edit,
                      isOutlined: true,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ProfileScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // App Settings
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Settings',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Settings List
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildSettingsItem(
                    icon: Icons.notifications,
                    title: 'Notifications',
                    subtitle: 'Manage notification settings',
                    onTap: () {
                      // TODO: Navigate to notification settings
                    },
                  ),
                  const Divider(height: 1),
                  _buildSettingsItem(
                    icon: Icons.security,
                    title: 'Privacy & Security',
                    subtitle: 'Manage your data and security settings',
                    onTap: () {
                      // TODO: Navigate to privacy settings
                    },
                  ),
                  const Divider(height: 1),
                  _buildSettingsItem(
                    icon: Icons.help_outline,
                    title: 'Help & Support',
                    subtitle: 'Contact support or view FAQs',
                    onTap: () {
                      // TODO: Navigate to help & support
                    },
                  ),
                  const Divider(height: 1),
                  _buildSettingsItem(
                    icon: Icons.info_outline,
                    title: 'About',
                    subtitle: 'App version and information',
                    onTap: () {
                      // TODO: Show about dialog
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Logout Button
            CustomButton(
              text: 'Logout',
              icon: Icons.logout,
              backgroundColor: Colors.red,
              onPressed: _signOut,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlightInfoItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return '${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_pages[_selectedIndex]),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Navigate to notifications screen
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildHomePage(),
          _buildMySchedulePage(),
          _buildMyFlightsPage(),
          _buildWalletPage(),
          _buildProfilePage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed, // Needed for more than 3 items
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_outlined),
            activeIcon: Icon(Icons.calendar_month),
            label: 'Schedule',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.flight_outlined),
            activeIcon: Icon(Icons.flight),
            label: 'Flights',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_outlined),
            activeIcon: Icon(Icons.account_balance_wallet),
            label: 'Wallet',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
