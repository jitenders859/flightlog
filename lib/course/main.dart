// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:provider/provider.dart';

// import '../../../lib/flight_logger/course/constants/colors.dart';
// import '../../../lib/flight_logger/course/services/auth_service.dart';
// import '../../../lib/flight_logger/course/services/database_service.dart';
// import '../../../lib/flight_logger/course/services/location_service.dart';
// import '../../../lib/flight_logger/course/services/notification_service.dart';
// import '../../../lib/flight_logger/course/services/flight_log_service.dart';
// import '../../../lib/flight_logger/course/services/aws_service.dart';
// import '../../../lib/flight_logger/course/services/lms_service.dart';
// import '../../../lib/flight_logger/course/screens/authentication/login_screen.dart';

// // Background message handler for Firebase Cloud Messaging
// Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
//   await Firebase.initializeApp();
//   print('Handling a background message: ${message.messageId}');
// }

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
  
//   // Initialize Firebase
//   await Firebase.initializeApp();
  
//   // Set up Firebase Cloud Messaging
//   FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
//   // Request notification permissions
//   await FirebaseMessaging.instance.requestPermission(
//     alert: true,
//     badge: true,
//     sound: true,
//   );
  
//   // Set up Flutter Local Notifications
//   final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
//   const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
//   final DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings(
//     requestAlertPermission: true,
//     requestBadgePermission: true,
//     requestSoundPermission: true,
//   );
//   final InitializationSettings initializationSettings = InitializationSettings(
//     android: initializationSettingsAndroid,
//     iOS: initializationSettingsIOS,
//   );
//   await flutterLocalNotificationsPlugin.initialize(
//     initializationSettings,
//     onDidReceiveNotificationResponse: (NotificationResponse notificationResponse) {
//       print('Notification clicked: ${notificationResponse.payload}');
//       // TODO: Handle notification click
//     },
//   );
  
//   // Initialize AWS
//   final awsService = AWSService();
//   await awsService.initialize();
  
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return MultiProvider(
//       providers: [
//         // Auth Service
//         ChangeNotifierProvider(create: (_) => AuthService()),
        
//         // Database Service
//         ChangeNotifierProvider(create: (_) => DatabaseService()),
        
//         // Location Service
//         ChangeNotifierProvider(create: (_) => LocationService()),
        
//         // Notification Service
//         ChangeNotifierProvider(create: (_) => NotificationService()),
        
//         // Flight Log Service - depends on other services
//         ChangeNotifierProxyProvider3<DatabaseService, LocationService, NotificationService, FlightLogService>(
//           create: (context) => FlightLogService(
//             databaseService: Provider.of<DatabaseService>(context, listen: false),
//             locationService: Provider.of<LocationService>(context, listen: false),
//             notificationService: Provider.of<NotificationService>(context, listen: false),
//           ),
//           update: (context, databaseService, locationService, notificationService, previous) =>
//             FlightLogService(
//               databaseService: databaseService,
//               locationService: locationService,
//               notificationService: notificationService,
//             ),
//         ),
        
//         // LMS Service
//         ChangeNotifierProvider(create: (_) => LMSService()),
//       ],
//       child: MaterialApp(
//         title: 'Flight Logger',
//         debugShowCheckedModeBanner: false,
//         theme: ThemeData(
//           primarySwatch: Colors.blue,
//           scaffoldBackgroundColor: AppColors.background,
//           fontFamily: 'Roboto',
//           appBarTheme: const AppBarTheme(
//             backgroundColor: AppColors.primary,
//             elevation: 0,
//             foregroundColor: Colors.white,
//           ),
//           elevatedButtonTheme: ElevatedButtonThemeData(
//             style: ElevatedButton.styleFrom(
//               backgroundColor: AppColors.primary,
//               foregroundColor: Colors.white,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               padding: const EdgeInsets.symmetric(vertical: 16),
//             ),
//           ),
//           inputDecorationTheme: InputDecorationTheme(
//             filled: true,
//             fillColor: Colors.white,
//             border: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(8),
//               borderSide: BorderSide.none,
//             ),
//             enabledBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(8),
//               borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
//             ),
//             focusedBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(8),
//               borderSide: const BorderSide(color: AppColors.primary),
//             ),
//             contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
//             prefixIconColor: AppColors.primary,
//           ),
//           cardTheme: CardTheme(
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(12),
//             ),
//             elevation: 2,
//           ),
//           bottomNavigationBarTheme: const BottomNavigationBarThemeData(
//             selectedItemColor: AppColors.primary,
//             unselectedItemColor: AppColors.textSecondary,
//             type: BottomNavigationBarType.fixed,
//             elevation: 8,
//           ),
//           tabBarTheme: const TabBarTheme(
//             indicatorColor: Colors.white,
//             labelColor: Colors.white,
//             unselectedLabelColor: Colors.white70,
//           ),
//           checkboxTheme: CheckboxThemeData(
//             fillColor: MaterialStateProperty.resolveWith<Color>((states) {
//               if (states.contains(MaterialState.disabled)) {
//                 return AppColors.textSecondary.withOpacity(.32);
//               }
//               return AppColors.primary;
//             }),
//           ),
//           radioTheme: RadioThemeData(
//             fillColor: MaterialStateProperty.resolveWith<Color>((states) {
//               if (states.contains(MaterialState.disabled)) {
//                 return AppColors.textSecondary.withOpacity(.32);
//               }
//               return AppColors.primary;
//             }),
//           ),
//           switchTheme: SwitchThemeData(
//             thumbColor: MaterialStateProperty.resolveWith<Color>((states) {
//               if (states.contains(MaterialState.disabled)) {
//                 return AppColors.textSecondary.withOpacity(.32);
//               }
//               if (states.contains(MaterialState.selected)) {
//                 return AppColors.primary;
//               }
//               return Colors.grey;
//             }),
//             trackColor: MaterialStateProperty.resolveWith<Color>((states) {
//               if (states.contains(MaterialState.disabled)) {
//                 return AppColors.textSecondary.withOpacity(.12);
//               }
//               if (states.contains(MaterialState.selected)) {
//                 return AppColors.primary.withOpacity(.5);
//               }
//               return Colors.grey.withOpacity(.5);
//             }),
//           ),
//           colorScheme: ColorScheme.fromSwatch(
//             primarySwatch: Colors.blue,
//           ).copyWith(
//             primary: AppColors.primary,
//             secondary: AppColors.accent,
//             error: AppColors.error,
//           ),
//         ),
//         darkTheme: ThemeData(
//           brightness: Brightness.dark,
//           primarySwatch: Colors.blue,
//           primaryColor: AppColors.primary,
//           scaffoldBackgroundColor: const Color(0xFF121212),
//           appBarTheme: const AppBarTheme(
//             backgroundColor: Color(0xFF1E1E1E),
//             elevation: 0,
//           ),
//           cardTheme: CardTheme(
//             color: const Color(0xFF1E1E1E),
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(12),
//             ),
//           ),
//           inputDecorationTheme: InputDecorationTheme(
//             filled: true,
//             fillColor: const Color(0xFF2C2C2C),
//             border: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(8),
//               borderSide: BorderSide.none,
//             ),
//             contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
//           ),
//           colorScheme: ColorScheme.dark(
//             primary: AppColors.primary,
//             secondary: AppColors.accent,
//             error: AppColors.error,
//             surface: const Color(0xFF1E1E1E),
//             background: const Color(0xFF121212),
//           ),
//         ),
//         themeMode: ThemeMode.light, // Default to light theme, can be changed by user preference
//         home: const LoginScreen(),
//       ),
//     );
//   }
// } MaterialStateProperty.resolveWith<Color>((states) {
//               if (states.contains(MaterialState.disabled)) {
//                 return AppColors.textSecondary.withOpacity(.12);
//               }
//               if (states.contains(MaterialState.selected)) {
//                 return AppColors.primary.withOpacity(.5);
//               }
//               return Colors.grey.withOpacity(.5);
//             }),
//           ),
//           colorScheme: ColorScheme.fromSwatch(
//             primarySwatch: Colors.blue,
//           ).copyWith(
//             primary: AppColors.primary,
//             secondary: AppColors.accent,
//             error: AppColors.error,
//           ),
//         ),
//         darkTheme: ThemeData(
//           brightness: Brightness.dark,
//           primarySwatch: Colors.blue,
//           primaryColor: AppColors.primary,
//           scaffoldBackgroundColor: const Color(0xFF121212),
//           appBarTheme: const AppBarTheme(
//             backgroundColor: Color(0xFF1E1E1E),
//             elevation: 0,
//           ),
//           cardTheme: CardTheme(
//             color: const Color(0xFF1E1E1E),
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(12),
//             ),
//           ),
//           inputDecorationTheme: InputDecorationTheme(
//             filled: true,
//             fillColor: const Color(0xFF2C2C2C),
//             border: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(8),
//               borderSide: BorderSide.none,
//             ),
//             contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
//           ),
//           colorScheme: ColorScheme.dark(
//             primary: AppColors.primary,
//             secondary: AppColors.accent,
//             error: AppColors.error,
//             surface: const Color(0xFF1E1E1E),
//             background: const Color(0xFF121212),
//           ),
//         ),
//         themeMode: ThemeMode.light, // Default to light theme, can be changed by user preference
//         home: const LoginScreen(),
//       ),
//     );
//   }
// }