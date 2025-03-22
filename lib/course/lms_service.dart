import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'aws_service.dart';
import 'content_model.dart';
import 'course_mode.dart';
import 'quiz_model.dart';

class LMSService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AWSService _awsService = AWSService();
  
  // Collection names
  static const String coursesCollection = 'courses';
  static const String contentCollection = 'content';
  static const String quizzesCollection = 'quizzes';
  static const String quizAttemptsCollection = 'quiz_attempts';
  
  // S3 folder paths
  static const String videosFolder = 'videos';
  static const String documentsFolder = 'documents';
  static const String pdfsFolder = 'pdfs';
  
  String? _currentUserId;
  String? _currentUserRole;
  
  bool _isLoading = false;
  String? _error;
  
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  void initialize(String userId, String userRole) {
    _currentUserId = userId;
    _currentUserRole = userRole;
  }
  
  // COURSES METHODS
  
  Future<List<Course>> getCourses() async {
    try {
      _setLoading(true);
      
      QuerySnapshot snapshot = await _firestore.collection(coursesCollection).get();
      
      List<Course> courses = snapshot.docs.map((doc) => 
        Course.fromMap(doc.data() as Map<String, dynamic>, doc.id)
      ).toList();
      
      _setLoading(false);
      return courses;
    } catch (e) {
      _setError('Error getting courses: $e');
      return [];
    }
  }
  
  Future<List<Course>> getCoursesByCategory(String category) async {
    try {
      _setLoading(true);
      
      QuerySnapshot snapshot = await _firestore
          .collection(coursesCollection)
          .where('category', isEqualTo: category)
          .where('isActive', isEqualTo: true)
          .get();
      
      List<Course> courses = snapshot.docs.map((doc) => 
        Course.fromMap(doc.data() as Map<String, dynamic>, doc.id)
      ).toList();
      
      _setLoading(false);
      return courses;
    } catch (e) {
      _setError('Error getting courses by category: $e');
      return [];
    }
  }
  
  Future<List<Course>> getStudentCourses(String studentId) async {
    try {
      _setLoading(true);
      
      QuerySnapshot snapshot = await _firestore
          .collection(coursesCollection)
          .where('assignedStudentIds', arrayContains: studentId)
          .where('isActive', isEqualTo: true)
          .get();
      
      List<Course> courses = snapshot.docs.map((doc) => 
        Course.fromMap(doc.data() as Map<String, dynamic>, doc.id)
      ).toList();
      
      _setLoading(false);
      return courses;
    } catch (e) {
      _setError('Error getting student courses: $e');
      return [];
    }
  }
  
  Future<Course?> getCourse(String courseId) async {
    try {
      _setLoading(true);
      
      DocumentSnapshot doc = await _firestore.collection(coursesCollection).doc(courseId).get();
      
      if (!doc.exists) {
        _setError('Course not found');
        return null;
      }
      
      Course course = Course.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      
      _setLoading(false);
      return course;
    } catch (e) {
      _setError('Error getting course: $e');
      return null;
    }
  }
  
  Future<String?> createCourse({
    required String title,
    required String description,
    required String category,
    String? thumbnailUrl,
    List<String>? assignedStudentIds,
  }) async {
    if (_currentUserId == null || _currentUserRole == null) {
      _setError('User not authenticated');
      return null;
    }
    
    if (_currentUserRole != 'admin' && _currentUserRole != 'teacher') {
      _setError('Only admins and teachers can create courses');
      return null;
    }
    
    try {
      _setLoading(true);
      
      // Create a document reference first to get an ID
      DocumentReference docRef = _firestore.collection(coursesCollection).doc();
      
      // Create the course object
      Course course = Course(
        id: docRef.id,
        title: title,
        description: description,
        category: category,
        createdBy: _currentUserId!,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: true,
        assignedStudentIds: assignedStudentIds ?? [],
        thumbnailUrl: thumbnailUrl,
      );
      
      // Save the course to Firestore
      await docRef.set(course.toMap());
      
      _setLoading(false);
      return docRef.id;
    } catch (e) {
      _setError('Error creating course: $e');
      return null;
    }
  }
  
  Future<bool> updateCourse({
    required String courseId,
    String? title,
    String? description,
    String? category,
    bool? isActive,
    String? thumbnailUrl,
    List<String>? assignedStudentIds,
  }) async {
    if (_currentUserId == null || _currentUserRole == null) {
      _setError('User not authenticated');
      return false;
    }
    
    if (_currentUserRole != 'admin' && _currentUserRole != 'teacher') {
      _setError('Only admins and teachers can update courses');
      return false;
    }
    
    try {
      _setLoading(true);
      
      // Get current course data
      DocumentSnapshot doc = await _firestore.collection(coursesCollection).doc(courseId).get();
      
      if (!doc.exists) {
        _setError('Course not found');
        return false;
      }
      
      Course course = Course.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      
      // Only the creator or admin can update the course
      if (course.createdBy != _currentUserId && _currentUserRole != 'admin') {
        _setError('You are not authorized to update this course');
        return false;
      }
      
      // Update the course
      Course updatedCourse = course.copyWith(
        title: title,
        description: description,
        category: category,
        isActive: isActive,
        thumbnailUrl: thumbnailUrl,
        assignedStudentIds: assignedStudentIds,
      );
      
      // Save updates to Firestore
      await _firestore.collection(coursesCollection).doc(courseId).update(updatedCourse.toMap());
      
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Error updating course: $e');
      return false;
    }
  }
  
  Future<bool> assignStudentToCourse(String courseId, String studentId) async {
    if (_currentUserId == null || _currentUserRole == null) {
      _setError('User not authenticated');
      return false;
    }
    
    if (_currentUserRole != 'admin' && _currentUserRole != 'teacher') {
      _setError('Only admins and teachers can assign students');
      return false;
    }
    
    try {
      _setLoading(true);
      
      // Update the course's assignedStudentIds array
      await _firestore.collection(coursesCollection).doc(courseId).update({
        'assignedStudentIds': FieldValue.arrayUnion([studentId]),
        'updatedAt': Timestamp.now(),
      });
      
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Error assigning student to course: $e');
      return false;
    }
  }
  
  Future<bool> removeStudentFromCourse(String courseId, String studentId) async {
    if (_currentUserId == null || _currentUserRole == null) {
      _setError('User not authenticated');
      return false;
    }
    
    if (_currentUserRole != 'admin' && _currentUserRole != 'teacher') {
      _setError('Only admins and teachers can remove students');
      return false;
    }
    
    try {
      _setLoading(true);
      
      // Update the course's assignedStudentIds array
      await _firestore.collection(coursesCollection).doc(courseId).update({
        'assignedStudentIds': FieldValue.arrayRemove([studentId]),
        'updatedAt': Timestamp.now(),
      });
      
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Error removing student from course: $e');
      return false;
    }
  }
  
  // CONTENT METHODS
  
  Future<List<Content>> getCourseContent(String courseId) async {
    try {
      _setLoading(true);
      
      QuerySnapshot snapshot = await _firestore
          .collection(contentCollection)
          .where('courseId', isEqualTo: courseId)
          .where('isActive', isEqualTo: true)
          .orderBy('orderIndex')
          .get();
      
      List<Content> contentList = snapshot.docs.map((doc) => 
        Content.fromMap(doc.data() as Map<String, dynamic>, doc.id)
      ).toList();
      
      _setLoading(false);
      return contentList;
    } catch (e) {
      _setError('Error getting course content: $e');
      return [];
    }
  }
  
  Future<List<Content>> getStudentContent(String studentId) async {
    try {
      _setLoading(true);
      
      QuerySnapshot snapshot = await _firestore
          .collection(contentCollection)
          .where('assignedStudentIds', arrayContains: studentId)
          .where('isActive', isEqualTo: true)
          .orderBy('updatedAt', descending: true)
          .get();
      
      List<Content> contentList = snapshot.docs.map((doc) => 
        Content.fromMap(doc.data() as Map<String, dynamic>, doc.id)
      ).toList();
      
      _setLoading(false);
      return contentList;
    } catch (e) {
      _setError('Error getting student content: $e');
      return [];
    }
  }
  
  Future<Content?> getContent(String contentId) async {
    try {
      _setLoading(true);
      
      DocumentSnapshot doc = await _firestore.collection(contentCollection).doc(contentId).get();
      
      if (!doc.exists) {
        _setError('Content not found');
        return null;
      }
      
      Content content = Content.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      
      _setLoading(false);
      return content;
    } catch (e) {
      _setError('Error getting content: $e');
      return null;
    }
  }
  
  Future<String?> uploadContentFile(File file, ContentType contentType) async {
    try {
      _setLoading(true);
      
      // Initialize AWS service if needed
      if (!_awsService.isInitialized) {
        await _awsService.initialize();
      }
      
      // Determine the folder based on content type
      String folder;
      switch (contentType) {
        case ContentType.video:
          folder = videosFolder;
          break;
        case ContentType.pdf:
          folder = pdfsFolder;
          break;
        default:
          folder = documentsFolder;
          break;
      }
      
      // Upload the file to S3
      String? fileUrl = await _awsService.uploadFile(
        file: file,
        folder: folder,
      );
      
      _setLoading(false);
      return fileUrl;
    } catch (e) {
      _setError('Error uploading content file: $e');
      return null;
    }
  }
  
  Future<String?> createContent({
    required String title,
    required String description,
    required ContentType contentType,
    required String courseId,
    required String fileUrl,
    String? thumbnailUrl,
    required int orderIndex,
    List<String>? assignedStudentIds,
    Map<String, dynamic>? metadata,
  }) async {
    if (_currentUserId == null || _currentUserRole == null) {
      _setError('User not authenticated');
      return null;
    }
    
    if (_currentUserRole != 'admin' && _currentUserRole != 'teacher') {
      _setError('Only admins and teachers can create content');
      return null;
    }
    
    try {
      _setLoading(true);
      
      // Create a document reference first to get an ID
      DocumentReference docRef = _firestore.collection(contentCollection).doc();
      
      // Create the content object
      Content content = Content(
        id: docRef.id,
        title: title,
        description: description,
        contentType: contentType,
        courseId: courseId,
        createdBy: _currentUserId!,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: true,
        fileUrl: fileUrl,
        thumbnailUrl: thumbnailUrl,
        orderIndex: orderIndex,
        assignedStudentIds: assignedStudentIds ?? [],
        metadata: metadata,
      );
      
      // Save the content to Firestore
      await docRef.set(content.toMap());
      
      _setLoading(false);
      return docRef.id;
    } catch (e) {
      _setError('Error creating content: $e');
      return null;
    }
  }
  
  Future<bool> updateContent({
    required String contentId,
    String? title,
    String? description,
    ContentType? contentType,
    String? courseId,
    String? fileUrl,
    String? thumbnailUrl,
    int? orderIndex,
    List<String>? assignedStudentIds,
    Map<String, dynamic>? metadata,
  }) async {
    if (_currentUserId == null || _currentUserRole == null) {
      _setError('User not authenticated');
      return false;
    }
    
    if (_currentUserRole != 'admin' && _currentUserRole != 'teacher') {
      _setError('Only admins and teachers can update content');
      return false;
    }
    
    try {
      _setLoading(true);
      
      // Get current content data
      DocumentSnapshot doc = await _firestore.collection(contentCollection).doc(contentId).get();
      
      if (!doc.exists) {
        _setError('Content not found');
        return false;
      }
      
      Content content = Content.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      
      // Only the creator or admin can update the content
      if (content.createdBy != _currentUserId && _currentUserRole != 'admin') {
        _setError('You are not authorized to update this content');
        return false;
      }
      
      // Update the content
      Content updatedContent = content.copyWith(
        title: title,
        description: description,
        contentType: contentType,
        courseId: courseId,
        fileUrl: fileUrl,
        thumbnailUrl: thumbnailUrl,
        orderIndex: orderIndex,
        assignedStudentIds: assignedStudentIds,
        metadata: metadata,
      );
      
      // Save updates to Firestore
      await _firestore.collection(contentCollection).doc(contentId).update(updatedContent.toMap());
      
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Error updating content: $e');
      return false;
    }
  }
  
  Future<bool> assignContentToStudent(String contentId, String studentId) async {
    if (_currentUserId == null || _currentUserRole == null) {
      _setError('User not authenticated');
      return false;
    }
    
    if (_currentUserRole != 'admin' && _currentUserRole != 'teacher') {
      _setError('Only admins and teachers can assign content');
      return false;
    }
    
    try {
      _setLoading(true);
      
      // Update the content's assignedStudentIds array
      await _firestore.collection(contentCollection).doc(contentId).update({
        'assignedStudentIds': FieldValue.arrayUnion([studentId]),
        'updatedAt': Timestamp.now(),
      });
      
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Error assigning content to student: $e');
      return false;
    }
  }
  
  // QUIZ METHODS
  
  Future<List<Quiz>> getCourseQuizzes(String courseId) async {
    try {
      _setLoading(true);
      
      QuerySnapshot snapshot = await _firestore
          .collection(quizzesCollection)
          .where('courseId', isEqualTo: courseId)
          .where('requiresApproval', isEqualTo: false) // Only regular quizzes, not tests
          .get();
      
      List<Quiz> quizzes = snapshot.docs.map((doc) => 
        Quiz.fromMap(doc.data() as Map<String, dynamic>, doc.id)
      ).toList();
      
      _setLoading(false);
      return quizzes;
    } catch (e) {
      _setError('Error getting course quizzes: $e');
      return [];
    }
  }
  
  Future<List<Test>> getCourseTests(String courseId) async {
    try {
      _setLoading(true);
      
      QuerySnapshot snapshot = await _firestore
          .collection(quizzesCollection)
          .where('courseId', isEqualTo: courseId)
          .where('requiresApproval', isEqualTo: true) // Only tests, not regular quizzes
          .get();
      
      List<Test> tests = snapshot.docs.map((doc) => 
        Test.fromMap(doc.data() as Map<String, dynamic>, doc.id)
      ).toList();
      
      _setLoading(false);
      return tests;
    } catch (e) {
      _setError('Error getting course tests: $e');
      return [];
    }
  }
  
  Future<Quiz?> getQuiz(String quizId) async {
    try {
      _setLoading(true);
      
      DocumentSnapshot doc = await _firestore.collection(quizzesCollection).doc(quizId).get();
      
      if (!doc.exists) {
        _setError('Quiz not found');
        return null;
      }
      
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      
      // Check if this is a test or a quiz
      if (data.containsKey('requiresApproval') && data['requiresApproval'] == true) {
        _setLoading(false);
        return Test.fromMap(data, doc.id);
      } else {
        _setLoading(false);
        return Quiz.fromMap(data, doc.id);
      }
    } catch (e) {
      _setError('Error getting quiz: $e');
      return null;
    }
  }
  
  Future<String?> createQuiz({
    required String title,
    required String description,
    required String contentId,
    required String courseId,
    required List<Question> questions,
    required int passingScore,
    required bool isTimeLimited,
    int? timeLimit,
    required bool showCorrectAnswers,
    bool isTest = false,
    bool requiresApproval = false,
  }) async {
    if (_currentUserId == null || _currentUserRole == null) {
      _setError('User not authenticated');
      return null;
    }
    
    if (_currentUserRole != 'admin' && _currentUserRole != 'teacher') {
      _setError('Only admins and teachers can create quizzes');
      return null;
    }
    
    try {
      _setLoading(true);
      
      // Calculate total points
      int totalPoints = questions.fold(0, (sum, question) => sum + question.points);
      
      // Create a document reference first to get an ID
      DocumentReference docRef = _firestore.collection(quizzesCollection).doc();
      
      // Assign IDs to questions
      List<Question> questionsWithIds = questions.map((q) {
        return Question(
          id: '${docRef.id}_q${questions.indexOf(q)}',
          questionText: q.questionText,
          questionType: q.questionType,
          options: q.options,
          correctAnswer: q.correctAnswer,
          explanation: q.explanation,
          points: q.points,
        );
      }).toList();
      
      // Create the quiz object
      if (isTest) {
        Test test = Test(
          id: docRef.id,
          title: title,
          description: description,
          contentId: contentId,
          courseId: courseId,
          questions: questionsWithIds,
          passingScore: passingScore,
          totalPoints: totalPoints,
          isTimeLimited: isTimeLimited,
          timeLimit: timeLimit ?? 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: _currentUserId!,
          showCorrectAnswers: showCorrectAnswers,
          requiresApproval: requiresApproval,
        );
        
        // Save the test to Firestore
        await docRef.set(test.toMap());
      } else {
        Quiz quiz = Quiz(
          id: docRef.id,
          title: title,
          description: description,
          contentId: contentId,
          courseId: courseId,
          questions: questionsWithIds,
          passingScore: passingScore,
          totalPoints: totalPoints,
          isTimeLimited: isTimeLimited,
          timeLimit: timeLimit ?? 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: _currentUserId!,
          showCorrectAnswers: showCorrectAnswers,
        );
        
        // Save the quiz to Firestore
        await docRef.set(quiz.toMap());
      }
      
      _setLoading(false);
      return docRef.id;
    } catch (e) {
      _setError('Error creating quiz: $e');
      return null;
    }
  }
  
  Future<String?> startQuizAttempt(String quizId) async {
    if (_currentUserId == null) {
      _setError('User not authenticated');
      return null;
    }
    
    try {
      _setLoading(true);
      
      // Create a document reference first to get an ID
      DocumentReference docRef = _firestore.collection(quizAttemptsCollection).doc();
      
      // Create the quiz attempt object
      QuizAttempt attempt = QuizAttempt(
        id: docRef.id,
        quizId: quizId,
        userId: _currentUserId!,
        startTime: DateTime.now(),
        userAnswers: {},
        score: 0,
        isPassed: false,
        isCompleted: false,
        isApproved: false,
      );
      
      // Save the attempt to Firestore
      await docRef.set(attempt.toMap());
      
      _setLoading(false);
      return docRef.id;
    } catch (e) {
      _setError('Error starting quiz attempt: $e');
      return null;
    }
  }
  
  Future<bool> submitQuizAnswer({
    required String attemptId,
    required String questionId,
    required String answer,
  }) async {
    if (_currentUserId == null) {
      _setError('User not authenticated');
      return false;
    }
    
    try {
      _setLoading(true);
      
      // Update the userAnswers map in the attempt
      await _firestore.collection(quizAttemptsCollection).doc(attemptId).update({
        'userAnswers.$questionId': answer,
        'updatedAt': Timestamp.now(),
      });
      
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Error submitting quiz answer: $e');
      return false;
    }
  }
  
  Future<bool> completeQuizAttempt(String attemptId) async {
    if (_currentUserId == null) {
      _setError('User not authenticated');
      return false;
    }
    
    try {
      _setLoading(true);
      
      // Get the attempt data
      DocumentSnapshot attemptDoc = await _firestore.collection(quizAttemptsCollection).doc(attemptId).get();
      
      if (!attemptDoc.exists) {
        _setError('Attempt not found');
        return false;
      }
      
      QuizAttempt attempt = QuizAttempt.fromMap(attemptDoc.data() as Map<String, dynamic>, attemptDoc.id);
      
      // Get the quiz data
      DocumentSnapshot quizDoc = await _firestore.collection(quizzesCollection).doc(attempt.quizId).get();
      
      if (!quizDoc.exists) {
        _setError('Quiz not found');
        return false;
      }
      
      Quiz quiz = Quiz.fromMap(quizDoc.data() as Map<String, dynamic>, quizDoc.id);
      
      // Calculate the score
      int score = 0;
      for (var question in quiz.questions) {
        String userAnswer = attempt.userAnswers[question.id] ?? '';
        if (userAnswer.toLowerCase() == question.correctAnswer.toLowerCase()) {
          score += question.points;
        }
      }
      
      bool isPassed = score >= quiz.passingScore;
      
      // Update the attempt with the score and completion status
      await _firestore.collection(quizAttemptsCollection).doc(attemptId).update({
        'endTime': Timestamp.now(),
        'score': score,
        'isPassed': isPassed,
        'isCompleted': true,
        'updatedAt': Timestamp.now(),
      });
      
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Error completing quiz attempt: $e');
      return false;
    }
  }
  
  Future<bool> approveQuizAttempt({
    required String attemptId,
    required bool isApproved,
    String? feedback,
  }) async {
    if (_currentUserId == null || _currentUserRole == null) {
      _setError('User not authenticated');
      return false;
    }
    
    if (_currentUserRole != 'admin' && _currentUserRole != 'teacher') {
      _setError('Only admins and teachers can approve quiz attempts');
      return false;
    }
    
    try {
      _setLoading(true);
      
      // Update the attempt with the approval status
      await _firestore.collection(quizAttemptsCollection).doc(attemptId).update({
        'isApproved': isApproved,
        'approvedBy': _currentUserId,
        'approvedAt': Timestamp.now(),
        'feedback': feedback,
        'updatedAt': Timestamp.now(),
      });
      
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Error approving quiz attempt: $e');
      return false;
    }
  }
  
  Future<List<QuizAttempt>> getStudentQuizAttempts(String studentId) async {
    try {
      _setLoading(true);
      
      QuerySnapshot snapshot = await _firestore
          .collection(quizAttemptsCollection)
          .where('userId', isEqualTo: studentId)
          .orderBy('startTime', descending: true)
          .get();
      
      List<QuizAttempt> attempts = snapshot.docs.map((doc) => 
        QuizAttempt.fromMap(doc.data() as Map<String, dynamic>, doc.id)
      ).toList();
      
      _setLoading(false);
      return attempts;
    } catch (e) {
      _setError('Error getting student quiz attempts: $e');
      return [];
    }
  }
  
  Future<List<QuizAttempt>> getPendingApprovalQuizAttempts() async {
    if (_currentUserRole != 'admin' && _currentUserRole != 'teacher') {
      _setError('Only admins and teachers can see pending approvals');
      return [];
    }
    
    try {
      _setLoading(true);
      
      QuerySnapshot snapshot = await _firestore
          .collection(quizAttemptsCollection)
          .where('isCompleted', isEqualTo: true)
          .where('isApproved', isEqualTo: false)
          .orderBy('endTime', descending: true)
          .get();
      
      List<QuizAttempt> attempts = snapshot.docs.map((doc) => 
        QuizAttempt.fromMap(doc.data() as Map<String, dynamic>, doc.id)
      ).toList();
      
      _setLoading(false);
      return attempts;
    } catch (e) {
      _setError('Error getting pending approval attempts: $e');
      return [];
    }
  }
  
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  void _setError(String? errorMessage) {
    _error = errorMessage;
    _isLoading = false;
    notifyListeners();
  }
}