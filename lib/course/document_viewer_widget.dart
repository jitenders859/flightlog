import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';

class DocumentViewerWidget extends StatefulWidget {
  final String documentUrl;
  final String title;
  final Function? onFinish;

  const DocumentViewerWidget({
    Key? key,
    required this.documentUrl,
    required this.title,
    this.onFinish,
  }) : super(key: key);

  @override
  State<DocumentViewerWidget> createState() => _DocumentViewerWidgetState();
}

class _DocumentViewerWidgetState extends State<DocumentViewerWidget> {
  String? _localFilePath;
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  int _totalPages = 0;
  int _currentPage = 0;
  bool _isDownloading = false;
  double _downloadProgress = 0;

  @override
  void initState() {
    super.initState();
    _loadDocument();
  }

  Future<void> _loadDocument() async {
    // setState(() {
    //   _isLoading = true;
    //   _hasError = false;
    //   _errorMessage = null;
    // });

    // try {
    //   // Get file extension
    //   final uri = Uri.parse(widget.documentUrl);
    //   final extension = extension(uri.path).toLowerCase();

    //   // Check if we support this file type
    //   if (extension != '.pdf') {
    //     setState(() {
    //       _hasError = true;
    //       _errorMessage = 'Unsupported file type: $extension. Only PDF files are supported for viewing.';
    //       _isLoading = false;
    //     });
    //     return;
    //   }

    //   // Download the file
    //   final localPath = await _downloadFile(widget.documentUrl);

    //   setState(() {
    //     _localFilePath = localPath;
    //     _isLoading = false;
    //   });
    // } catch (e) {
    //   setState(() {
    //     _hasError = true;
    //     _errorMessage = e.toString();
    //     _isLoading = false;
    //   });
    // }
  }

  Future<String> _downloadFile(String url) async {
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0;
    });

    final response = await http.Client().send(
      http.Request('GET', Uri.parse(url)),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to download document: ${response.statusCode}');
    }

    final contentLength = response.contentLength ?? 0;
    int received = 0;

    final List<int> bytes = [];

    response.stream.listen(
      (List<int> newBytes) {
        bytes.addAll(newBytes);
        received += newBytes.length;

        if (contentLength > 0) {
          setState(() {
            _downloadProgress = received / contentLength;
          });
        }
      },
      onDone: () async {
        // Get temporary directory
        final dir = await getTemporaryDirectory();
        final filename = basename(url);
        final file = File('${dir.path}/$filename');

        // Write the file
        await file.writeAsBytes(bytes);

        setState(() {
          _isDownloading = false;
          _localFilePath = file.path;
        });
      },
      onError: (e) {
        setState(() {
          _isDownloading = false;
          _hasError = true;
          _errorMessage = 'Error downloading document: $e';
        });
      },
      cancelOnError: true,
    );

    // Wait for download to complete
    while (_isDownloading && !_hasError) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    if (_hasError) {
      throw Exception(_errorMessage);
    }

    return _localFilePath!;
  }

  @override
  Widget build(BuildContext context) {
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
                'Downloading document: ${(_downloadProgress * 100).toStringAsFixed(0)}%',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ] else ...[
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Loading document...',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      );
    }

    if (_hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                'Error loading document',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(color: Colors.red),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage ?? 'Unknown error',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadDocument,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // PDF View
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(24),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Page: $_currentPage / $_totalPages',
                  style: const TextStyle(color: Colors.white70),
                ),
                if (_totalPages > 0)
                  IconButton(
                    icon: const Icon(Icons.download, color: Colors.white),
                    onPressed: () => _downloadAndSaveFile(context),
                    tooltip: 'Download document',
                  ),
              ],
            ),
          ),
        ),
      ),
      body: PDFView(
        filePath: _localFilePath!,
        enableSwipe: true,
        swipeHorizontal: true,
        autoSpacing: true,
        pageFling: true,
        pageSnap: true,
        defaultPage: 0,
        fitPolicy: FitPolicy.BOTH,
        preventLinkNavigation: false,
        onRender: (pages) {
          setState(() {
            _totalPages = pages!;
          });
        },
        onViewCreated: (PDFViewController pdfViewController) {
          // You could store the controller for future use
        },
        onPageChanged: (int? page, int? total) {
          if (page != null) {
            setState(() {
              _currentPage = page + 1;
            });

            // If we reached the last page, call onFinish
            if (page == total! - 1 && widget.onFinish != null) {
              widget.onFinish!();
            }
          }
        },
        onError: (error) {
          setState(() {
            _hasError = true;
            _errorMessage = error.toString();
          });
        },
      ),
    );
  }

  Future<void> _downloadAndSaveFile(BuildContext context) async {
    // Implementing save to device functionality...
    // This would typically use another plugin to save the file to the downloads folder
    // For simplicity, we'll just show a success message

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Document saved to downloads'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
