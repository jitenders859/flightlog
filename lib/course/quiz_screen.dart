import 'package:flutter/material.dart';
import 'lms_service.dart';
import 'quiz_model.dart';
import 'quiz_widget.dart';
import 'package:provider/provider.dart';

import 'quiz_result_screen.dart';

class QuizScreen extends StatefulWidget {
  final Quiz quiz;

  const QuizScreen({
    Key? key,
    required this.quiz,
  }) : super(key: key);

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  bool _isLoading = false;
  String? _errorMessage;
  String? _attemptId;
  bool _hasStarted = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.quiz.title),
        // Exit confirmation dialog
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            _showExitConfirmationDialog();
          },
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                'Error',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Return to Course'),
              ),
            ],
          ),
        ),
      );
    }

    if (!_hasStarted) {
      return _buildQuizIntro();
    }

    if (_attemptId == null) {
      return const Center(
        child: Text('Error: Unable to start quiz attempt'),
      );
    }

    return QuizWidget(
      quiz: widget.quiz,
      attemptId: _attemptId!,
      onAnswerSubmitted: _submitAnswer,
      onQuizCompleted: _completeQuiz,
    );
  }

  Widget _buildQuizIntro() {
    bool isTest = widget.quiz is Test;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quiz/Test Title and Description
          Text(
            widget.quiz.title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isTest ? Colors.purple : Colors.blue,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.quiz.description,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          
          const SizedBox(height: 32),
          
          // Quiz/Test information card
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quiz type and question count
                  Row(
                    children: [
                      Icon(
                        isTest ? Icons.assignment : Icons.quiz,
                        color: isTest ? Colors.purple : Colors.blue,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isTest ? 'Test' : 'Quiz',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.help_outline,
                        color: Colors.grey[600],
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.quiz.questions.length} Questions',
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  
                  // Time limit
                  if (widget.quiz.isTimeLimited) ...[
                    Row(
                      children: [
                        const Icon(Icons.timer, color: Colors.orange),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Time Limit',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${widget.quiz.timeLimit} minutes',
                              style: TextStyle(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // Passing score
                  Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Passing Score',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${widget.quiz.passingScore}% (${widget.quiz.totalPoints} total points)',
                            style: TextStyle(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Approval requirement
                  if (isTest && (widget.quiz as Test).requiresApproval) ...[
                    Row(
                      children: [
                        const Icon(Icons.person, color: Colors.blue),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Teacher Approval Required',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Your test will be reviewed by your teacher before finalizing the score',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // Show answers
                  Row(
                    children: [
                      const Icon(Icons.visibility, color: Colors.purple),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Results Visibility',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              widget.quiz.showCorrectAnswers
                                  ? 'Correct answers will be shown after each question'
                                  : 'Answers will be shown after completion',
                              style: TextStyle(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Instructions
          Text(
            'Instructions',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '• Read each question carefully before answering.\n'
            '• Once you start, the timer will begin counting down.\n'
            '• You must complete the entire quiz in one session.\n'
            '• Ensure you have a stable internet connection.\n'
            '• Do not refresh or close the page during the quiz.',
            style: TextStyle(
              height: 1.5,
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Start button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _startQuiz,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: isTest ? Colors.purple : Colors.blue,
              ),
              child: Text('Start ${isTest ? 'Test' : 'Quiz'}'),
            ),
          ),
          
          // Cancel button
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startQuiz() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final lmsService = Provider.of<LMSService>(context, listen: false);
      
      // Start a new quiz attempt
      final attemptId = await lmsService.startQuizAttempt(widget.quiz.id);
      
      if (attemptId == null) {
        throw Exception('Failed to start quiz attempt');
      }
      
      setState(() {
        _attemptId = attemptId;
        _hasStarted = true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error starting quiz: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _submitAnswer(String questionId, String answer) async {
    if (_attemptId == null) return;
    
    try {
      final lmsService = Provider.of<LMSService>(context, listen: false);
      
      await lmsService.submitQuizAnswer(
        attemptId: _attemptId!,
        questionId: questionId,
        answer: answer,
      );
      
      return;
    } catch (e) {
      // Show error but don't interrupt the quiz
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting answer: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _completeQuiz() async {
    if (_attemptId == null) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final lmsService = Provider.of<LMSService>(context, listen: false);
      
      final success = await lmsService.completeQuizAttempt(_attemptId!);
      
      if (!success) {
        throw Exception('Failed to complete quiz');
      }
      
      // Navigate to results screen
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => QuizResultScreen(
              quiz: widget.quiz,
              attemptId: _attemptId!,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error completing quiz: $e';
        _isLoading = false;
      });
    }
  }

  void _showExitConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit Quiz?'),
        content: const Text(
          'Are you sure you want to exit? Your progress will be lost and you will need to start over.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Exit quiz screen
            },
            child: const Text('Exit Quiz'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}