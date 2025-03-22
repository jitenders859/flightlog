import 'package:cloud_firestore/cloud_firestore.dart';

enum ContentType {
  video,
  document,
  pdf,
  quiz,
  test,
}

class Content {
  final String id;
  final String title;
  final String description;
  final ContentType contentType;
  final String courseId;
  final String createdBy; // Admin or teacher ID
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final String fileUrl; // S3 URL for the content
  final String? thumbnailUrl;
  final int orderIndex; // For ordering content within a course
  final List<String> assignedStudentIds;
  final Map<String, dynamic>? metadata; // For content-specific data

  Content({
    required this.id,
    required this.title,
    required this.description,
    required this.contentType,
    required this.courseId,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    required this.isActive,
    required this.fileUrl,
    this.thumbnailUrl,
    required this.orderIndex,
    required this.assignedStudentIds,
    this.metadata,
  });

  factory Content.fromMap(Map<String, dynamic> map, String id) {
    return Content(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      contentType: _parseContentType(map['contentType'] ?? 'document'),
      courseId: map['courseId'] ?? '',
      createdBy: map['createdBy'] ?? '',
      createdAt: (map['createdAt'] != null)
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: (map['updatedAt'] != null)
          ? (map['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
      isActive: map['isActive'] ?? true,
      fileUrl: map['fileUrl'] ?? '',
      thumbnailUrl: map['thumbnailUrl'],
      orderIndex: map['orderIndex'] ?? 0,
      assignedStudentIds: List<String>.from(map['assignedStudentIds'] ?? []),
      metadata: map['metadata'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'contentType': contentType.toString().split('.').last,
      'courseId': courseId,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isActive': isActive,
      'fileUrl': fileUrl,
      'thumbnailUrl': thumbnailUrl,
      'orderIndex': orderIndex,
      'assignedStudentIds': assignedStudentIds,
      'metadata': metadata,
    };
  }

  Content copyWith({
    String? title,
    String? description,
    ContentType? contentType,
    String? courseId,
    bool? isActive,
    String? fileUrl,
    String? thumbnailUrl,
    int? orderIndex,
    List<String>? assignedStudentIds,
    Map<String, dynamic>? metadata,
  }) {
    return Content(
      id: this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      contentType: contentType ?? this.contentType,
      courseId: courseId ?? this.courseId,
      createdBy: this.createdBy,
      createdAt: this.createdAt,
      updatedAt: DateTime.now(),
      isActive: isActive ?? this.isActive,
      fileUrl: fileUrl ?? this.fileUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      orderIndex: orderIndex ?? this.orderIndex,
      assignedStudentIds: assignedStudentIds ?? this.assignedStudentIds,
      metadata: metadata ?? this.metadata,
    );
  }

  static ContentType _parseContentType(String typeString) {
    switch (typeString.toLowerCase()) {
      case 'video':
        return ContentType.video;
      case 'document':
        return ContentType.document;
      case 'pdf':
        return ContentType.pdf;
      case 'quiz':
        return ContentType.quiz;
      case 'test':
        return ContentType.test;
      default:
        return ContentType.document;
    }
  }

  bool get isVideo => contentType == ContentType.video;
  bool get isDocument => contentType == ContentType.document;
  bool get isPdf => contentType == ContentType.pdf;
  bool get isQuiz => contentType == ContentType.quiz;
  bool get isTest => contentType == ContentType.test;
}