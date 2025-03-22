import 'dart:io';
import 'package:flutter/material.dart';
import 'package:navlog/course/video_player_widget.dart' show VideoPlayerWidget;
import 'content_model.dart';
import 'document_viewer_widget.dart';
import 'file_utils.dart';
import 'lms_service.dart';
import 'quiz_model.dart';
import 'quiz_screen.dart';
import 'package:provider/provider.dart';

class ContentViewerScreen extends StatefulWidget {
  final Content content;

  const ContentViewerScreen({Key? key, required this.content})
    : super(key: key);

  @override
  State<ContentViewerScreen> createState() => _ContentViewerScreenState();
}

class _ContentViewerScreenState extends State<ContentViewerScreen> {
  bool _isLoading = true;
  bool _isDownloading = false;
  double _downloadProgress = 0;
  String? _errorMessage;
  File? _localFile;

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  Future<void> _loadContent() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (widget.content.contentType == ContentType.quiz ||
          widget.content.contentType == ContentType.test) {
        // Quizzes don't need to download files
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Start downloading the file
      setState(() {
        _isDownloading = true;
        _downloadProgress = 0;
      });

      // Download the file
      final file = await FileUtils.downloadFile(
        widget.content.fileUrl,
        onProgress: (progress) {
          setState(() {
            _downloadProgress = progress;
          });
        },
      );

      if (file == null) {
        throw Exception('Failed to download file');
      }

      setState(() {
        _localFile = file;
        _isDownloading = false;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading content: $e';
        _isDownloading = false;
        _isLoading = false;
      });
    }
  }

  Future<void> _downloadFile() async {
    if (_localFile == null) return;

    setState(() {
      _isDownloading = true;
    });

    try {
      final savedFile = await _localFile!.saveToDownloads();

      setState(() {
        _isDownloading = false;
      });

      if (savedFile != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File saved to downloads'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save file'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isDownloading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving file: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.content.title),
        actions: [
          if (_localFile != null) ...[
            IconButton(
              icon: Icon(_getFileIcon(), color: Colors.white),
              onPressed: _downloadFile,
              tooltip: 'Download',
            ),
          ],
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isDownloading) ...[
              CircularProgressIndicator(
                value: _downloadProgress > 0 ? _downloadProgress : null,
              ),
              const SizedBox(height: 16),
              Text(
                'Downloading content: ${(_downloadProgress * 100).toStringAsFixed(0)}%',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ] else ...[
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text('Loading content...'),
            ],
          ],
        ),
      );
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
                onPressed: _loadContent,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // Display content based on type
    switch (widget.content.contentType) {
      case ContentType.video:
        return VideoPlayerWidget(
          videoUrl: widget.content.fileUrl,
          autoPlay: true,
          showControls: true,
          allowFullScreen: true,
        );

      case ContentType.document:
      case ContentType.pdf:
        if (_localFile == null) {
          return const Center(child: Text('File not available'));
        }

        return DocumentViewerWidget(
          documentUrl: _localFile!.path,
          title: widget.content.title,
        );

      case ContentType.quiz:
      case ContentType.test:
        // Fetch the quiz/test and navigate to quiz screen
        return FutureBuilder<Quiz?>(
          future: Provider.of<LMSService>(
            context,
          ).getQuiz(widget.content.metadata?['quizId'] ?? ''),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError || !snapshot.hasData) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.quiz_outlined,
                      size: 64,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Quiz not found',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'The requested quiz could not be loaded',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Go Back'),
                    ),
                  ],
                ),
              );
            }

            final quiz = snapshot.data!;

            // Navigate to quiz screen
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => QuizScreen(quiz: quiz)),
              );
            });

            return const Center(child: CircularProgressIndicator());
          },
        );
    }
  }

  IconData _getFileIcon() {
    switch (widget.content.contentType) {
      case ContentType.video:
        return Icons.video_library_outlined;
      case ContentType.document:
        return Icons.description_outlined;
      case ContentType.pdf:
        return Icons.picture_as_pdf_outlined;
      case ContentType.quiz:
        return Icons.quiz_outlined;
      case ContentType.test:
        return Icons.assignment_outlined;
    }
  }
}
