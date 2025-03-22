class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String body;
  final String type; // 'flight-alarm', 'proximity-warning', 'system', 'custom'
  final DateTime timestamp;
  final bool isRead;
  final Map<String, dynamic>? additionalData;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    required this.timestamp,
    required this.isRead,
    this.additionalData,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map, String id) {
    return NotificationModel(
      id: id,
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      type: map['type'] ?? 'system',
      timestamp: (map['timestamp'] != null) 
          ? DateTime.fromMillisecondsSinceEpoch(map['timestamp']) 
          : DateTime.now(),
      isRead: map['isRead'] ?? false,
      additionalData: map['additionalData'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'body': body,
      'type': type,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'isRead': isRead,
      'additionalData': additionalData,
    };
  }

  NotificationModel markAsRead() {
    return NotificationModel(
      id: this.id,
      userId: this.userId,
      title: this.title,
      body: this.body,
      type: this.type,
      timestamp: this.timestamp,
      isRead: true,
      additionalData: this.additionalData,
    );
  }

  // Create flight alarm notification
  static NotificationModel createFlightAlarm({
    required String userId,
    required String flightLogId,
    String title = 'Flight Time Reminder',
    String body = 'Your flight time is ending in 1 hour. Please prepare to return.',
  }) {
    return NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      title: title,
      body: body,
      type: 'flight-alarm',
      timestamp: DateTime.now(),
      isRead: false,
      additionalData: {
        'flightLogId': flightLogId,
      },
    );
  }

  // Create proximity warning notification
  static NotificationModel createProximityWarning({
    required String userId,
    required double distanceFromSchool,
    required String flightLogId,
    String title = 'Distance Warning',
    String? body,
  }) {
    return NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      title: title,
      body: body ?? 'You are ${distanceFromSchool.toStringAsFixed(1)} meters from school. Please return soon.',
      type: 'proximity-warning',
      timestamp: DateTime.now(),
      isRead: false,
      additionalData: {
        'flightLogId': flightLogId,
        'distanceFromSchool': distanceFromSchool,
      },
    );
  }

  // Create custom notification
  static NotificationModel createCustom({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? additionalData,
  }) {
    return NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      title: title,
      body: body,
      type: 'custom',
      timestamp: DateTime.now(),
      isRead: false,
      additionalData: additionalData,
    );
  }
}