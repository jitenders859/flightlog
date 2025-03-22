class Validators {
  // Email validation
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    
    return null;
  }
  
  // Password validation
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    
    return null;
  }
  
  // Name validation
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }
    
    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }
    
    return null;
  }
  
  // Phone number validation
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Phone is optional
    }
    
    final phoneRegex = RegExp(r'^\+?[0-9]{10,15}$');
    
    if (!phoneRegex.hasMatch(value)) {
      return 'Please enter a valid phone number';
    }
    
    return null;
  }
  
  // Required field validation
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    
    return null;
  }
  
  // Confirm password validation
  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Confirm password is required';
    }
    
    if (value != password) {
      return 'Passwords do not match';
    }
    
    return null;
  }
  
  // Numeric validation
  static String? validateNumeric(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    
    if (double.tryParse(value) == null) {
      return 'Please enter a valid number';
    }
    
    return null;
  }
  
  // Latitude validation
  static String? validateLatitude(String? value) {
    if (value == null || value.isEmpty) {
      return 'Latitude is required';
    }
    
    final double? latitude = double.tryParse(value);
    
    if (latitude == null) {
      return 'Please enter a valid number';
    }
    
    if (latitude < -90 || latitude > 90) {
      return 'Latitude must be between -90 and 90';
    }
    
    return null;
  }
  
  // Longitude validation
  static String? validateLongitude(String? value) {
    if (value == null || value.isEmpty) {
      return 'Longitude is required';
    }
    
    final double? longitude = double.tryParse(value);
    
    if (longitude == null) {
      return 'Please enter a valid number';
    }
    
    if (longitude < -180 || longitude > 180) {
      return 'Longitude must be between -180 and 180';
    }
    
    return null;
  }
}