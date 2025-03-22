class AppConstants {
  // User Roles
  static const String roleStudent = 'student';
  static const String roleTeacher = 'teacher';
  static const String roleDispatch = 'dispatch';
  static const String roleAdmin = 'admin';
  
  // Firestore Collections
  static const String usersCollection = 'users';
  static const String flightLogsCollection = 'flight_logs';
  static const String notificationsCollection = 'notifications';
  static const String settingsCollection = 'settings';
  
  // Location Constants
  static const int locationUpdateInterval = 60; // seconds
  static const double schoolProximityThreshold = 1000; // meters
  
  // Notification Constants
  static const String flightAlarmChannelId = 'flight_alarm_channel';
  static const String flightAlarmChannelName = 'Flight Alarms';
  static const String flightAlarmChannelDescription = 'Channel for flight alarms and notifications';
  
  static const String proximityAlarmChannelId = 'proximity_alarm_channel';
  static const String proximityAlarmChannelName = 'Proximity Alarms';
  static const String proximityAlarmChannelDescription = 'Channel for proximity alarms and notifications';
  
  // App Settings
  static const String appName = 'Flight Logger';
  static const String appVersion = '1.0.0';
  
  // Default School Location (to be configured by admin)
  static const double defaultSchoolLatitude = 37.4220; // Example: Palo Alto
  static const double defaultSchoolLongitude = -122.0841;
  
  // Shared Preferences Keys
  static const String prefsUserRole = 'user_role';
  static const String prefsUserId = 'user_id';
  static const String prefsUserName = 'user_name';
  static const String prefsSchoolLatitude = 'school_latitude';
  static const String prefsSchoolLongitude = 'school_longitude';
  static const String prefsNotificationsEnabled = 'notifications_enabled';
}