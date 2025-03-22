import 'package:cloud_firestore/cloud_firestore.dart';

class Course {
  final String id;
  final String title;
  final String description;
  final String category; // e.g., 'PPL', 'CPL', 'Multi'
  final String createdBy; // Admin or teacher ID
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final List<String> assignedStudentIds;
  final String? thumbnailUrl;
  final Map<String, dynamic>? additionalData;

  Course({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    required this.isActive,
    required this.assignedStudentIds,
    this.thumbnailUrl,
    this.additionalData,
  });

  factory Course.fromMap(Map<String, dynamic> map, String id) {
    return Course(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      createdBy: map['createdBy'] ?? '',
      createdAt: (map['createdAt'] != null)
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: (map['updatedAt'] != null)
          ? (map['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
      isActive: map['isActive'] ?? true,
      assignedStudentIds: List<String>.from(map['assignedStudentIds'] ?? []),
      thumbnailUrl: map['thumbnailUrl'],
      additionalData: map['additionalData'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isActive': isActive,
      'assignedStudentIds': assignedStudentIds,
      'thumbnailUrl': thumbnailUrl,
      'additionalData': additionalData,
    };
  }

  Course copyWith({
    String? title,
    String? description,
    String? category,
    bool? isActive,
    List<String>? assignedStudentIds,
    String? thumbnailUrl,
    Map<String, dynamic>? additionalData,
  }) {
    return Course(
      id: this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      createdBy: this.createdBy,
      createdAt: this.createdAt,
      updatedAt: DateTime.now(),
      isActive: isActive ?? this.isActive,
      assignedStudentIds: assignedStudentIds ?? this.assignedStudentIds,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      additionalData: additionalData ?? this.additionalData,
    );
  }
}