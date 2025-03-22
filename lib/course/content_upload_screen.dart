import 'dart:io';
import 'package:flutter/material.dart';
import '../constants/colors.dart';
import 'course_mode.dart';
import 'lms_service.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;

class ContentUploadScreen extends StatefulWidget {
  final Course course;
  final ContentType contentType;

  const ContentUploadScreen({
    Key? key,
    required this.course,
    required this.contentType,
  }) : super(key: key);

  @override
  State<ContentUploadScreen> createState() => _ContentUploadScreenState();
}

class _ContentUploadScreenState extends State<ContentUploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  File? _selectedFile;
  String? _fileName;
  bool _isUploading = false;
  double _uploadProgress = 0;
  String? _errorMessage;

  // For content order
  int _orderIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadContentCount();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadContentCount() async {
    try {
      final lmsService = Provider.of<LMSService>(context, listen: false);
      final contentList = await lmsService.getCourseContent(widget.course.id);
      setState(() {
        _orderIndex =
            contentList.length; // Set order index to the end of the list
      });
    } catch (e) {
      // Use a default order index if we can't load the content count
      setState(() {
        _orderIndex = 0;
      });
    }
  }

  Future<void> _pickFile() async {
    // FilePickerResult? result;

    // try {
    //   switch (widget.contentType) {
    //     case ContentType.video:
    //       // Pick video file
    //       result = await FilePicker.platform.pickFiles(
    //         type: FileType.video,
    //         allowMultiple: false,
    //       );
    //       break;
    //     case ContentType.pdf:
    //       // Pick PDF file
    //       result = await FilePicker.platform.pickFiles(
    //         type: FileType.custom,
    //         allowedExtensions: ['pdf'],
    //         allowMultiple: false,
    //       );
    //       break;
    //     case ContentType.document:
    //       // Pick document file (DOC, DOCX, TXT)
    //       result = await FilePicker.platform.pickFiles(
    //         type: FileType.custom,
    //         allowedExtensions: ['doc', 'docx', 'txt'],
    //         allowMultiple: false,
    //       );
    //       break;
    //     default:
    //       // Default to any file
    //       result = await FilePicker.platform.pickFiles(
    //         allowMultiple: false,
    //       );
    //   }

    //   if (result != null && result.files.isNotEmpty) {
    //     setState(() {
    //       _selectedFile = File(result!.files.first.path!);
    //       _fileName = result.files.first.name;
    //       _errorMessage = null;

    //       // Set title if empty
    //       if (_titleController.text.isEmpty) {
    //         _titleController.text = path.basenameWithoutExtension(_fileName!);
    //       }
    //     });
    //   }
    // } catch (e) {
    //   setState(() {
    //     _errorMessage = 'Error picking file: $e';
    //   });
    // }
  }

  Future<void> _uploadContent() async {
    // if (!_formKey.currentState!.validate()) {
    //   return;
    // }

    // if (_selectedFile == null) {
    //   setState(() {
    //     _errorMessage = 'Please select a file to upload';
    //   });
    //   return;
    // }

    // setState(() {
    //   _isUploading = true;
    //   _uploadProgress = 0;
    //   _errorMessage = null;
    // });

    // try {
    //   final lmsService = Provider.of<LMSService>(context, listen: false);

    //   // First upload the file to AWS S3
    //   final fileUrl = await lmsService.uploadContentFile(
    //     _selectedFile!,
    //     widget.contentType,
    //   );

    //   if (fileUrl == null) {
    //     throw Exception('Failed to upload file');
    //   }

    //   // Update progress
    //   setState(() {
    //     _uploadProgress = 0.7; // 70% progress after file upload
    //   });

    //   // Create content record in Firestore
    //   final contentId = await lmsService.createContent(
    //     title: _titleController.text.trim(),
    //     description: _descriptionController.text.trim(),
    //     contentType: widget.contentType,
    //     courseId: widget.course.id,
    //     fileUrl: fileUrl,
    //     orderIndex: _orderIndex,
    //     assignedStudentIds:
    //         widget
    //             .course
    //             .assignedStudentIds, // Assign to all course students by default
    //   );

    //   if (contentId == null) {
    //     throw Exception('Failed to create content record');
    //   }

    //   // Complete progress
    //   setState(() {
    //     _uploadProgress = 1.0;
    //     _isUploading = false;
    //   });

    //   // Show success message and navigate back
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(
    //       content: Text('Content uploaded successfully'),
    //       backgroundColor: Colors.green,
    //     ),
    //   );

    //   // Return to previous screen
    //   Navigator.pop(context, true);
    // } catch (e) {
    //   setState(() {
    //     _errorMessage = 'Error uploading content: $e';
    //     _isUploading = false;
    //   });
    // }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Upload ${_getContentTypeName()}')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title field
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'Enter a title for this content',
                prefixIcon: Icon(Icons.title),
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
                hintText: 'Enter a description for this content',
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
            ),

            const SizedBox(height: 24),

            // File selection section
            Text(
              'Select ${_getContentTypeName()} File',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 16),

            // File picker button
            InkWell(
              onTap: _isUploading ? null : _pickFile,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!, width: 1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Icon(
                      _getContentTypeIcon(),
                      size: 48,
                      color: _getContentTypeColor(),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _selectedFile != null
                          ? 'Selected file: $_fileName'
                          : 'Click to select a file',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color:
                            _selectedFile != null
                                ? Colors.black
                                : Colors.grey[600],
                      ),
                    ),
                    if (_selectedFile != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        '${(_selectedFile!.lengthSync() / 1024 / 1024).toStringAsFixed(2)} MB',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // File requirements note
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 8),
              child: Text(
                _getFileRequirementsText(),
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),

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

            // Upload progress
            if (_isUploading) ...[
              LinearProgressIndicator(
                value: _uploadProgress,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
              const SizedBox(height: 8),
              Text(
                'Uploading... ${(_uploadProgress * 100).toInt()}%',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
            ],

            // Upload button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isUploading ? null : _uploadContent,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child:
                    _isUploading
                        ? const Text('Uploading...')
                        : Text('Upload ${_getContentTypeName()}'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getContentTypeName() {
    // switch (widget.contentType) {
    //   case ContentType.video:
    //     return 'Video';
    //   case ContentType.document:
    //     return 'Document';
    //   case ContentType.pdf:
    //     return 'PDF';
    //   case ContentType.quiz:
    //     return 'Quiz';
    //   case ContentType.test:
    //     return 'Test';
    // }
    //here
    return 'Test';
  }

  IconData _getContentTypeIcon() {
    // switch (widget.contentType) {
    //   case ContentType.video:
    //     return Icons.video_library;
    //   case ContentType.document:
    //     return Icons.description;
    //   case ContentType.pdf:
    //     return Icons.picture_as_pdf;
    //   case ContentType.quiz:
    //     return Icons.quiz;
    //   case ContentType.test:
    //     return Icons.assignment;
    // }
    return Icons.assignment;
  }

  Color _getContentTypeColor() {
    // switch (widget.contentType) {
    //   case ContentType.video:
    //     return Colors.red;
    //   case ContentType.document:
    //     return Colors.blue;
    //   case ContentType.pdf:
    //     return Colors.red;
    //   case ContentType.quiz:
    //     return Colors.orange;
    //   case ContentType.test:
    //     return Colors.purple;
    // }
    return Colors.purple;
  }

  String _getFileRequirementsText() {
    // switch (widget.contentType) {
    //   case ContentType.video:
    //     return 'Supported formats: MP4, MOV, AVI. Maximum size: 500MB.';
    //   case ContentType.document:
    //     return 'Supported formats: DOC, DOCX, TXT. Maximum size: 50MB.';
    //   case ContentType.pdf:
    //     return 'Supported format: PDF. Maximum size: 100MB.';
    //   default:
    //     return 'Select a file to upload.';
    // }
    return 'Supported format: PDF. Maximum size: 100MB.';
  }
}
