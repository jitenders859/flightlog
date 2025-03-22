import 'package:flutter/material.dart';
import 'constants/app_constants.dart';
import 'screens/admin/admin_home_screen.dart';
import 'screens/dispatch/dispatch_home_screen.dart';
import 'screens/student/student_home_screen.dart';
import 'screens/teacher/teacher_screen.dart';
import 'services/auth_service.dart';
import 'constants/colors.dart';
import 'widgets/custom_button.dart';
import 'validators.dart';
import 'package:provider/provider.dart';

import 'registration_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _errorMessage = null;
    });

    AuthService authService = Provider.of<AuthService>(context, listen: false);

    final user = await authService.signIn(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (user != null) {
      _navigateToHomeScreen(user.role);
    } else {
      setState(() {
        _errorMessage =
            authService.error ?? 'Failed to login. Please try again.';
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

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => homeScreen),
    );
  }

  void _navigateToRegistration() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RegistrationScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 60),

                // App Logo and Title
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.flight_takeoff,
                          size: 60,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Flight Logger',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Login to your account',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 48),

                // Login Form
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
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

                      // Password Field
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
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

                      const SizedBox(height: 8),

                      // Forgot Password
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            // TODO: Implement forgot password
                          },
                          child: const Text('Forgot Password?'),
                        ),
                      ),

                      // Error Message
                      if (_errorMessage != null)
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
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

                      // Login Button
                      CustomButton(
                        text: 'Login',
                        isLoading: authService.isLoading,
                        onPressed: _login,
                      ),

                      const SizedBox(height: 24),

                      // Register Option
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Don't have an account? ",
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                          GestureDetector(
                            onTap: _navigateToRegistration,
                            child: const Text(
                              'Register',
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
