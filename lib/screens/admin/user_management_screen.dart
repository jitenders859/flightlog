import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import 'package:provider/provider.dart';

import '../../constants/app_constants.dart';
import '../../constants/colors.dart';
import '../../models/user_model.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_button.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({Key? key}) : super(key: key);

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<UserModel> _students = [];
  List<UserModel> _teachers = [];
  List<UserModel> _dispatchUsers = [];
  List<UserModel> _adminUsers = [];
  
  bool _isLoadingStudents = true;
  bool _isLoadingTeachers = true;
  bool _isLoadingDispatch = true;
  bool _isLoadingAdmins = true;
  
  String? _errorMessage;
  String _searchQuery = '';
  
  final TextEditingController _searchController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadUsers();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _loadUsers() async {
    await Future.wait([
      _loadStudents(),
      _loadTeachers(),
      _loadDispatchUsers(),
      _loadAdminUsers(),
    ]);
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
  
  Future<void> _loadTeachers() async {
    setState(() {
      _isLoadingTeachers = true;
    });
    
    try {
      final databaseService = Provider.of<DatabaseService>(context, listen: false);
      _teachers = await databaseService.getAllTeachers();
    } catch (e) {
      print('Error loading teachers: $e');
    } finally {
      setState(() {
        _isLoadingTeachers = false;
      });
    }
  }
  
  Future<void> _loadDispatchUsers() async {
    setState(() {
      _isLoadingDispatch = true;
    });
    
    try {
      // TODO: Replace with actual implementation once available
      // For now, we'll just simulate an empty list
      _dispatchUsers = [];
    } catch (e) {
      print('Error loading dispatch users: $e');
    } finally {
      setState(() {
        _isLoadingDispatch = false;
      });
    }
  }
  
  Future<void> _loadAdminUsers() async {
    setState(() {
      _isLoadingAdmins = true;
    });
    
    try {
      // TODO: Replace with actual implementation once available
      // For now, we'll just simulate an empty list
      _adminUsers = [];
    } catch (e) {
      print('Error loading admin users: $e');
    } finally {
      setState(() {
        _isLoadingAdmins = false;
      });
    }
  }
  
  Future<void> _updateUserStatus(UserModel user, bool isActive) async {
    try {
      final databaseService = Provider.of<DatabaseService>(context, listen: false);
      
      bool success = await databaseService.updateUserStatus(user.id, isActive);
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('User ${isActive ? 'activated' : 'deactivated'} successfully'),
            backgroundColor: isActive ? AppColors.success : AppColors.warning,
          ),
        );
        
        // Refresh the user list based on the current tab
        switch (_tabController.index) {
          case 0:
            await _loadStudents();
            break;
          case 1:
            await _loadTeachers();
            break;
          case 2:
            await _loadDispatchUsers();
            break;
          case 3:
            await _loadAdminUsers();
            break;
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update user status'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
  
  Future<void> _resetUserPassword(UserModel user) async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      
      bool success = await authService.resetPassword(user.email);
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset email sent successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send password reset email: ${authService.error}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
  
  void _navigateToAddUser(String role) {
    // TODO: Implement navigation to add user screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Add $role user functionality will be implemented'),
        backgroundColor: AppColors.info,
      ),
    );
  }
  
  void _navigateToEditUser(UserModel user) {
    // TODO: Implement navigation to edit user screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Edit user functionality will be implemented'),
        backgroundColor: AppColors.info,
      ),
    );
  }
  
  List<UserModel> _getFilteredUsers(List<UserModel> users) {
    if (_searchQuery.isEmpty) {
      return users;
    }
    
    return users.where((user) {
      return user.fullName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             user.email.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             (user.phoneNumber != null && user.phoneNumber!.contains(_searchQuery));
    }).toList();
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'Search users by name or email',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty 
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        
        Container(
          color: AppColors.adminColor,
          child: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: const [
              Tab(text: 'Students'),
              Tab(text: 'Teachers'),
              Tab(text: 'Dispatch'),
              Tab(text: 'Admins'),
            ],
          ),
        ),
        
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildUserList(
                users: _getFilteredUsers(_students),
                isLoading: _isLoadingStudents,
                emptyMessage: 'No students found',
                roleColor: AppColors.studentColor,
                roleName: 'Student',
                roleIcon: Icons.school,
              ),
              _buildUserList(
                users: _getFilteredUsers(_teachers),
                isLoading: _isLoadingTeachers,
                emptyMessage: 'No teachers found',
                roleColor: AppColors.teacherColor,
                roleName: 'Teacher',
                roleIcon: Icons.person,
              ),
              _buildUserList(
                users: _getFilteredUsers(_dispatchUsers),
                isLoading: _isLoadingDispatch,
                emptyMessage: 'No dispatch users found',
                roleColor: AppColors.dispatchColor,
                roleName: 'Dispatch',
                roleIcon: Icons.headset_mic,
              ),
              _buildUserList(
                users: _getFilteredUsers(_adminUsers),
                isLoading: _isLoadingAdmins,
                emptyMessage: 'No admin users found',
                roleColor: AppColors.adminColor,
                roleName: 'Admin',
                roleIcon: Icons.admin_panel_settings,
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildUserList({
    required List<UserModel> users,
    required bool isLoading,
    required String emptyMessage,
    required Color roleColor,
    required String roleName,
    required IconData roleIcon,
  }) {
    if (isLoading) {
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
              onPressed: _loadUsers,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    
    if (users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              roleIcon,
              size: 64,
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty 
                  ? 'Try adjusting your search query'
                  : 'Add new users to get started',
              style: const TextStyle(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (_searchQuery.isNotEmpty)
              ElevatedButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
                  });
                },
                child: const Text('Clear Search'),
              )
            else
              CustomButton(
                text: 'Add New $roleName',
                icon: Icons.person_add,
                backgroundColor: roleColor,
                onPressed: () => _navigateToAddUser(roleName),
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
              Expanded(
                child: Text(
                  '${users.length} ${roleName.toLowerCase()}${users.length == 1 ? '' : 's'} found',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _navigateToAddUser(roleName),
                icon: const Icon(Icons.add),
                label: Text('Add $roleName'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: roleColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      // Avatar
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: roleColor,
                        child: Text(
                          user.firstName[0] + user.lastName[0],
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      
                      // User info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.fullName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              user.email,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            if (user.phoneNumber != null && user.phoneNumber!.isNotEmpty)
                              Text(
                                'Phone: ${user.phoneNumber}',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      ),
                      
                      // Status indicator and menu
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: user.isActive 
                                  ? AppColors.success.withOpacity(0.1) 
                                  : AppColors.error.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              user.isActive ? 'Active' : 'Inactive',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: user.isActive 
                                    ? AppColors.success 
                                    : AppColors.error,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert),
                            onSelected: (value) {
                              switch (value) {
                                case 'edit':
                                  _navigateToEditUser(user);
                                  break;
                                case 'activate':
                                  _updateUserStatus(user, true);
                                  break;
                                case 'deactivate':
                                  _updateUserStatus(user, false);
                                  break;
                                case 'reset':
                                  _resetUserPassword(user);
                                  break;
                                case 'delete':
                                  // Show confirmation dialog
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Confirm Delete'),
                                      content: Text('Are you sure you want to delete ${user.fullName}? This action cannot be undone.'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                            // TODO: Implement delete user functionality
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('Delete user functionality will be implemented'),
                                                backgroundColor: AppColors.info,
                                              ),
                                            );
                                          },
                                          child: const Text('Delete', style: TextStyle(color: AppColors.error)),
                                        ),
                                      ],
                                    ),
                                  );
                                  break;
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit, size: 18),
                                    SizedBox(width: 8),
                                    Text('Edit'),
                                  ],
                                ),
                              ),
                              if (!user.isActive)
                                const PopupMenuItem(
                                  value: 'activate',
                                  child: Row(
                                    children: [
                                      Icon(Icons.check_circle, size: 18, color: AppColors.success),
                                      SizedBox(width: 8),
                                      Text('Activate'),
                                    ],
                                  ),
                                ),
                              if (user.isActive)
                                const PopupMenuItem(
                                  value: 'deactivate',
                                  child: Row(
                                    children: [
                                      Icon(Icons.block, size: 18, color: AppColors.warning),
                                      SizedBox(width: 8),
                                      Text('Deactivate'),
                                    ],
                                  ),
                                ),
                              const PopupMenuItem(
                                value: 'reset',
                                child: Row(
                                  children: [
                                    Icon(Icons.lock_reset, size: 18, color: AppColors.info),
                                    SizedBox(width: 8),
                                    Text('Reset Password'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, size: 18, color: AppColors.error),
                                    SizedBox(width: 8),
                                    Text('Delete', style: TextStyle(color: AppColors.error)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}