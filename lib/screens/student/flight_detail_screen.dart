import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../services/database_service.dart';
import '../../models/flight_log_model.dart';
import '../../models/user_model.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class FlightDetailScreen extends StatefulWidget {
  final String flightLogId;
  
  const FlightDetailScreen({
    Key? key,
    required this.flightLogId,
  }) : super(key: key);

  @override
  State<FlightDetailScreen> createState() => _FlightDetailScreenState();
}

class _FlightDetailScreenState extends State<FlightDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  FlightLogModel? _flightLog;
  UserModel? _student;
  UserModel? _teacher;
  bool _isLoading = true;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadFlightDetails();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _loadFlightDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final databaseService = Provider.of<DatabaseService>(context, listen: false);
      
      // Load flight log
      _flightLog = await databaseService.getFlightLog(widget.flightLogId);
      
      if (_flightLog != null) {
        // Load student information
        _student = await databaseService.getUser(_flightLog!.studentId);
        
        // Load teacher information if available
        if (_flightLog!.teacherId != null) {
          _teacher = await databaseService.getUser(_flightLog!.teacherId!);
        }
      } else {
        _errorMessage = 'Flight log not found';
      }
    } catch (e) {
      _errorMessage = 'Error loading flight details: $e';
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flight Details'),
        bottom: _isLoading || _flightLog == null 
            ? null 
            : TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Overview'),
                  Tab(text: 'Flight Path'),
                  Tab(text: 'Notes'),
                ],
              ),
      ),
      body: _buildBody(),
    );
  }
  
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(
                color: AppColors.error,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadFlightDetails,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    
    if (_flightLog == null) {
      return const Center(
        child: Text('Flight log not found'),
      );
    }
    
    return TabBarView(
      controller: _tabController,
      children: [
        _buildOverviewTab(),
        _buildFlightPathTab(),
        _buildNotesTab(),
      ],
    );
  }
  
  Widget _buildOverviewTab() {
    final bool isActive = _flightLog!.status == 'in-progress';
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Card
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: isActive 
                      ? [AppColors.primary, AppColors.primaryDark] 
                      : [AppColors.success, AppColors.success.withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Flight Status',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
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
                              decoration: BoxDecoration(
                                color: isActive ? Colors.amber : Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isActive ? 'In Progress' : 'Completed',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
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
                      _buildStatusInfoItem(
                        icon: Icons.calendar_today,
                        title: 'Date',
                        value: DateFormat('MMM dd, yyyy').format(_flightLog!.startTime),
                      ),
                      const SizedBox(width: 24),
                      _buildStatusInfoItem(
                        icon: Icons.access_time,
                        title: 'Started',
                        value: DateFormat('hh:mm a').format(_flightLog!.startTime),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildStatusInfoItem(
                        icon: Icons.timer,
                        title: 'Duration',
                        value: _flightLog!.durationString,
                      ),
                      const SizedBox(width: 24),
                      if (_flightLog!.endTime != null)
                        _buildStatusInfoItem(
                          icon: Icons.flight_land,
                          title: 'Ended',
                          value: DateFormat('hh:mm a').format(_flightLog!.endTime!),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // People Involved Card
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
                    'People',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Student Info
                  if (_student != null)
                    _buildPersonInfoItem(
                      icon: Icons.school,
                      title: 'Student',
                      name: _student!.fullName,
                      subtitle: _student!.email,
                      iconColor: AppColors.studentColor,
                    ),
                  
                  if (_student != null && _teacher != null)
                    const Divider(height: 24),
                  
                  // Teacher Info (if available)
                  if (_teacher != null)
                    _buildPersonInfoItem(
                      icon: Icons.person,
                      title: 'Teacher',
                      name: _teacher!.fullName,
                      subtitle: _teacher!.email,
                      iconColor: AppColors.teacherColor,
                    ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Flight Stats Card
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
                    'Flight Stats',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Location Points
                  _buildStatItem(
                    icon: Icons.location_on,
                    title: 'Location Points',
                    value: '${_flightLog!.flightPath.length}',
                  ),
                  
                  const Divider(height: 24),
                  
                  // Flight Duration
                  _buildStatItem(
                    icon: Icons.timer,
                    title: 'Flight Duration',
                    value: _flightLog!.durationString,
                  ),
                  
                  if (_flightLog!.flightPath.isNotEmpty && _flightLog!.flightPath.length > 1) ...[
                    const Divider(height: 24),
                    
                    // Max Altitude (if available)
                    if (_flightLog!.flightPath.any((point) => point.altitude != null))
                      _buildStatItem(
                        icon: Icons.height,
                        title: 'Max Altitude',
                        value: '${_calculateMaxAltitude().toStringAsFixed(1)} m',
                      ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFlightPathTab() {
    if (_flightLog!.flightPath.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off,
              size: 64,
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Flight Path Data',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Location data for this flight is not available.',
              style: TextStyle(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                    'Flight Path Data',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_flightLog!.flightPath.length} location points recorded',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  const Text(
                    'Flight Map View',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.backgroundDark,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text(
                        'Map visualization would appear here',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          const Text(
            'Location Points',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 8),
          
          Expanded(
            child: ListView.builder(
              itemCount: _flightLog!.flightPath.length,
              itemBuilder: (context, index) {
                final locationPoint = _flightLog!.flightPath[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Lat: ${locationPoint.latitude.toStringAsFixed(6)}, Lon: ${locationPoint.longitude.toStringAsFixed(6)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Time: ${DateFormat('hh:mm:ss a').format(locationPoint.timestamp)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              if (locationPoint.altitude != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  'Altitude: ${locationPoint.altitude!.toStringAsFixed(1)} m',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildNotesTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                    'Flight Notes',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  if (_flightLog!.notes != null && _flightLog!.notes!.isNotEmpty)
                    Text(_flightLog!.notes!)
                  else
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          'No notes available for this flight',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          
          if (_flightLog!.status == 'in-progress')
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                'Notes can be added when the flight is completed',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildStatusInfoItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.white.withOpacity(0.7)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPersonInfoItem({
    required IconData icon,
    required String title,
    required String name,
    required String subtitle,
    required Color iconColor,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor),
        ),
        const SizedBox(width: 12),
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
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
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
      ],
    );
  }
  
  Widget _buildStatItem({
    required IconData icon,
    required String title,
    required String value,
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
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  double _calculateMaxAltitude() {
    double maxAltitude = 0;
    
    for (var point in _flightLog!.flightPath) {
      if (point.altitude != null && point.altitude! > maxAltitude) {
        maxAltitude = point.altitude!;
      }
    }
    
    return maxAltitude;
  }
}