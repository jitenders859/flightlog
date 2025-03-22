import 'package:flutter/material.dart';
import '../constants/colors.dart';
import 'course_mode.dart';
import 'lms_service.dart';
import 'quiz_model.dart';
import 'package:provider/provider.dart';

class QuizBuilderScreen extends StatefulWidget {
  final Course course;
  final bool isTest; // Whether creating a quiz or test

  const QuizBuilderScreen({Key? key, required this.course, this.isTest = false})
    : super(key: key);

  @override
  State<QuizBuilderScreen> createState() => _QuizBuilderScreenState();
}

class _QuizBuilderScreenState extends State<QuizBuilderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _passingScoreController = TextEditingController(text: '70');
  final _timeLimitController = TextEditingController(text: '30');

  bool _isTimeLimited = true;
  bool _showCorrectAnswers = true;
  bool _requiresApproval = false;

  List<Question> _questions = [];

  bool _isCreating = false;
  String? _errorMessage;
  String _contentId = '';

  @override
  void initState() {
    super.initState();

    // If creating a test, set approval required to true by default
    if (widget.isTest) {
      _requiresApproval = true;
    }

    // Add a default first question
    _addQuestion();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _passingScoreController.dispose();
    _timeLimitController.dispose();
    super.dispose();
  }

  void _addQuestion() {
    setState(() {
      _questions.add(
        Question(
          id: 'q${_questions.length + 1}',
          questionText: '',
          questionType: QuestionType.multipleChoice,
          options: ['', '', '', ''],
          correctAnswer: '',
          explanation: '',
          points: 1,
        ),
      );
    });
  }

  void _removeQuestion(int index) {
    if (_questions.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You need at least one question'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _questions.removeAt(index);
    });
  }

  void _updateQuestion(int index, Question updatedQuestion) {
    setState(() {
      _questions[index] = updatedQuestion;
    });
  }

  Future<void> _createQuiz() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate all questions
    for (int i = 0; i < _questions.length; i++) {
      if (!_validateQuestion(i)) {
        return;
      }
    }

    setState(() {
      _isCreating = true;
      _errorMessage = null;
    });

    try {
      final lmsService = Provider.of<LMSService>(context, listen: false);

      final quizId = await lmsService.createQuiz(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        contentId:
            _contentId, // This would be set if coming from content creation
        courseId: widget.course.id,
        questions: _questions,
        passingScore: int.parse(_passingScoreController.text),
        isTimeLimited: _isTimeLimited,
        timeLimit: _isTimeLimited ? int.parse(_timeLimitController.text) : 0,
        showCorrectAnswers: _showCorrectAnswers,
        isTest: widget.isTest,
        requiresApproval: _requiresApproval,
      );

      if (quizId == null) {
        throw Exception('Failed to create quiz');
      }

      // Show success message and navigate back
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isTest
                ? 'Test created successfully'
                : 'Quiz created successfully',
          ),
          backgroundColor: Colors.green,
        ),
      );

      // Return to previous screen
      Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        _errorMessage = 'Error creating ${widget.isTest ? 'test' : 'quiz'}: $e';
        _isCreating = false;
      });
    }
  }

  bool _validateQuestion(int index) {
    final question = _questions[index];

    if (question.questionText.isEmpty) {
      _showErrorSnackBar('Question ${index + 1} text is empty');
      return false;
    }

    if (question.questionType == QuestionType.multipleChoice) {
      // Check all options
      for (int i = 0; i < question.options.length; i++) {
        if (question.options[i].isEmpty) {
          _showErrorSnackBar(
            'Option ${i + 1} in Question ${index + 1} is empty',
          );
          return false;
        }
      }
    }

    if (question.correctAnswer.isEmpty) {
      _showErrorSnackBar(
        'Correct answer for Question ${index + 1} is not selected',
      );
      return false;
    }

    if (question.explanation.isEmpty) {
      _showErrorSnackBar('Explanation for Question ${index + 1} is empty');
      return false;
    }

    return true;
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isTest ? 'Create Test' : 'Create Quiz'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Quiz settings header
          Container(
            padding: const EdgeInsets.all(16),
            color:
                widget.isTest
                    ? Colors.purple.withOpacity(0.1)
                    : Colors.orange.withOpacity(0.1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.isTest ? 'Test Settings' : 'Quiz Settings',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.isTest
                      ? 'Create a timed assessment that requires teacher approval'
                      : 'Create a quick knowledge check for students',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),

          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title field
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: widget.isTest ? 'Test Title' : 'Quiz Title',
                      hintText:
                          widget.isTest
                              ? 'Enter test title'
                              : 'Enter quiz title',
                      prefixIcon: const Icon(Icons.title),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a title';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Description field
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      hintText: 'Enter a description',
                      prefixIcon: Icon(Icons.description),
                    ),
                    maxLines: 2,
                  ),

                  const SizedBox(height: 24),

                  // Quiz configuration
                  const Text(
                    'Configuration',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),

                  // Passing score
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _passingScoreController,
                          decoration: const InputDecoration(
                            labelText: 'Passing Score (%)',
                            hintText: 'E.g., 70',
                            prefixIcon: Icon(Icons.percent),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a passing score';
                            }
                            final score = int.tryParse(value);
                            if (score == null || score < 0 || score > 100) {
                              return 'Enter a score between 0-100';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),

                  // Time limit checkbox and field
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Checkbox(
                        value: _isTimeLimited,
                        onChanged: (value) {
                          setState(() {
                            _isTimeLimited = value ?? false;
                          });
                        },
                      ),
                      const Text('Time Limit'),
                      const SizedBox(width: 16),
                      if (_isTimeLimited) ...[
                        Expanded(
                          child: TextFormField(
                            controller: _timeLimitController,
                            decoration: const InputDecoration(
                              labelText: 'Minutes',
                              hintText: 'E.g., 30',
                              prefixIcon: Icon(Icons.timer),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (!_isTimeLimited) return null;

                              if (value == null || value.isEmpty) {
                                return 'Please enter time limit';
                              }
                              final time = int.tryParse(value);
                              if (time == null || time <= 0) {
                                return 'Enter a valid time';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ],
                  ),

                  // Show correct answers checkbox
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Checkbox(
                        value: _showCorrectAnswers,
                        onChanged: (value) {
                          setState(() {
                            _showCorrectAnswers = value ?? true;
                          });
                        },
                      ),
                      const Text('Show correct answers after submission'),
                    ],
                  ),

                  // Requires approval checkbox (for tests only)
                  if (widget.isTest) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Checkbox(
                          value: _requiresApproval,
                          onChanged: (value) {
                            setState(() {
                              _requiresApproval = value ?? true;
                            });
                          },
                        ),
                        const Text('Requires teacher approval'),
                      ],
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Questions section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Questions',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _addQuestion,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Question'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Question list
                  ...List.generate(_questions.length, (index) {
                    return _buildQuestionEditor(index);
                  }),

                  // Error message
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red[300]!, width: 1),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red[800]),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isCreating ? null : _createQuiz,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor:
                            widget.isTest ? Colors.purple : AppColors.primary,
                      ),
                      child:
                          _isCreating
                              ? const CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              )
                              : Text(
                                'Create ${widget.isTest ? 'Test' : 'Quiz'}',
                              ),
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionEditor(int index) {
    final question = _questions[index];
    final TextEditingController questionTextController = TextEditingController(
      text: question.questionText,
    );
    final TextEditingController explanationController = TextEditingController(
      text: question.explanation,
    );

    // Controllers for options
    final List<TextEditingController> optionControllers = [];
    for (int i = 0; i < question.options.length; i++) {
      optionControllers.add(TextEditingController(text: question.options[i]));
    }

    // Selected option for correct answer
    String selectedOption = question.correctAnswer;

    return Card(
      margin: const EdgeInsets.only(bottom: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question header with number and remove button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Question ${index + 1}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _removeQuestion(index),
                  tooltip: 'Remove question',
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Question text
            TextField(
              controller: questionTextController,
              decoration: const InputDecoration(
                labelText: 'Question Text',
                hintText: 'Enter your question here',
              ),
              maxLines: 2,
              onChanged: (value) {
                _updateQuestion(index, question.copyWith(questionText: value));
              },
            ),

            const SizedBox(height: 16),

            // Question type selector
            DropdownButtonFormField<QuestionType>(
              value: question.questionType,
              decoration: const InputDecoration(labelText: 'Question Type'),
              items: const [
                DropdownMenuItem(
                  value: QuestionType.multipleChoice,
                  child: Text('Multiple Choice'),
                ),
                DropdownMenuItem(
                  value: QuestionType.trueFalse,
                  child: Text('True/False'),
                ),
                DropdownMenuItem(
                  value: QuestionType.shortAnswer,
                  child: Text('Short Answer'),
                ),
              ],
              onChanged: (value) {
                if (value == null) return;

                // Update options based on question type
                List<String> newOptions = [];
                String newCorrectAnswer = '';

                if (value == QuestionType.multipleChoice) {
                  newOptions = ['', '', '', ''];
                  newCorrectAnswer = '';
                } else if (value == QuestionType.trueFalse) {
                  newOptions = ['True', 'False'];
                  newCorrectAnswer = '';
                } else {
                  newOptions = [];
                  newCorrectAnswer = '';
                }

                _updateQuestion(
                  index,
                  question.copyWith(
                    questionType: value,
                    options: newOptions,
                    correctAnswer: newCorrectAnswer,
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // Options based on question type
            if (question.questionType == QuestionType.multipleChoice) ...[
              const Text(
                'Answer Options',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              // Multiple choice options
              ...List.generate(question.options.length, (i) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Radio<String>(
                        value: question.options[i],
                        groupValue: selectedOption,
                        onChanged: (value) {
                          setState(() {
                            selectedOption = value ?? '';
                            _updateQuestion(
                              index,
                              question.copyWith(correctAnswer: value ?? ''),
                            );
                          });
                        },
                      ),
                      Expanded(
                        child: TextField(
                          controller: optionControllers[i],
                          decoration: InputDecoration(
                            labelText: 'Option ${i + 1}',
                            hintText: 'Enter option ${i + 1}',
                          ),
                          onChanged: (value) {
                            final newOptions = List<String>.from(
                              question.options,
                            );
                            newOptions[i] = value;

                            // Update the correct answer if it's the same as the changed option
                            String newCorrectAnswer = question.correctAnswer;
                            if (question.correctAnswer == question.options[i]) {
                              newCorrectAnswer = value;
                              selectedOption = value;
                            }

                            _updateQuestion(
                              index,
                              question.copyWith(
                                options: newOptions,
                                correctAnswer: newCorrectAnswer,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              }),

              // Add option button
              if (question.options.length < 6)
                TextButton.icon(
                  onPressed: () {
                    final newOptions = List<String>.from(question.options)
                      ..add('');
                    _updateQuestion(
                      index,
                      question.copyWith(options: newOptions),
                    );

                    // Add a controller for the new option
                    optionControllers.add(TextEditingController());
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Option'),
                ),
            ] else if (question.questionType == QuestionType.trueFalse) ...[
              // True/False options
              const Text(
                'Answer Options',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  Radio<String>(
                    value: 'True',
                    groupValue: selectedOption,
                    onChanged: (value) {
                      setState(() {
                        selectedOption = value ?? '';
                        _updateQuestion(
                          index,
                          question.copyWith(correctAnswer: value ?? ''),
                        );
                      });
                    },
                  ),
                  const Text('True'),
                  const SizedBox(width: 24),
                  Radio<String>(
                    value: 'False',
                    groupValue: selectedOption,
                    onChanged: (value) {
                      setState(() {
                        selectedOption = value ?? '';
                        _updateQuestion(
                          index,
                          question.copyWith(correctAnswer: value ?? ''),
                        );
                      });
                    },
                  ),
                  const Text('False'),
                ],
              ),
            ] else if (question.questionType == QuestionType.shortAnswer) ...[
              // Short answer
              const Text(
                'Correct Answer',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              TextField(
                decoration: const InputDecoration(
                  labelText: 'Correct Answer',
                  hintText: 'Enter the correct answer',
                ),
                onChanged: (value) {
                  _updateQuestion(
                    index,
                    question.copyWith(correctAnswer: value),
                  );
                },
              ),

              const SizedBox(height: 8),
              const Text(
                'Note: Student answers will be case-insensitive for matching',
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Explanation
            const Text(
              'Explanation',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            TextField(
              controller: explanationController,
              decoration: const InputDecoration(
                labelText: 'Explanation',
                hintText: 'Explain why the correct answer is right',
              ),
              maxLines: 3,
              onChanged: (value) {
                _updateQuestion(index, question.copyWith(explanation: value));
              },
            ),

            const SizedBox(height: 16),

            // Points
            Row(
              children: [
                const Text(
                  'Points:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 16),
                DropdownButton<int>(
                  value: question.points,
                  items:
                      [1, 2, 3, 4, 5].map((points) {
                        return DropdownMenuItem<int>(
                          value: points,
                          child: Text(points.toString()),
                        );
                      }).toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    _updateQuestion(index, question.copyWith(points: value));
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Extension to allow copying a Question with updated fields
extension QuestionCopy on Question {
  Question copyWith({
    String? id,
    String? questionText,
    QuestionType? questionType,
    List<String>? options,
    String? correctAnswer,
    String? explanation,
    int? points,
  }) {
    return Question(
      id: id ?? this.id,
      questionText: questionText ?? this.questionText,
      questionType: questionType ?? this.questionType,
      options: options ?? this.options,
      correctAnswer: correctAnswer ?? this.correctAnswer,
      explanation: explanation ?? this.explanation,
      points: points ?? this.points,
    );
  }
}
