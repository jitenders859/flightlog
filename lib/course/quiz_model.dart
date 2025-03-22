import 'package:cloud_firestore/cloud_firestore.dart';

enum QuestionType {
  multipleChoice,
  trueFalse,
  shortAnswer,
}

class Question {
  final String id;
  final String questionText;
  final QuestionType questionType;
  final List<String> options; // For multiple choice questions
  final String correctAnswer;
  final String explanation; // Description of the correct answer
  final int points;

  Question({
    required this.id,
    required this.questionText,
    required this.questionType,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
    this.points = 1,
  });

  factory Question.fromMap(Map<String, dynamic> map, String id) {
    return Question(
      id: id,
      questionText: map['questionText'] ?? '',
      questionType: _parseQuestionType(map['questionType'] ?? 'multipleChoice'),
      options: List<String>.from(map['options'] ?? []),
      correctAnswer: map['correctAnswer'] ?? '',
      explanation: map['explanation'] ?? '',
      points: map['points'] ?? 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'questionText': questionText,
      'questionType': questionType.toString().split('.').last,
      'options': options,
      'correctAnswer': correctAnswer,
      'explanation': explanation,
      'points': points,
    };
  }

  static QuestionType _parseQuestionType(String typeString) {
    switch (typeString.toLowerCase()) {
      case 'multiplechoice':
        return QuestionType.multipleChoice;
      case 'truefalse':
        return QuestionType.trueFalse;
      case 'shortanswer':
        return QuestionType.shortAnswer;
      default:
        return QuestionType.multipleChoice;
    }
  }
}

class Quiz {
  final String id;
  final String title;
  final String description;
  final String contentId; // Related content ID
  final String courseId;
  final List<Question> questions;
  final int passingScore; // Minimum score to pass
  final int totalPoints; // Sum of all question points
  final bool isTimeLimited;
  final int timeLimit; // In minutes, if isTimeLimited is true
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final bool showCorrectAnswers; // Show correct answers after submission

  Quiz({
    required this.id,
    required this.title,
    required this.description,
    required this.contentId,
    required this.courseId,
    required this.questions,
    required this.passingScore,
    required this.totalPoints,
    required this.isTimeLimited,
    this.timeLimit = 0,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    this.showCorrectAnswers = true,
  });

  factory Quiz.fromMap(Map<String, dynamic> map, String id) {
    List<Question> questionsList = [];
    if (map['questions'] != null) {
      final questionsMap = map['questions'] as Map<String, dynamic>;
      questionsMap.forEach((qId, qData) {
        questionsList.add(Question.fromMap(qData, qId));
      });
    }

    return Quiz(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      contentId: map['contentId'] ?? '',
      courseId: map['courseId'] ?? '',
      questions: questionsList,
      passingScore: map['passingScore'] ?? 0,
      totalPoints: map['totalPoints'] ?? 0,
      isTimeLimited: map['isTimeLimited'] ?? false,
      timeLimit: map['timeLimit'] ?? 0,
      createdAt: (map['createdAt'] != null)
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: (map['updatedAt'] != null)
          ? (map['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
      createdBy: map['createdBy'] ?? '',
      showCorrectAnswers: map['showCorrectAnswers'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    Map<String, dynamic> questionsMap = {};
    for (var question in questions) {
      questionsMap[question.id] = question.toMap();
    }

    return {
      'title': title,
      'description': description,
      'contentId': contentId,
      'courseId': courseId,
      'questions': questionsMap,
      'passingScore': passingScore,
      'totalPoints': totalPoints,
      'isTimeLimited': isTimeLimited,
      'timeLimit': timeLimit,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'createdBy': createdBy,
      'showCorrectAnswers': showCorrectAnswers,
    };
  }
}

class QuizAttempt {
  final String id;
  final String quizId;
  final String userId;
  final DateTime startTime;
  final DateTime? endTime;
  final Map<String, String> userAnswers; // questionId -> userAnswer
  final int score;
  final bool isPassed;
  final bool isCompleted;
  final bool isApproved; // Teacher/admin approval
  final String? approvedBy;
  final DateTime? approvedAt;
  final String? feedback; // Teacher/admin feedback

  QuizAttempt({
    required this.id,
    required this.quizId,
    required this.userId,
    required this.startTime,
    this.endTime,
    required this.userAnswers,
    required this.score,
    required this.isPassed,
    required this.isCompleted,
    required this.isApproved,
    this.approvedBy,
    this.approvedAt,
    this.feedback,
  });

  factory QuizAttempt.fromMap(Map<String, dynamic> map, String id) {
    return QuizAttempt(
      id: id,
      quizId: map['quizId'] ?? '',
      userId: map['userId'] ?? '',
      startTime: (map['startTime'] != null)
          ? (map['startTime'] as Timestamp).toDate()
          : DateTime.now(),
      endTime: map['endTime'] != null
          ? (map['endTime'] as Timestamp).toDate()
          : null,
      userAnswers: Map<String, String>.from(map['userAnswers'] ?? {}),
      score: map['score'] ?? 0,
      isPassed: map['isPassed'] ?? false,
      isCompleted: map['isCompleted'] ?? false,
      isApproved: map['isApproved'] ?? false,
      approvedBy: map['approvedBy'],
      approvedAt: map['approvedAt'] != null
          ? (map['approvedAt'] as Timestamp).toDate()
          : null,
      feedback: map['feedback'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'quizId': quizId,
      'userId': userId,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
      'userAnswers': userAnswers,
      'score': score,
      'isPassed': isPassed,
      'isCompleted': isCompleted,
      'isApproved': isApproved,
      'approvedBy': approvedBy,
      'approvedAt': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
      'feedback': feedback,
    };
  }

  QuizAttempt copyWith({
    DateTime? endTime,
    Map<String, String>? userAnswers,
    int? score,
    bool? isPassed,
    bool? isCompleted,
    bool? isApproved,
    String? approvedBy,
    DateTime? approvedAt,
    String? feedback,
  }) {
    return QuizAttempt(
      id: this.id,
      quizId: this.quizId,
      userId: this.userId,
      startTime: this.startTime,
      endTime: endTime ?? this.endTime,
      userAnswers: userAnswers ?? this.userAnswers,
      score: score ?? this.score,
      isPassed: isPassed ?? this.isPassed,
      isCompleted: isCompleted ?? this.isCompleted,
      isApproved: isApproved ?? this.isApproved,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      feedback: feedback ?? this.feedback,
    );
  }
}

class Test extends Quiz {
  final bool requiresApproval; // Whether the test needs teacher/admin approval
  
  Test({
    required super.id,
    required super.title,
    required super.description,
    required super.contentId,
    required super.courseId,
    required super.questions,
    required super.passingScore,
    required super.totalPoints,
    required super.isTimeLimited,
    required super.timeLimit,
    required super.createdAt,
    required super.updatedAt,
    required super.createdBy,
    required super.showCorrectAnswers,
    required this.requiresApproval,
  });
  
  factory Test.fromQuiz(Quiz quiz, {required bool requiresApproval}) {
    return Test(
      id: quiz.id,
      title: quiz.title,
      description: quiz.description,
      contentId: quiz.contentId,
      courseId: quiz.courseId,
      questions: quiz.questions,
      passingScore: quiz.passingScore,
      totalPoints: quiz.totalPoints,
      isTimeLimited: quiz.isTimeLimited,
      timeLimit: quiz.timeLimit,
      createdAt: quiz.createdAt,
      updatedAt: quiz.updatedAt,
      createdBy: quiz.createdBy,
      showCorrectAnswers: quiz.showCorrectAnswers,
      requiresApproval: requiresApproval,
    );
  }
  
  factory Test.fromMap(Map<String, dynamic> map, String id) {
    final quiz = Quiz.fromMap(map, id);
    return Test.fromQuiz(
      quiz,
      requiresApproval: map['requiresApproval'] ?? true,
    );
  }
  
  @override
  Map<String, dynamic> toMap() {
    final Map<String, dynamic> map = super.toMap();
    map['requiresApproval'] = requiresApproval;
    return map;
  }
}