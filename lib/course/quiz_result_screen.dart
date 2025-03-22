import 'package:flutter/material.dart';
import '../constants/colors.dart';
import 'lms_service.dart';
import 'quiz_model.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class QuizResultScreen extends StatefulWidget {
  final Quiz quiz;
  final String attemptId;

  const QuizResultScreen({
    Key? key,
    required this.quiz,
    required this.attemptId,
  }) : super(key: key);

  @override
  State<QuizResultScreen> createState() => _QuizResultScreenState();
}

class _QuizResultScreenState extends State<QuizResultScreen> {
  bool _isLoading = true;
  QuizAttempt? _attempt;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAttemptData();
  }

  Future<void> _loadAttemptData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final lmsService = Provider.of<LMSService>(context, listen: false);

      // Get the attempt
      final attempts = await lmsService.getStudentQuizAttempts(
        'current',
      ); // 'current' will use the current user's ID
      final attempt = attempts.firstWhere(
        (a) => a.id == widget.attemptId,
        orElse: () => throw Exception('Attempt not found'),
      );

      setState(() {
        _attempt = attempt;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading quiz results: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz Results'),
        // Prevent going back to the quiz
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            // Return to course screen
            Navigator.of(context).pop();
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
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Error',
                style: Theme.of(
                  context,
                ).textTheme.headlineSmall?.copyWith(color: Colors.red),
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

    if (_attempt == null) {
      return const Center(child: Text('No attempt data found.'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildResultSummaryCard(),
          const SizedBox(height: 24),
          _buildQuestionAnalysis(),
        ],
      ),
    );
  }

  Widget _buildResultSummaryCard() {
    final bool isTest = widget.quiz is Test;
    final bool isPending = isTest && !_attempt!.isApproved;
    final bool isPassed = _attempt!.isPassed;

    // Calculate percentages
    final double scorePercentage =
        widget.quiz.totalPoints > 0
            ? (_attempt!.score / widget.quiz.totalPoints) * 100
            : 0;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.quiz.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isTest ? 'Test Results' : 'Quiz Results',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
                _buildStatusBadge(),
              ],
            ),

            const SizedBox(height: 24),

            // Score visualization
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 150,
                    height: 150,
                    child: CircularProgressIndicator(
                      value: scorePercentage / 100,
                      strokeWidth: 10,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isPending
                            ? Colors.orange
                            : (isPassed ? Colors.green : Colors.red),
                      ),
                    ),
                  ),
                  Column(
                    children: [
                      Text(
                        '${scorePercentage.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${_attempt!.score}/${widget.quiz.totalPoints}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Quiz metadata
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildInfoItem(
                  icon: Icons.assignment,
                  title: 'Questions',
                  value: widget.quiz.questions.length.toString(),
                ),
                _buildInfoItem(
                  icon: Icons.access_time,
                  title: 'Time Taken',
                  value: _formatDuration(),
                ),
                _buildInfoItem(
                  icon: Icons.calendar_today,
                  title: 'Date',
                  value: DateFormat('MMM d, yyyy').format(_attempt!.startTime),
                ),
              ],
            ),

            if (isPending && isTest) ...[
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),

              Center(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange, width: 1),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Awaiting Teacher Approval',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Your test results will be finalized after review',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            if (_attempt!.isApproved &&
                _attempt!.feedback != null &&
                _attempt!.feedback!.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Teacher Feedback',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.blue.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(_attempt!.feedback!),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 24),

            // Return to course button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                child: const Text('Return to Course'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionAnalysis() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Question Analysis',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        ...widget.quiz.questions.map((question) {
          final userAnswer =
              _attempt!.userAnswers[question.id] ?? 'Not answered';
          final isCorrect =
              userAnswer.toLowerCase() == question.correctAnswer.toLowerCase();

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        isCorrect ? Icons.check_circle : Icons.cancel,
                        color: isCorrect ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          question.questionText,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isCorrect
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isCorrect ? '+${question.points}' : '0',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isCorrect ? Colors.green : Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Your answer
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(
                        width: 100,
                        child: Text(
                          'Your answer:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          userAnswer,
                          style: TextStyle(
                            color: isCorrect ? Colors.green : Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Correct answer (if wrong)
                  if (!isCorrect) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(
                          width: 100,
                          child: Text(
                            'Correct answer:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            question.correctAnswer,
                            style: const TextStyle(color: Colors.green),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],

                  // Explanation
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(
                        width: 100,
                        child: Text(
                          'Explanation:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          question.explanation,
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildStatusBadge() {
    final bool isTest = widget.quiz is Test;
    final bool isPending = isTest && !_attempt!.isApproved;
    final bool isPassed = _attempt!.isPassed;

    Color badgeColor;
    String badgeText;
    IconData badgeIcon;

    if (isPending) {
      badgeColor = Colors.orange;
      badgeText = 'Pending';
      badgeIcon = Icons.hourglass_empty;
    } else if (isPassed) {
      badgeColor = Colors.green;
      badgeText = 'Passed';
      badgeIcon = Icons.check_circle;
    } else {
      badgeColor = Colors.red;
      badgeText = 'Failed';
      badgeIcon = Icons.cancel;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: badgeColor.withOpacity(0.5), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(badgeIcon, size: 16, color: badgeColor),
          const SizedBox(width: 4),
          Text(
            badgeText,
            style: TextStyle(fontWeight: FontWeight.bold, color: badgeColor),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.grey[600]),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  String _formatDuration() {
    if (_attempt?.startTime == null || _attempt?.endTime == null) {
      return 'N/A';
    }

    final duration = _attempt!.endTime!.difference(_attempt!.startTime);

    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else {
      return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
    }
  }
}
