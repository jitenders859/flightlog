import 'dart:async';
import 'package:flutter/material.dart';
import 'quiz_model.dart';

class QuizWidget extends StatefulWidget {
  final Quiz quiz;
  final String attemptId;
  final Function(String questionId, String answer) onAnswerSubmitted;
  final Function() onQuizCompleted;

  const QuizWidget({
    Key? key,
    required this.quiz,
    required this.attemptId,
    required this.onAnswerSubmitted,
    required this.onQuizCompleted,
  }) : super(key: key);

  @override
  State<QuizWidget> createState() => _QuizWidgetState();
}

class _QuizWidgetState extends State<QuizWidget> {
  int _currentQuestionIndex = 0;
  Map<String, String> _userAnswers = {};
  bool _isSubmitting = false;
  bool _showExplanation = false;
  bool _isTimeUp = false;

  // Timer for timed quizzes/tests
  Timer? _timer;
  int _remainingSeconds = 0;

  @override
  void initState() {
    super.initState();

    // Initialize timer if quiz is time-limited
    if (widget.quiz.isTimeLimited && widget.quiz.timeLimit > 0) {
      _remainingSeconds =
          widget.quiz.timeLimit * 60; // Convert minutes to seconds
      _startTimer();
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _timer?.cancel();
          _isTimeUp = true;
          _submitQuiz();
        }
      });
    });
  }

  String _formatTime(int seconds) {
    int hours = seconds ~/ 3600;
    int minutes = (seconds % 3600) ~/ 60;
    int secs = seconds % 60;

    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Future<void> _submitAnswer(String answer) async {
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    final questionId = widget.quiz.questions[_currentQuestionIndex].id;

    try {
      // Save answer locally
      setState(() {
        _userAnswers[questionId] = answer;
      });

      // Send answer to service
      await widget.onAnswerSubmitted(questionId, answer);

      // Show explanation if enabled
      if (widget.quiz.showCorrectAnswers) {
        setState(() {
          _showExplanation = true;
        });

        // Auto-advance after delay if not the last question
        if (_currentQuestionIndex < widget.quiz.questions.length - 1) {
          Timer(const Duration(seconds: 3), () {
            if (mounted) {
              setState(() {
                _showExplanation = false;
                _currentQuestionIndex++;
                _isSubmitting = false;
              });
            }
          });
        } else {
          Timer(const Duration(seconds: 3), () {
            if (mounted) {
              setState(() {
                _showExplanation = false;
                _isSubmitting = false;
              });
              _submitQuiz();
            }
          });
        }
      } else {
        // Move to next question immediately
        if (_currentQuestionIndex < widget.quiz.questions.length - 1) {
          setState(() {
            _currentQuestionIndex++;
            _isSubmitting = false;
          });
        } else {
          setState(() {
            _isSubmitting = false;
          });
          _submitQuiz();
        }
      }
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting answer: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _submitQuiz() {
    _timer?.cancel();
    widget.onQuizCompleted();
  }

  @override
  Widget build(BuildContext context) {
    final question = widget.quiz.questions[_currentQuestionIndex];
    final currentAnswer = _userAnswers[question.id];
    final isAnswered = currentAnswer != null;
    final isCorrect =
        isAnswered &&
        currentAnswer.toLowerCase() == question.correctAnswer.toLowerCase();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Quiz header with progress and timer
        Container(
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).primaryColor.withOpacity(0.1),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Question ${_currentQuestionIndex + 1} of ${widget.quiz.questions.length}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (widget.quiz.isTimeLimited) ...[
                    Row(
                      children: [
                        const Icon(Icons.timer, size: 18, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          _formatTime(_remainingSeconds),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color:
                                _remainingSeconds < 60
                                    ? Colors.red
                                    : (_remainingSeconds < 300
                                        ? Colors.orange
                                        : Colors.black),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value:
                    ((_currentQuestionIndex + 1) /
                        widget.quiz.questions.length),
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
        ),

        // Question and answers
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Question text
                Text(
                  question.questionText,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),

                // Answer options or input field
                if (question.questionType == QuestionType.multipleChoice) ...[
                  ...question.options.map((option) {
                    final isSelected = isAnswered && currentAnswer == option;
                    final isCorrectOption =
                        option.toLowerCase() ==
                        question.correctAnswer.toLowerCase();

                    // Determine color based on whether answer is shown and if it's correct
                    Color? optionColor;
                    if (_showExplanation) {
                      if (isCorrectOption) {
                        optionColor = Colors.green.withOpacity(0.2);
                      } else if (isSelected && !isCorrectOption) {
                        optionColor = Colors.red.withOpacity(0.2);
                      }
                    } else if (isSelected) {
                      optionColor = Theme.of(
                        context,
                      ).primaryColor.withOpacity(0.1);
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color:
                              isSelected
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey.withOpacity(0.3),
                          width: isSelected ? 2 : 1,
                        ),
                        color: optionColor,
                      ),
                      child: InkWell(
                        onTap:
                            isAnswered || _isSubmitting
                                ? null
                                : () => _submitAnswer(option),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              isSelected
                                  ? Icon(
                                    Icons.check_circle,
                                    color: Theme.of(context).primaryColor,
                                  )
                                  : const Icon(
                                    Icons.circle_outlined,
                                    color: Colors.grey,
                                  ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  option,
                                  style: TextStyle(
                                    fontWeight:
                                        isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                  ),
                                ),
                              ),
                              if (_showExplanation && isCorrectOption) ...[
                                const Icon(Icons.check, color: Colors.green),
                              ],
                              if (_showExplanation &&
                                  isSelected &&
                                  !isCorrectOption) ...[
                                const Icon(Icons.close, color: Colors.red),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ] else if (question.questionType == QuestionType.trueFalse) ...[
                  // True/False options
                  ...['True', 'False'].map((option) {
                    final isSelected =
                        isAnswered &&
                        currentAnswer.toLowerCase() == option.toLowerCase();
                    final isCorrectOption =
                        option.toLowerCase() ==
                        question.correctAnswer.toLowerCase();

                    Color? optionColor;
                    if (_showExplanation) {
                      if (isCorrectOption) {
                        optionColor = Colors.green.withOpacity(0.2);
                      } else if (isSelected && !isCorrectOption) {
                        optionColor = Colors.red.withOpacity(0.2);
                      }
                    } else if (isSelected) {
                      optionColor = Theme.of(
                        context,
                      ).primaryColor.withOpacity(0.1);
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color:
                              isSelected
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey.withOpacity(0.3),
                          width: isSelected ? 2 : 1,
                        ),
                        color: optionColor,
                      ),
                      child: InkWell(
                        onTap:
                            isAnswered || _isSubmitting
                                ? null
                                : () => _submitAnswer(option),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              isSelected
                                  ? Icon(
                                    Icons.check_circle,
                                    color: Theme.of(context).primaryColor,
                                  )
                                  : const Icon(
                                    Icons.circle_outlined,
                                    color: Colors.grey,
                                  ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  option,
                                  style: TextStyle(
                                    fontWeight:
                                        isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                  ),
                                ),
                              ),
                              if (_showExplanation && isCorrectOption) ...[
                                const Icon(Icons.check, color: Colors.green),
                              ],
                              if (_showExplanation &&
                                  isSelected &&
                                  !isCorrectOption) ...[
                                const Icon(Icons.close, color: Colors.red),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ] else if (question.questionType ==
                    QuestionType.shortAnswer) ...[
                  // Short answer text field
                  TextField(
                    enabled: !isAnswered && !_isSubmitting,
                    decoration: const InputDecoration(
                      hintText: 'Type your answer here',
                      border: OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(Icons.send),
                        onPressed: null,
                        // isAnswered || _isSubmitting
                        //     ? null
                        //     : () {
                        //       // Get the current text value from controller
                        //       final fieldValue =
                        //           (context.findRenderObject() as RenderBox)
                        //               .findObject(
                        //                 const Text(
                        //                   'TODO: Implement text field value extraction',
                        //                 ),
                        //               )
                        //               .toString();

                        //       if (fieldValue.isNotEmpty) {
                        //         _submitAnswer(fieldValue);
                        //       }
                        //     },
                      ),
                    ),
                    onSubmitted:
                        isAnswered || _isSubmitting
                            ? null
                            : (value) {
                              if (value.isNotEmpty) {
                                _submitAnswer(value);
                              }
                            },
                  ),
                  if (isAnswered) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Your answer: $currentAnswer',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color:
                            _showExplanation
                                ? (isCorrect ? Colors.green : Colors.red)
                                : Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ],

                // Explanation section
                if (_showExplanation) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color:
                          isCorrect
                              ? Colors.green.withOpacity(0.1)
                              : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isCorrect ? Colors.green : Colors.red,
                        width: 1,
                      ),
                    ),
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
                            Text(
                              isCorrect ? 'Correct!' : 'Incorrect',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isCorrect ? Colors.green : Colors.red,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('Correct answer: ${question.correctAnswer}'),
                        const SizedBox(height: 8),
                        Text(
                          question.explanation,
                          style: const TextStyle(fontStyle: FontStyle.italic),
                        ),
                        if (_currentQuestionIndex <
                            widget.quiz.questions.length - 1) ...[
                          const SizedBox(height: 16),
                          const Text(
                            'Next question in 3 seconds...',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ] else ...[
                          const SizedBox(height: 16),
                          const Text(
                            'Quiz will be submitted in 3 seconds...',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        // Bottom navigation
        if (!_showExplanation) ...[
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Previous button
                if (_currentQuestionIndex > 0) ...[
                  ElevatedButton(
                    onPressed:
                        _isSubmitting
                            ? null
                            : () {
                              setState(() {
                                _currentQuestionIndex--;
                              });
                            },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[200],
                      foregroundColor: Colors.black,
                    ),
                    child: const Text('Previous'),
                  ),
                ] else ...[
                  const SizedBox(width: 90), // Placeholder for balance
                ],

                // Question counter
                Text(
                  '${_currentQuestionIndex + 1} / ${widget.quiz.questions.length}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),

                // Skip/Next button (for already answered questions)
                if (isAnswered) ...[
                  ElevatedButton(
                    onPressed:
                        _isSubmitting
                            ? null
                            : () {
                              if (_currentQuestionIndex <
                                  widget.quiz.questions.length - 1) {
                                setState(() {
                                  _currentQuestionIndex++;
                                });
                              } else {
                                _submitQuiz();
                              }
                            },
                    child: Text(
                      _currentQuestionIndex < widget.quiz.questions.length - 1
                          ? 'Next'
                          : 'Finish',
                    ),
                  ),
                ] else ...[
                  ElevatedButton(
                    onPressed:
                        _isSubmitting
                            ? null
                            : () {
                              // Skip this question
                              if (_currentQuestionIndex <
                                  widget.quiz.questions.length - 1) {
                                setState(() {
                                  _currentQuestionIndex++;
                                });
                              } else {
                                _submitQuiz();
                              }
                            },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[200],
                      foregroundColor: Colors.black,
                    ),
                    child: Text(
                      _currentQuestionIndex < widget.quiz.questions.length - 1
                          ? 'Skip'
                          : 'Finish',
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],

        // Time up alert
        if (_isTimeUp) ...[
          Container(
            color: Colors.red,
            padding: const EdgeInsets.all(16),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.timer_off, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  'Time\'s up! Quiz has been submitted.',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
