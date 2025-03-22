import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../login_screen.dart';
import '../../models/flight_log_model.dart';
import '../student/flight_detail_screen.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_button.dart';
import '../../services/database_service.dart';
import '../../models/user_model.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';


class TeacherHomeScreen extends StatefulWidget {
  const TeacherHomeScreen({Key? key}) : super(key: key);

  @override
  State<TeacherHomeScreen> createState() => _TeacherHomeScreenState();
}

class _TeacherHomeScreenState extends State<TeacherHomeScreen> {
  int _selectedIndex = 0;
  final List<String> _pages = ['Students', 'Active Flights', 'Profile'];
  List<UserModel> _students = [];
  List<FlightLogModel> _activeFlights = [];
  bool _isLoadingStudents = true;
  bool _isLoadingFlights = true;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }
  
  Future<void> _loadInitialData() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final databaseService = Provider.of<DatabaseService>(context, listen: false);
    
    if (authService.currentUser != null) {
      databaseService.initialize(
        authService.currentUser!.id,
        authService.currentUser!.role,
      );
      
      _loadStudents();
      _loadActiveFlights();
    }
  }
  
  Future<void> _loadStudents() async {
    setState(() {
      _isLoadingStudents = true;
      _errorMessage = null;
    });
    
    try {
      final databaseService = Provider.of<DatabaseService>(context, listen: false);
      _students = await databaseService.getAllStudents();
      
    } catch (e) {
      _errorMessage = 'Error loading students: $e';
    } finally {
      setState(() {
        _isLoadingStudents = false;
      });
    }
  }
  
  Future<void> _loadActiveFlights() async {
    setState(() {
      _isLoadingFlights = true;
    });
    
    try {
      final databaseService = Provider.of<DatabaseService>(context, listen: false);
      _activeFlights = await databaseService.getActiveFlightLogs().first;
      
    } catch (e) {
      print('Error loading active flights: $e');
    } finally {
      setState(() {
        _isLoadingFlights = false;
      });
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
  
  Widget _buildStudentsPage() {
    if (_isLoadingStudents) {
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
              onPressed: _loadStudents,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    
    if (_students.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.school,
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
          child: ListTile(
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
            subtitle: Text(student.email),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // Navigate to student details screen
              // TODO: Implement student details screen
            },
          ),
        );
      },
    );
  }
  
  Widget _buildActiveFlightsPage() {
    if (_isLoadingFlights) {
      return const Center(child: CircularProgressIndicator());
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
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _activeFlights.length,
      itemBuilder: (context, index) {
        final flight = _activeFlights[index];
        
        return FutureBuilder<UserModel?>(
          future: Provider.of<DatabaseService>(context).getUser(flight.studentId),
          builder: (context, snapshot) {
            final student = snapshot.data;
            final studentName = student?.fullName ?? 'Loading...';
            
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.primary, width: 1),
              ),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FlightDetailScreen(
                        flightLogId: flight.id,
                      ),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              studentName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Text(
                                  'In Flight',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.access_time, 
                            size: 16, 
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Started: ${DateFormat('hh:mm a').format(flight.startTime)}',
                            style: const TextStyle(color: AppColors.textSecondary),
                          ),
                          const SizedBox(width: 16),
                          Icon(Icons.calendar_today, 
                            size: 16, 
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('MMM dd, yyyy').format(flight.startTime),
                            style: const TextStyle(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
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
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 8),
                      Center(
                        child: ElevatedButton.icon(
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
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
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
                    backgroundColor: AppColors.teacherColor,
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
                      color: AppColors.teacherColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Teacher',
                      style: TextStyle(
                        color: AppColors.teacherColor,
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
                _loadStudents();
              } else if (_selectedIndex == 1) {
                _loadActiveFlights();
              }
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildStudentsPage(),
          _buildActiveFlightsPage(),
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
            icon: Icon(Icons.school_outlined),
            activeIcon: Icon(Icons.school),
            label: 'Students',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.flight_takeoff_outlined),
            activeIcon: Icon(Icons.flight_takeoff),
            label: 'Active Flights',
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