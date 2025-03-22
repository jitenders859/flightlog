import 'dart:async';
import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../models/flight_log_model.dart';
import '../../models/user_model.dart';
import '../student/flight_detail_screen.dart';
import '../../services/database_service.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';


class FlightMonitoringScreen extends StatefulWidget {
  const FlightMonitoringScreen({Key? key}) : super(key: key);

  @override
  State<FlightMonitoringScreen> createState() => _FlightMonitoringScreenState();
}

class _FlightMonitoringScreenState extends State<FlightMonitoringScreen> {
  List<FlightLogModel> _activeFlights = [];
  bool _isLoading = true;
  String? _errorMessage;
  Timer? _refreshTimer;
  Map<String, UserModel?> _studentCache = {};
  
  @override
  void initState() {
    super.initState();
    _loadActiveFlights();
    
    // Set up a timer to refresh data every minute
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _loadActiveFlights();
    });
  }
  
  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
  
  Future<void> _loadActiveFlights() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final databaseService = Provider.of<DatabaseService>(context, listen: false);
      _activeFlights = await databaseService.getActiveFlightLogs().first;
      
      // Preload student data
      for (var flight in _activeFlights) {
        if (!_studentCache.containsKey(flight.studentId)) {
          _studentCache[flight.studentId] = await databaseService.getUser(flight.studentId);
        }
      }
      
    } catch (e) {
      _errorMessage = 'Error loading active flights: $e';
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _sendNotification(String studentId, String flightLogId) async {
    // Show dialog to compose notification
    final result = await showDialog<Map<String, String?>>(
      context: context,
      builder: (context) => _buildNotificationDialog(),
    );
    
    if (result != null && result['title'] != null && result['body'] != null) {
      try {
        final databaseService = Provider.of<DatabaseService>(context, listen: false);
        
        await databaseService.sendNotification(
          userId: studentId,
          title: result['title']!,
          body: result['body']!,
          type: 'custom',
          additionalData: {
            'flightLogId': flightLogId,
            'sentBy': 'dispatch',
          },
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification sent successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send notification: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
  
  Future<void> _sendBulkNotification() async {
    if (_activeFlights.isEmpty) return;
    
    // Show dialog to compose notification
    final result = await showDialog<Map<String, String?>>(
      context: context,
      builder: (context) => _buildNotificationDialog(isBulk: true),
    );
    
    if (result != null && result['title'] != null && result['body'] != null) {
      try {
        final databaseService = Provider.of<DatabaseService>(context, listen: false);
        final List<Future> futures = [];
        
        for (var flight in _activeFlights) {
          futures.add(
            databaseService.sendNotification(
              userId: flight.studentId,
              title: result['title']!,
              body: result['body']!,
              type: 'custom',
              additionalData: {
                'flightLogId': flight.id,
                'sentBy': 'dispatch',
                'isBulk': true,
              },
            )
          );
        }
        
        await Future.wait(futures);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Notification sent to ${_activeFlights.length} students'),
            backgroundColor: AppColors.success,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send notifications: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
  
  Widget _buildNotificationDialog({bool isBulk = false}) {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();
    
    // Default templates
    const List<Map<String, String>> templates = [
      {
        'title': 'Return To School',
        'body': 'Please return to school as soon as possible.',
      },
      {
        'title': 'Weather Alert',
        'body': 'Weather conditions are changing. Please monitor and consider returning soon.',
      },
      {
        'title': 'Time Check',
        'body': 'Your flight has been active for a while. Please check your remaining time.',
      },
    ];
    
    return AlertDialog(
      title: Text(isBulk ? 'Send Bulk Notification' : 'Send Notification'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isBulk)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.warning),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: AppColors.warning, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This will send a notification to all ${_activeFlights.length} active flights',
                        style: const TextStyle(
                          color: AppColors.warning,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          TextField(
            controller: titleController,
            decoration: const InputDecoration(
              labelText: 'Notification Title',
              hintText: 'E.g., Return to School',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: bodyController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Notification Message',
              hintText: 'Enter your message here...',
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Quick Templates:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: templates.map((template) {
              return ElevatedButton(
                onPressed: () {
                  titleController.text = template['title']!;
                  bodyController.text = template['body']!;
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  foregroundColor: AppColors.primary,
                  elevation: 0,
                ),
                child: Text(template['title']!),
              );
            }).toList(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (titleController.text.isNotEmpty && bodyController.text.isNotEmpty) {
              Navigator.pop(context, {
                'title': titleController.text,
                'body': bodyController.text,
              });
            }
          },
          child: const Text('Send'),
        ),
      ],
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flight Monitoring'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadActiveFlights,
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: _activeFlights.isNotEmpty 
          ? FloatingActionButton.extended(
              onPressed: _sendBulkNotification,
              icon: const Icon(Icons.campaign),
              label: const Text('Notify All'),
              backgroundColor: AppColors.dispatchColor,
            )
          : null,
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
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadActiveFlights,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    
    if (_activeFlights.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.flight_takeoff,
              size: 64,
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Active Flights',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'There are no students currently in flight.',
              style: TextStyle(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: AppColors.dispatchColor.withOpacity(0.1),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: AppColors.dispatchColor),
              const SizedBox(width: 8),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                    ),
                    children: [
                      const TextSpan(
                        text: 'Active Flights: ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text: '${_activeFlights.length}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.dispatchColor,
                        ),
                      ),
                      const TextSpan(
                        text: ' | Last updated: ',
                      ),
                      TextSpan(
                        text: DateFormat('hh:mm a').format(DateTime.now()),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _activeFlights.length,
            itemBuilder: (context, index) {
              final flight = _activeFlights[index];
              final student = _studentCache[flight.studentId];
              
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    // Header with student info and status
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: AppColors.dispatchColor,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: Colors.white,
                            child: Text(
                              student != null
                                  ? student.firstName[0] + student.lastName[0]
                                  : '??',
                              style: const TextStyle(
                                color: AppColors.dispatchColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  student?.fullName ?? 'Loading...',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                                if (student != null)
                                  Text(
                                    student.email,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Text(
                                  'In Flight',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Flight details
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // Flight times
                          Row(
                            children: [
                              Expanded(
                                child: _buildInfoItem(
                                  icon: Icons.access_time,
                                  title: 'Start Time',
                                  value: DateFormat('hh:mm a').format(flight.startTime),
                                ),
                              ),
                              Expanded(
                                child: _buildInfoItem(
                                  icon: Icons.timer,
                                  title: 'Duration',
                                  value: _calculateDuration(flight.startTime),
                                ),
                              ),
                              Expanded(
                                child: _buildInfoItem(
                                  icon: Icons.calendar_today,
                                  title: 'Date',
                                  value: DateFormat('MMM dd, yyyy').format(flight.startTime),
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Location info
                          Row(
                            children: [
                              Expanded(
                                child: _buildInfoItem(
                                  icon: Icons.place,
                                  title: 'Location Points',
                                  value: '${flight.flightPath.length}',
                                ),
                              ),
                              Expanded(
                                child: _buildInfoItem(
                                  icon: Icons.route,
                                  title: 'Flight ID',
                                  value: flight.id.substring(0, 8),
                                ),
                              ),
                              if (flight.teacherId != null)
                                Expanded(
                                  child: _buildInfoItem(
                                    icon: Icons.person,
                                    title: 'Teacher',
                                    value: 'Assigned',
                                  ),
                                ),
                            ],
                          ),
                          
                          const SizedBox(height: 16),
                          const Divider(height: 1),
                          const SizedBox(height: 16),
                          
                          // Action buttons
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => FlightDetailScreen(
                                          flightLogId: flight.id,
                                        ),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.visibility),
                                  label: const Text('View Details'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.dispatchColor,
                                    side: const BorderSide(color: AppColors.dispatchColor),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _sendNotification(flight.studentId, flight.id),
                                  icon: const Icon(Icons.notifications_active),
                                  label: const Text('Send Alert'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.dispatchColor,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 4),
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
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  String _calculateDuration(DateTime startTime) {
    final Duration duration = DateTime.now().difference(startTime);
    
    final int hours = duration.inHours;
    final int minutes = duration.inMinutes % 60;
    
    return '${hours}h ${minutes}m';
  }
}