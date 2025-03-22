import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../constants/colors.dart';
import '../../widgets/custom_button.dart';
import '../../validators.dart';
import 'package:provider/provider.dart';


class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _phoneController;
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  
  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }
  
  void _initializeControllers() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;
    
    if (user != null) {
      _firstNameController = TextEditingController(text: user.firstName);
      _lastNameController = TextEditingController(text: user.lastName);
      _phoneController = TextEditingController(text: user.phoneNumber ?? '');
    } else {
      _firstNameController = TextEditingController();
      _lastNameController = TextEditingController();
      _phoneController = TextEditingController();
    }
  }
  
  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
  
  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });
    
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      
      bool success = await authService.updateProfile(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        phoneNumber: _phoneController.text.trim().isNotEmpty 
            ? _phoneController.text.trim() 
            : null,
      );
      
      if (success) {
        setState(() {
          _successMessage = 'Profile updated successfully!';
        });
      } else {
        setState(() {
          _errorMessage = authService.error ?? 'Failed to update profile. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _resetPassword() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;
    
    if (user == null) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });
    
    try {
      bool success = await authService.resetPassword(user.email);
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset email sent. Please check your inbox.'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        setState(() {
          _errorMessage = authService.error ?? 'Failed to send password reset email. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;
    
    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Profile'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      user.firstName[0] + user.lastName[0],
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user.fullName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Edit Profile Form
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Personal Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // First Name
                  TextFormField(
                    controller: _firstNameController,
                    decoration: const InputDecoration(
                      labelText: 'First Name',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: Validators.validateName,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Last Name
                  TextFormField(
                    controller: _lastNameController,
                    decoration: const InputDecoration(
                      labelText: 'Last Name',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: Validators.validateName,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Phone (Optional)
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number (Optional)',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: Validators.validatePhone,
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
                  
                  // Success Message
                  if (_successMessage != null)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        _successMessage!,
                        style: const TextStyle(
                          color: AppColors.success,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  
                  const SizedBox(height: 24),
                  
                  // Update Profile Button
                  CustomButton(
                    text: 'Update Profile',
                    isLoading: _isLoading,
                    onPressed: _updateProfile,
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Security Section
                  const Text(
                    'Security',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Reset Password Button
                  CustomButton(
                    text: 'Reset Password',
                    icon: Icons.lock_reset,
                    isOutlined: true,
                    onPressed: _resetPassword,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}