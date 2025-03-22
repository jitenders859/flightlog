import 'package:flutter/material.dart';
import 'constants/app_constants.dart';
import 'constants/colors.dart';
import 'screens/admin/admin_home_screen.dart';
import 'screens/dispatch/dispatch_home_screen.dart';
import 'screens/student/student_home_screen.dart';
import 'screens/teacher/teacher_screen.dart';
import 'services/auth_service.dart';
import 'validators.dart';
import 'widgets/custom_button.dart';
import 'package:provider/provider.dart';


class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({Key? key}) : super(key: key);

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  
  String _selectedRole = AppConstants.roleStudent;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;
  
  final List<Map<String, dynamic>> _roles = [
    {
      'value': AppConstants.roleStudent,
      'title': 'Student',
      'description': 'Track your flight logs and receive notifications',
      'icon': Icons.school,
      'color': AppColors.studentColor,
    },
    {
      'value': AppConstants.roleTeacher,
      'title': 'Teacher',
      'description': 'Monitor student flights and manage records',
      'icon': Icons.person,
      'color': AppColors.teacherColor,
    },
    {
      'value': AppConstants.roleDispatch,
      'title': 'Dispatch',
      'description': 'Track all student flights and send alerts',
      'icon': Icons.headset_mic,
      'color': AppColors.dispatchColor,
    },
    {
      'value': AppConstants.roleAdmin,
      'title': 'Admin',
      'description': 'Full access to all system features',
      'icon': Icons.admin_panel_settings,
      'color': AppColors.adminColor,
    },
  ];
  
  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
  
  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _errorMessage = null;
    });
    
    AuthService authService = Provider.of<AuthService>(context, listen: false);
    
    final user = await authService.register(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      role: _selectedRole,
      phoneNumber: _phoneController.text.trim().isNotEmpty 
          ? _phoneController.text.trim() 
          : null,
    );
    
    if (user != null) {
      _navigateToHomeScreen(user.role);
    } else {
      setState(() {
        _errorMessage = authService.error ?? 'Failed to register. Please try again.';
      });
    }
  }
  
  void _navigateToHomeScreen(String role) {
    Widget homeScreen;
    
    switch (role) {
      case AppConstants.roleStudent:
        homeScreen = const StudentHomeScreen();
        break;
      case AppConstants.roleTeacher:
        homeScreen = const TeacherHomeScreen();
        break;
      case AppConstants.roleDispatch:
        homeScreen = const DispatchHomeScreen();
        break;
      case AppConstants.roleAdmin:
        homeScreen = const AdminHomeScreen();
        break;
      default:
        homeScreen = const StudentHomeScreen();
    }
    
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => homeScreen),
      (route) => false,
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register'),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Role Selection
                const Text(
                  'Select your role',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Role Cards
                SizedBox(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _roles.length,
                    itemBuilder: (context, index) {
                      final role = _roles[index];
                      final isSelected = role['value'] == _selectedRole;
                      
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedRole = role['value'];
                          });
                        },
                        child: Container(
                          width: 110,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? role['color'].withOpacity(0.1) : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? role['color'] : AppColors.backgroundDark,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                role['icon'],
                                color: role['color'],
                                size: 28,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                role['title'],
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? role['color'] : AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Tap to select',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isSelected ? role['color'] : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Registration Form
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Name Fields (Row with First and Last Name)
                      Row(
                        children: [
                          // First Name
                          Expanded(
                            child: TextFormField(
                              controller: _firstNameController,
                              decoration: const InputDecoration(
                                labelText: 'First Name',
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                              textCapitalization: TextCapitalization.words,
                              validator: Validators.validateName,
                            ),
                          ),
                          
                          const SizedBox(width: 16),
                          
                          // Last Name
                          Expanded(
                            child: TextFormField(
                              controller: _lastNameController,
                              decoration: const InputDecoration(
                                labelText: 'Last Name',
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                              textCapitalization: TextCapitalization.words,
                              validator: Validators.validateName,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Email Field
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: Validators.validateEmail,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Phone Field (Optional)
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Phone (Optional)',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                        validator: Validators.validatePhone,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Password Field
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        validator: Validators.validatePassword,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Confirm Password Field
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        decoration: InputDecoration(
                          labelText: 'Confirm Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword = !_obscureConfirmPassword;
                              });
                            },
                          ),
                        ),
                        validator: (value) => Validators.validateConfirmPassword(
                          value, 
                          _passwordController.text,
                        ),
                      ),
                      
                      // Error Message
                      if (_errorMessage != null)
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: AppColors.error,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      
                      const SizedBox(height: 24),
                      
                      // Register Button
                      CustomButton(
                        text: 'Register',
                        isLoading: authService.isLoading,
                        onPressed: _register,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Login Option
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Already have an account? ",
                            style: TextStyle(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: const Text(
                              'Login',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
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
          ),
        ),
      ),
    );
  }
}