import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../constants/colors.dart';
import '../../login_screen.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'user_management_screen.dart';
import 'flight_logs_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({Key? key}) : super(key: key);

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _selectedIndex = 0;
  final List<String> _pages = ['Dashboard', 'Users', 'Settings'];

  // Dashboard stats
  int _activeFlightsCount = 0;
  int _studentCount = 0;
  int _teacherCount = 0;
  int _dispatchCount = 0;
  int _totalFlightLogs = 0;

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final databaseService = Provider.of<DatabaseService>(
        context,
        listen: false,
      );

      if (authService.currentUser != null) {
        databaseService.initialize(
          authService.currentUser!.id,
          authService.currentUser!.role,
        );
      }

      // Get active flights
      final activeFlights = await databaseService.getActiveFlightLogs().first;
      _activeFlightsCount = activeFlights.length;

      // Get user counts
      final students = await databaseService.getAllStudents();
      _studentCount = students.length;

      final teachers = await databaseService.getAllTeachers();
      _teacherCount = teachers.length;

      final dispatchs = await databaseService.getAllDispatchers();
      _dispatchCount = dispatchs.length;

      // TODO: Implement getting total flight logs once we have that method
      _totalFlightLogs = 0;
    } catch (e) {
      _errorMessage = 'Error loading dashboard data: $e';
    } finally {
      setState(() {
        _isLoading = false;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_pages[_selectedIndex]),
        actions: [
          if (_selectedIndex == 0)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadDashboardData,
            ),
          IconButton(icon: const Icon(Icons.logout), onPressed: _signOut),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildDashboardPage(),
          _buildUsersPage(),
          _buildSettingsPage(),
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
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: 'Users',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardPage() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(color: AppColors.error, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadDashboardData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome card
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: [
                    AppColors.adminColor,
                    AppColors.adminColor.withOpacity(0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Welcome to Admin Dashboard',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Today is ${DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now())}',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Active Flights: $_activeFlightsCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Stats Grid
          const Text(
            'System Statistics',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 12),

          // User stats
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Students',
                  value: _studentCount.toString(),
                  icon: Icons.school,
                  color: AppColors.studentColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  title: 'Teachers',
                  value: _teacherCount.toString(),
                  icon: Icons.person,
                  color: AppColors.teacherColor,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Dispatch',
                  value: _dispatchCount.toString(),
                  icon: Icons.headset_mic,
                  color: AppColors.dispatchColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  title: 'Total Flights',
                  value: _totalFlightLogs.toString(),
                  icon: Icons.flight,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Quick actions
          const Text(
            'Quick Actions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 12),

          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildActionItem(
                    icon: Icons.person_add,
                    title: 'Add New User',
                    subtitle:
                        'Create a new student, teacher, or dispatch account',
                    onTap: () {
                      // TODO: Navigate to add user screen
                    },
                  ),
                  const Divider(height: 24),
                  _buildActionItem(
                    icon: Icons.flight_takeoff,
                    title: 'View All Flight Logs',
                    subtitle: 'Access complete flight history',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FlightLogsScreen(),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 24),
                  _buildActionItem(
                    icon: Icons.location_on,
                    title: 'Update School Location',
                    subtitle:
                        'Change the school coordinates for proximity alerts',
                    onTap: () {
                      // TODO: Navigate to school location screen
                    },
                  ),
                  const Divider(height: 24),
                  _buildActionItem(
                    icon: Icons.settings,
                    title: 'System Settings',
                    subtitle: 'Manage application settings and configurations',
                    onTap: () {
                      setState(() {
                        _selectedIndex = 2; // Navigate to settings tab
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersPage() {
    return const UserManagementScreen();
  }

  Widget _buildSettingsPage() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'System Settings',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 16),

          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildSettingsItem(
                  icon: Icons.location_on,
                  title: 'School Location',
                  subtitle: 'Update the school\'s coordinates',
                  onTap: () {
                    // TODO: Navigate to school location settings
                  },
                ),
                const Divider(height: 1),
                _buildSettingsItem(
                  icon: Icons.timer,
                  title: 'Flight Time Limits',
                  subtitle: 'Set maximum flight duration and warning times',
                  onTap: () {
                    // TODO: Navigate to flight time settings
                  },
                ),
                const Divider(height: 1),
                _buildSettingsItem(
                  icon: Icons.notifications,
                  title: 'Notification Settings',
                  subtitle: 'Configure system notification behavior',
                  onTap: () {
                    // TODO: Navigate to notification settings
                  },
                ),
                const Divider(height: 1),
                _buildSettingsItem(
                  icon: Icons.security,
                  title: 'Security Settings',
                  subtitle: 'Manage user permissions and access levels',
                  onTap: () {
                    // TODO: Navigate to security settings
                  },
                ),
                const Divider(height: 1),
                _buildSettingsItem(
                  icon: Icons.backup,
                  title: 'Backup & Restore',
                  subtitle: 'Export and import system data',
                  onTap: () {
                    // TODO: Navigate to backup settings
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          const Text(
            'System Information',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 16),

          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildInfoRow(
                    title: 'App Version',
                    value: AppConstants.appVersion,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(title: 'Database', value: 'Firebase Firestore'),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    title: 'Authentication',
                    value: 'Firebase Auth',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                Icon(icon, color: color),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.adminColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppColors.adminColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
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

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.adminColor.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.adminColor),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  Widget _buildInfoRow({required String title, required String value}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(color: AppColors.textSecondary)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
