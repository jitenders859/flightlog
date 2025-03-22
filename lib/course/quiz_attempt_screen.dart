import 'package:flutter/material.dart';
import '../constants/colors.dart';
import 'lms_service.dart';
import 'quiz_model.dart';
import '../models/user_model.dart';
import '../services/database_service.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'quiz_result_screen.dart';

class QuizAttemptsScreen extends StatefulWidget {
  final String? quizId; // Optional: filter by specific quiz
  final String? studentId; // Optional: filter by specific student
  final bool pendingOnly; // Show only pending approval attempts

  const QuizAttemptsScreen({
    Key? key,
    this.quizId,
    this.studentId,
    this.pendingOnly = false,
  }) : super(key: key);

  @override
  State<QuizAttemptsScreen> createState() => _QuizAttemptsScreenState();
}

class _QuizAttemptsScreenState extends State<QuizAttemptsScreen> {
  bool _isLoading = true;
  List<QuizAttempt> _attempts = [];
  Map<String, Quiz> _quizzes = {};
  Map<String, UserModel> _students = {};
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAttempts();
  }

  Future<void> _loadAttempts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final lmsService = Provider.of<LMSService>(context, listen: false);
      final databaseService = Provider.of<DatabaseService>(
        context,
        listen: false,
      );

      List<QuizAttempt> attempts;

      if (widget.pendingOnly) {
        attempts = await lmsService.getPendingApprovalQuizAttempts();
      } else if (widget.studentId != null) {
        attempts = await lmsService.getStudentQuizAttempts(widget.studentId!);
      } else {
        // TODO: Implement getting all attempts
        attempts = [];
      }

      // Filter by quiz if specified
      if (widget.quizId != null) {
        attempts = attempts.where((a) => a.quizId == widget.quizId).toList();
      }

      // Load quiz data for each attempt
      final Map<String, Quiz> quizzes = {};
      for (final attempt in attempts) {
        if (!quizzes.containsKey(attempt.quizId)) {
          final quiz = await lmsService.getQuiz(attempt.quizId);
          if (quiz != null) {
            quizzes[attempt.quizId] = quiz;
          }
        }
      }

      // Load student data for each attempt
      final Map<String, UserModel> students = {};
      for (final attempt in attempts) {
        if (!students.containsKey(attempt.userId)) {
          final student = await databaseService.getUser(attempt.userId);
          if (student != null) {
            students[attempt.userId] = student;
          }
        }
      }

      setState(() {
        _attempts = attempts;
        _quizzes = quizzes;
        _students = students;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading quiz attempts: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _approveAttempt(
    String attemptId, {
    required bool approve,
    String? feedback,
  }) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final lmsService = Provider.of<LMSService>(context, listen: false);

      final success = await lmsService.approveQuizAttempt(
        attemptId: attemptId,
        isApproved: approve,
        feedback: feedback,
      );

      if (!success) {
        throw Exception('Failed to update approval status');
      }

      // Reload the attempts
      await _loadAttempts();

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              approve
                  ? 'Attempt approved successfully'
                  : 'Attempt rejected successfully',
            ),
            backgroundColor: approve ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error updating approval status: $e';
        _isLoading = false;
      });

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showApprovalDialog(QuizAttempt attempt) {
    final feedbackController = TextEditingController();
    bool isApproving = true;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(isApproving ? 'Approve Attempt' : 'Reject Attempt'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Toggle buttons for approve/reject
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment<bool>(
                        value: true,
                        label: Text('Approve'),
                        icon: Icon(Icons.check_circle),
                      ),
                      ButtonSegment<bool>(
                        value: false,
                        label: Text('Reject'),
                        icon: Icon(Icons.cancel),
                      ),
                    ],
                    selected: {isApproving},
                    onSelectionChanged: (selectedSet) {
                      setDialogState(() {
                        isApproving = selectedSet.first;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Feedback field
                  const Text(
                    'Feedback (optional):',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: feedbackController,
                    decoration: const InputDecoration(
                      hintText: 'Enter feedback for the student',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _approveAttempt(
                      attempt.id,
                      approve: isApproving,
                      feedback:
                          feedbackController.text.isNotEmpty
                              ? feedbackController.text
                              : null,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isApproving ? Colors.green : Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(isApproving ? 'Approve' : 'Reject'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pendingOnly ? 'Pending Approvals' : 'Quiz Attempts'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadAttempts),
        ],
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
                onPressed: _loadAttempts,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_attempts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              widget.pendingOnly
                  ? Icons.hourglass_empty
                  : Icons.assignment_outlined,
              size: 64,
              color: Colors.grey.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              widget.pendingOnly
                  ? 'No pending approvals'
                  : 'No quiz attempts found',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              widget.pendingOnly
                  ? 'All student tests have been reviewed'
                  : 'Students have not taken any quizzes yet',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _attempts.length,
      itemBuilder: (context, index) {
        final attempt = _attempts[index];
        final quiz = _quizzes[attempt.quizId];
        final student = _students[attempt.userId];

        if (quiz == null) {
          return const SizedBox.shrink();
        }

        final bool isTest = quiz is Test;
        final bool isPending = isTest && !attempt.isApproved;
        final bool isPassed = attempt.isPassed;

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: isPending ? 3 : 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side:
                isPending
                    ? const BorderSide(color: Colors.orange, width: 1)
                    : BorderSide.none,
          ),
          child: InkWell(
            onTap: () {
              // View the attempt details
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) =>
                          QuizResultScreen(quiz: quiz, attemptId: attempt.id),
                ),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with user and status
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppColors.studentColor,
                        child: Text(
                          student != null
                              ? student.firstName[0] + student.lastName[0]
                              : '??',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              student?.fullName ?? 'Unknown Student',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              quiz.title,
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                      _buildStatusBadge(attempt),
                    ],
                  ),

                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 16),

                  // Attempt details
                  Row(
                    children: [
                      Expanded(
                        child: _buildDetailItem(
                          icon: Icons.score,
                          title: 'Score',
                          value: '${attempt.score}/${quiz.totalPoints}',
                          valueColor: isPassed ? Colors.green : Colors.red,
                        ),
                      ),
                      Expanded(
                        child: _buildDetailItem(
                          icon: Icons.percent,
                          title: 'Percentage',
                          value:
                              '${((attempt.score / quiz.totalPoints) * 100).toStringAsFixed(0)}%',
                          valueColor: isPassed ? Colors.green : Colors.red,
                        ),
                      ),
                      Expanded(
                        child: _buildDetailItem(
                          icon: Icons.calendar_today,
                          title: 'Date',
                          value: DateFormat('MMM d').format(attempt.startTime),
                        ),
                      ),
                    ],
                  ),

                  // Actions for pending approvals
                  if (isPending) ...[
                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => QuizResultScreen(
                                        quiz: quiz,
                                        attemptId: attempt.id,
                                      ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.visibility),
                            label: const Text('View'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.blue,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _showApprovalDialog(attempt),
                            icon: const Icon(Icons.rate_review),
                            label: const Text('Review'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(QuizAttempt attempt) {
    Color badgeColor;
    String badgeText;
    IconData badgeIcon;

    if (!attempt.isCompleted) {
      badgeColor = Colors.blue;
      badgeText = 'In Progress';
      badgeIcon = Icons.hourglass_top;
    } else if (!attempt.isApproved) {
      badgeColor = Colors.orange;
      badgeText = 'Pending';
      badgeIcon = Icons.hourglass_empty;
    } else if (attempt.isPassed) {
      badgeColor = Colors.green;
      badgeText = 'Passed';
      badgeIcon = Icons.check_circle;
    } else {
      badgeColor = Colors.red;
      badgeText = 'Failed';
      badgeIcon = Icons.cancel;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: badgeColor.withOpacity(0.5), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(badgeIcon, size: 14, color: badgeColor),
          const SizedBox(width: 4),
          Text(
            badgeText,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: badgeColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String title,
    required String value,
    Color? valueColor,
  }) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(fontWeight: FontWeight.bold, color: valueColor),
        ),
        Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }
}
