import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../constants/app_constants.dart';
import '../models/notification_mode.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  StreamSubscription? _notificationSubscription;
  String? _userId;
  bool _isInitialized = false;
  bool _permissionsGranted = false;
  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  bool _notificationsEnabled = true;

  bool get isInitialized => _isInitialized;
  bool get permissionsGranted => _permissionsGranted;
  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get notificationsEnabled => _notificationsEnabled;

  NotificationService() {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _notificationsEnabled =
        prefs.getBool(AppConstants.prefsNotificationsEnabled) ?? true;
  }

  Future<void> initialize({required String userId}) async {
    if (_isInitialized) return;

    _userId = userId;

    // Initialize local notifications
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    final DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
          // onDidReceiveLocalNotification: _onDidReceiveLocalNotification,
        );
    final InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request notification permissions
    await _requestPermissions();

    // Set up notification channels
    await _setupNotificationChannels();

    // Set up Firebase Cloud Messaging
    await _setupFirebaseMessaging();

    // Listen for new notifications in Firestore
    _listenForNotifications();

    _isInitialized = true;
    notifyListeners();
  }

  Future<void> _requestPermissions() async {
    if (Platform.isIOS) {
      // Request iOS permissions
      await _messaging.requestPermission(alert: true, badge: true, sound: true);

      // Enable provisional notifications (iOS 12+ silent notifications)
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
            alert: true,
            badge: true,
            sound: true,
          );
    }

    if (Platform.isAndroid) {
      // Request Android permissions
      final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
          _localNotifications
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();

      _permissionsGranted =
          await androidPlugin?.requestNotificationsPermission() ?? false;
    } else {
      _permissionsGranted = true;
    }

    notifyListeners();
  }

  Future<void> _setupNotificationChannels() async {
    if (Platform.isAndroid) {
      // Flight Alarm Channel
      const AndroidNotificationChannel flightAlarmChannel =
          AndroidNotificationChannel(
            AppConstants.flightAlarmChannelId,
            AppConstants.flightAlarmChannelName,
            description: AppConstants.flightAlarmChannelDescription,
            importance: Importance.high,
            enableVibration: true,
            playSound: true,
          );

      // Proximity Warning Channel
      const AndroidNotificationChannel proximityChannel =
          AndroidNotificationChannel(
            AppConstants.proximityAlarmChannelId,
            AppConstants.proximityAlarmChannelName,
            description: AppConstants.proximityAlarmChannelDescription,
            importance: Importance.high,
            enableVibration: true,
            playSound: true,
          );

      final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
          _localNotifications
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();

      await androidPlugin?.createNotificationChannel(flightAlarmChannel);
      await androidPlugin?.createNotificationChannel(proximityChannel);
    }
  }

  Future<void> _setupFirebaseMessaging() async {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification taps when the app is in the background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessageTap);

    // Get initial notification if app was opened from a notification
    RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleBackgroundMessageTap(initialMessage);
    }
  }

  void _listenForNotifications() {
    if (_userId == null) return;

    // Cancel any existing subscription
    _notificationSubscription?.cancel();

    // Listen for new notifications for this user
    _notificationSubscription = _firestore
        .collection(AppConstants.notificationsCollection)
        .where('userId', isEqualTo: _userId)
        .orderBy('timestamp', descending: true)
        .limit(50) // Limit to recent notifications
        .snapshots()
        .listen(_handleNotificationsSnapshot);
  }

  void _handleNotificationsSnapshot(QuerySnapshot snapshot) {
    _notifications =
        snapshot.docs
            .map(
              (doc) => NotificationModel.fromMap(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ),
            )
            .toList();

    _unreadCount =
        _notifications.where((notification) => !notification.isRead).length;

    notifyListeners();
  }

  void _handleForegroundMessage(RemoteMessage message) async {
    print('Handling a foreground message: ${message.messageId}');

    if (!_notificationsEnabled) return;

    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null) {
      // Store notification in Firestore
      try {
        NotificationModel notificationModel = NotificationModel(
          id:
              message.messageId ??
              DateTime.now().millisecondsSinceEpoch.toString(),
          userId: _userId ?? '',
          title: notification.title ?? '',
          body: notification.body ?? '',
          type: message.data['type'] ?? 'system',
          timestamp: DateTime.now(),
          isRead: false,
          additionalData: message.data,
        );

        await _firestore
            .collection(AppConstants.notificationsCollection)
            .doc(notificationModel.id)
            .set(notificationModel.toMap());
      } catch (e) {
        print('Error storing notification: $e');
      }

      // Show local notification if Android or iOS
      if (android != null || Platform.isIOS) {
        String channelId = AppConstants.flightAlarmChannelId;

        // Use the appropriate channel based on notification type
        if (message.data['type'] == 'proximity-warning') {
          channelId = AppConstants.proximityAlarmChannelId;
        }

        // Display notification
        await _localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              channelId,
              channelId == AppConstants.flightAlarmChannelId
                  ? AppConstants.flightAlarmChannelName
                  : AppConstants.proximityAlarmChannelName,
              icon: android?.smallIcon,
              priority: Priority.high,
              importance: Importance.high,
            ),
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          payload: message.messageId,
        );
      }
    }
  }

  void _handleBackgroundMessageTap(RemoteMessage message) {
    print('User tapped on notification from background: ${message.messageId}');

    // Mark the notification as read
    if (message.messageId != null && _userId != null) {
      _firestore
          .collection(AppConstants.notificationsCollection)
          .doc(message.messageId)
          .update({'isRead': true});
    }

    // Handle navigation based on notification type
    String? type = message.data['type'];
    switch (type) {
      case 'flight-alarm':
        // TODO: Navigate to flight details screen
        // Get flight log ID from message.data['flightLogId']
        break;
      case 'proximity-warning':
        // TODO: Navigate to map screen
        break;
      default:
        // TODO: Navigate to notifications screen
        break;
    }
  }

  void _onDidReceiveLocalNotification(
    int id,
    String? title,
    String? body,
    String? payload,
  ) {
    print('Received local notification: $title');
    // For iOS 9 and earlier
  }

  void _onNotificationTapped(NotificationResponse response) {
    print('Local notification tapped: ${response.payload}');

    // Handle navigation based on payload
    if (response.payload != null) {
      // Mark the notification as read
      _firestore
          .collection(AppConstants.notificationsCollection)
          .doc(response.payload)
          .update({'isRead': true});

      // TODO: Navigate based on notification type
    }
  }

  Future<void> markAsRead(String notificationId) async {
    await _firestore
        .collection(AppConstants.notificationsCollection)
        .doc(notificationId)
        .update({'isRead': true});
  }

  Future<void> markAllAsRead() async {
    if (_userId == null) return;

    // Get all unread notifications for this user
    QuerySnapshot unreadNotifications =
        await _firestore
            .collection(AppConstants.notificationsCollection)
            .where('userId', isEqualTo: _userId)
            .where('isRead', isEqualTo: false)
            .get();

    // Create a batch update
    WriteBatch batch = _firestore.batch();

    // Add each document to the batch
    for (var doc in unreadNotifications.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    // Commit the batch
    await batch.commit();

    // Update local list
    for (var i = 0; i < _notifications.length; i++) {
      if (!_notifications[i].isRead) {
        _notifications[i] = _notifications[i].markAsRead();
      }
    }

    _unreadCount = 0;
    notifyListeners();
  }

  Future<void> deleteNotification(String notificationId) async {
    await _firestore
        .collection(AppConstants.notificationsCollection)
        .doc(notificationId)
        .delete();

    // Update local list
    _notifications.removeWhere(
      (notification) => notification.id == notificationId,
    );

    // Recalculate unread count
    _unreadCount =
        _notifications.where((notification) => !notification.isRead).length;

    notifyListeners();
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    _notificationsEnabled = enabled;

    // Save to preferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool(AppConstants.prefsNotificationsEnabled, enabled);

    notifyListeners();
  }

  // Send a flight time alarm notification
  Future<void> sendFlightAlarm({
    required String userId,
    required String flightLogId,
    String? title,
    String? body,
  }) async {
    if (!_notificationsEnabled) return;

    try {
      NotificationModel notification = NotificationModel.createFlightAlarm(
        userId: userId,
        flightLogId: flightLogId,
        title: title ?? 'Flight Time Reminder',
        body:
            body ??
            'Your flight time is ending in 1 hour. Please prepare to return.',
      );

      // Store in Firestore
      await _firestore
          .collection(AppConstants.notificationsCollection)
          .doc(notification.id)
          .set(notification.toMap());

      // Show local notification
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: const AndroidNotificationDetails(
            AppConstants.flightAlarmChannelId,
            AppConstants.flightAlarmChannelName,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: notification.id,
      );
    } catch (e) {
      print('Error sending flight alarm: $e');
    }
  }

  // Send a proximity warning notification
  Future<void> sendProximityWarning({
    required String userId,
    required String flightLogId,
    required double distanceFromSchool,
    String? title,
    String? body,
  }) async {
    if (!_notificationsEnabled) return;

    try {
      NotificationModel notification = NotificationModel.createProximityWarning(
        userId: userId,
        flightLogId: flightLogId,
        distanceFromSchool: distanceFromSchool,
        title: title ?? 'Distance Warning',
        body:
            body ??
            'You are ${distanceFromSchool.toStringAsFixed(1)} meters from school. Please return soon.',
      );

      // Store in Firestore
      await _firestore
          .collection(AppConstants.notificationsCollection)
          .doc(notification.id)
          .set(notification.toMap());

      // Show local notification
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: const AndroidNotificationDetails(
            AppConstants.proximityAlarmChannelId,
            AppConstants.proximityAlarmChannelName,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: notification.id,
      );
    } catch (e) {
      print('Error sending proximity warning: $e');
    }
  }

  // Schedule a flight alarm for 1 hour before the expected end time
  Future<void> scheduleFlightAlarm({
    required String userId,
    required String flightLogId,
    required DateTime endTime,
    String? title,
    String? body,
  }) async {
    if (!_notificationsEnabled) return;

    try {
      // Calculate the time for 1 hour before end time
      DateTime alarmTime = endTime.subtract(const Duration(hours: 1));

      // Only schedule if the alarm time is in the future
      if (alarmTime.isAfter(DateTime.now())) {
        // Create the notification model
        NotificationModel notification = NotificationModel.createFlightAlarm(
          userId: userId,
          flightLogId: flightLogId,
          title: title ?? 'Flight Time Reminder',
          body:
              body ??
              'Your flight time is ending in 1 hour. Please prepare to return.',
        );

        // Store in Firestore
        await _firestore
            .collection(AppConstants.notificationsCollection)
            .doc(notification.id)
            .set(notification.toMap());

        // Schedule the notification
        // await _localNotifications.zonedSchedule(
        //   notification.hashCode,
        //   notification.title,
        //   notification.body,
        //   tz.TZDateTime.from(alarmTime, tz.local),
        //   NotificationDetails(
        //     android: const AndroidNotificationDetails(
        //       AppConstants.flightAlarmChannelId,
        //       AppConstants.flightAlarmChannelName,
        //       importance: Importance.high,
        //       priority: Priority.high,
        //     ),
        //     iOS: const DarwinNotificationDetails(
        //       presentAlert: true,
        //       presentBadge: true,
        //       presentSound: true,
        //     ),
        //   ),
        //   // androidAllowWhileIdle: true,
        //   // uiLocalNotificationDateInterpretation:
        //   //     UILocalNotificationDateInterpretation.absoluteTime,
        //   matchDateTimeComponents: DateTimeComponents.time,
        //   payload: notification.id,
        // );
      }
    } catch (e) {
      print('Error scheduling flight alarm: $e');
    }
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }
}
