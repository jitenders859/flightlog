class UserModel {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String role;
  final String? phoneNumber;
  final String? profileImageUrl;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? fcmToken;
  final Map<String, dynamic>? additionalData;

  UserModel({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    this.phoneNumber,
    this.profileImageUrl,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.fcmToken,
    this.additionalData,
  });

  String get fullName => '$firstName $lastName';

  // Create from map (e.g., Firestore document)
  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      email: map['email'] ?? '',
      firstName: map['firstName'] ?? '',
      lastName: map['lastName'] ?? '',
      role: map['role'] ?? '',
      phoneNumber: map['phoneNumber'],
      profileImageUrl: map['profileImageUrl'],
      isActive: map['isActive'] ?? true,
      createdAt: (map['createdAt'] != null) ? 
        DateTime.fromMillisecondsSinceEpoch(map['createdAt']) : 
        DateTime.now(),
      updatedAt: (map['updatedAt'] != null) ? 
        DateTime.fromMillisecondsSinceEpoch(map['updatedAt']) : 
        DateTime.now(),
      fcmToken: map['fcmToken'],
      additionalData: map['additionalData'],
    );
  }

  // Convert to map (e.g., for Firestore)
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'role': role,
      'phoneNumber': phoneNumber,
      'profileImageUrl': profileImageUrl,
      'isActive': isActive,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'fcmToken': fcmToken,
      'additionalData': additionalData,
    };
  }

  // Create copy with updated fields
  UserModel copyWith({
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? profileImageUrl,
    bool? isActive,
    String? fcmToken,
    Map<String, dynamic>? additionalData,
  }) {
    return UserModel(
      id: this.id,
      email: this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      role: this.role,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      isActive: isActive ?? this.isActive,
      createdAt: this.createdAt,
      updatedAt: DateTime.now(),
      fcmToken: fcmToken ?? this.fcmToken,
      additionalData: additionalData ?? this.additionalData,
    );
  }
}