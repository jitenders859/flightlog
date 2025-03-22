import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../constants/colors.dart';
import '../../services/notification_service.dart';
import '../../widgets/custom_button.dart';
import '../../services/database_service.dart';
import '../student/flight_detail_screen.dart';
import '../../models/flight_log_model.dart';
import '../../login_screen.dart';
import '../../models/user_model.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';


import 'flight_monitoring_screen.dart';

class DispatchHomeScreen extends StatefulWidget {
  const DispatchHomeScreen({Key? key}) : super(key: key);

  @override
  State<DispatchHomeScreen> createState() => _DispatchHomeScreenState();
}

class _DispatchHomeScreenState extends State<DispatchHomeScreen> {
  int _selectedIndex = 0;
  final List<String> _pages = ['Active Flights', 'All Students', 'Profile'];
  List<FlightLogModel> _activeFlights = [];
  List<UserModel> _students = [];
  bool _isLoadingFlights = true;
  bool _isLoadingStudents = true;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }
  
  Future<void> _loadInitialData() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final databaseService = Provider.of<DatabaseService>(context, listen: false);
    final notificationService = Provider.of<NotificationService>(context, listen: false);
    
    if (authService.currentUser != null) {
      databaseService.initialize(
        authService.currentUser!.id,
        authService.currentUser!.role,
      );
      
      await notificationService.initialize(
        userId: authService.currentUser!.id,
      );
      
      _loadActiveFlights();
      _loadStudents();
    }
  }
  
  Future<void> _loadActiveFlights() async {
    setState(() {
      _isLoadingFlights = true;
      _errorMessage = null;
    });
    
    try {
      final databaseService = Provider.of<DatabaseService>(context, listen: false);
      _activeFlights = await databaseService.getActiveFlightLogs().first;
      
    } catch (e) {
      _errorMessage = 'Error loading active flights: $e';
    } finally {
      setState(() {
        _isLoadingFlights = false;
      });
    }
  }
  
  Future<void> _loadStudents() async {
    setState(() {
      _isLoadingStudents = true;
    });
    
    try {
      final databaseService = Provider.of<DatabaseService>(context, listen: false);
      _students = await databaseService.getAllStudents();
      
    } catch (e) {
      print('Error loading students: $e');
    } finally {
      setState(() {
        _isLoadingStudents = false;
      });
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
  
  Widget _buildNotificationDialog() {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();
    
    return AlertDialog(
      title: const Text('Send Notification'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
  
  Widget _buildActiveFlightsPage() {
    if (_isLoadingFlights) {
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
            const SizedBox(height: 24),
            CustomButton(
              text: 'Refresh',
              icon: Icons.refresh,
              isOutlined: true,
              onPressed: _loadActiveFlights,
            ),
          ],
        ),
      );
    }
    
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: AppColors.info),
              const SizedBox(width: 8),
              Expanded(
                child: RichText(
                  text: const TextSpan(
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                    children: [
                      TextSpan(
                        text: 'Active Flights: ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text: 'Monitor all flights and send notifications to students',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FlightMonitoringScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                child: const Text('Monitor All'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _activeFlights.length,
            itemBuilder: (context, index) {
              final flight = _activeFlights[index];
              
              return FutureBuilder<UserModel?>(
                future: Provider.of<DatabaseService>(context).getUser(flight.studentId),
                builder: (context, snapshot) {
                  final student = snapshot.data;
                  final studentName = student?.fullName ?? 'Loading...';
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: AppColors.dispatchColor.withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: AppColors.studentColor,
                                    child: Text(
                                      student != null
                                          ? student.firstName[0] + student.lastName[0]
                                          : '??',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        studentName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Text(
                                        'Flight ID: ${flight.id.substring(0, 6)}...',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.warning.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: AppColors.warning,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Text(
                                      'In Flight',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.warning,
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
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Start Time',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    Text(
                                      DateFormat('hh:mm a').format(flight.startTime),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Duration',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    Text(
                                      _calculateDuration(flight.startTime),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Location Points',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    Text(
                                      '${flight.flightPath.length}',
                                      style: const TextStyle(
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
                                  label: const Text('Details'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.primary,
                                    side: const BorderSide(color: AppColors.primary),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _sendNotification(flight.studentId, flight.id),
                                  icon: const Icon(Icons.notifications_active),
                                  label: const Text('Notify'),
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
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildStudentsPage() {
    if (_isLoadingStudents) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_students.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people,
              size: 64,
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Students Found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'There are no students registered in the system.',
              style: TextStyle(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _students.length,
      itemBuilder: (context, index) {
        final student = _students[index];
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: CircleAvatar(
              backgroundColor: AppColors.studentColor,
              child: Text(
                student.firstName[0] + student.lastName[0],
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              student.fullName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(student.email),
                if (student.phoneNumber != null && student.phoneNumber!.isNotEmpty)
                  Text('Phone: ${student.phoneNumber}'),
              ],
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // TODO: Navigate to student flight history or details
            },
          ),
        );
      },
    );
  }
  
  Widget _buildProfilePage() {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;
    
    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }
    
    return Padding(
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
                    backgroundColor: AppColors.dispatchColor,
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
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Role Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.dispatchColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Dispatch',
                      style: TextStyle(
                        color: AppColors.dispatchColor,
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
                      // TODO: Navigate to edit profile screen
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
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.notifications_outlined, color: AppColors.primary),
                  ),
                  title: const Text('Notification Templates'),
                  subtitle: const Text('Manage notification templates'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    // TODO: Navigate to notification templates
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.location_on_outlined, color: AppColors.primary),
                  ),
                  title: const Text('School Location'),
                  subtitle: const Text('Update school coordinates'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    // TODO: Navigate to school location settings
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
    );
  }
  
  String _calculateDuration(DateTime startTime) {
    final Duration duration = DateTime.now().difference(startTime);
    
    final int hours = duration.inHours;
    final int minutes = duration.inMinutes % 60;
    
    return '${hours}h ${minutes}m';
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_pages[_selectedIndex]),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              if (_selectedIndex == 0) {
                _loadActiveFlights();
              } else if (_selectedIndex == 1) {
                _loadStudents();
              }
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildActiveFlightsPage(),
          _buildStudentsPage(),
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
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.flight_takeoff_outlined),
            activeIcon: Icon(Icons.flight_takeoff),
            label: 'Active Flights',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: 'Students',
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