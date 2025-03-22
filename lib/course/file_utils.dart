import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';

class FileUtils {
  /// Download a file from a URL and save it to the temp directory
  static Future<File?> downloadFile(
    String url, {
    String? customFileName,
    Function(double)? onProgress,
  }) async {
    try {
      // Create a temp file path
      final tempDir = await getTemporaryDirectory();
      final fileName = customFileName ?? path.basename(url);
      final filePath = path.join(tempDir.path, fileName);

      // Check if file already exists
      final file = File(filePath);
      if (await file.exists()) {
        return file;
      }

      // Create the file
      final request = http.Request('GET', Uri.parse(url));
      final response = await http.Client().send(request);

      final contentLength = response.contentLength ?? 0;
      int bytesReceived = 0;

      final bytes = <int>[];

      // Stream the response to keep track of progress
      await for (final chunk in response.stream) {
        bytes.addAll(chunk);
        bytesReceived += chunk.length;

        if (contentLength > 0 && onProgress != null) {
          onProgress(bytesReceived / contentLength);
        }
      }

      // Write the file
      await file.writeAsBytes(bytes);

      return file;
    } catch (e) {
      print('Error downloading file: $e');
      return null;
    }
  }

  /// Save a file to the downloads directory
  static Future<File?> saveToDownloads(
    File file, {
    String? customFileName,
  }) async {
    try {
      // Request storage permission
      if (!await _requestStoragePermission()) {
        throw Exception('Storage permission denied');
      }

      // Get the downloads directory
      Directory? downloadsDir;

      if (Platform.isAndroid) {
        downloadsDir = Directory('/storage/emulated/0/Download');
      } else if (Platform.isIOS) {
        downloadsDir = await getApplicationDocumentsDirectory();
      } else {
        throw Exception('Unsupported platform');
      }

      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }

      // Create the file path
      final fileName = customFileName ?? path.basename(file.path);
      final filePath = path.join(downloadsDir.path, fileName);

      // Copy the file
      final savedFile = await file.copy(filePath);

      return savedFile;
    } catch (e) {
      print('Error saving file to downloads: $e');
      return null;
    }
  }

  /// Open a file with the default app
  static Future<OpenResult> openFile(File file) async {
    try {
      return await OpenFile.open(file.path);
    } catch (e) {
      print('Error opening file: $e');
      return OpenResult(type: ResultType.error, message: e.toString());
    }
  }

  /// Get a readable file size string (e.g. "1.2 MB")
  static String getFileSizeString(int bytes) {
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];

    if (bytes == 0) {
      return '0 B';
    }

    final i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(1)} ${suffixes[i]}';
  }

  /// Get file type from extension
  static String getFileType(String filePath) {
    final extension = path.extension(filePath).toLowerCase();

    switch (extension) {
      case '.jpg':
      case '.jpeg':
      case '.png':
      case '.gif':
      case '.webp':
        return 'image';

      case '.mp4':
      case '.avi':
      case '.mov':
      case '.wmv':
      case '.flv':
      case '.mkv':
      case '.webm':
        return 'video';

      case '.mp3':
      case '.wav':
      case '.ogg':
      case '.aac':
      case '.flac':
        return 'audio';

      case '.pdf':
        return 'pdf';

      case '.doc':
      case '.docx':
        return 'word';

      case '.xls':
      case '.xlsx':
        return 'excel';

      case '.ppt':
      case '.pptx':
        return 'powerpoint';

      case '.txt':
      case '.rtf':
        return 'text';

      case '.zip':
      case '.rar':
      case '.7z':
      case '.tar':
      case '.gz':
        return 'archive';

      default:
        return 'other';
    }
  }

  /// Get file icon based on file type
  static IconData getFileIcon(String filePath) {
    final fileType = getFileType(filePath);

    switch (fileType) {
      case 'image':
        return Icons.image;
      case 'video':
        return Icons.video_file;
      case 'audio':
        return Icons.audio_file;
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'word':
        return Icons.description;
      case 'excel':
        return Icons.table_chart;
      case 'powerpoint':
        return Icons.slideshow;
      case 'text':
        return Icons.article;
      case 'archive':
        return Icons.folder_zip;
      default:
        return Icons.insert_drive_file;
    }
  }

  /// Create a File from a ByteData
  static Future<File> createFileFromByteData(
    ByteData data,
    String fileName,
  ) async {
    final buffer = data.buffer;
    final tempDir = await getTemporaryDirectory();
    final filePath = path.join(tempDir.path, fileName);
    final file = File(filePath);

    return await file.writeAsBytes(
      buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    );
  }

  /// Get MIME type from file extension
  static String getMimeType(String filePath) {
    final extension = path.extension(filePath).toLowerCase();

    switch (extension) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.webp':
        return 'image/webp';

      case '.mp4':
        return 'video/mp4';
      case '.avi':
        return 'video/x-msvideo';
      case '.mov':
        return 'video/quicktime';
      case '.wmv':
        return 'video/x-ms-wmv';
      case '.flv':
        return 'video/x-flv';
      case '.mkv':
        return 'video/x-matroska';
      case '.webm':
        return 'video/webm';

      case '.mp3':
        return 'audio/mpeg';
      case '.wav':
        return 'audio/wav';
      case '.ogg':
        return 'audio/ogg';
      case '.aac':
        return 'audio/aac';
      case '.flac':
        return 'audio/flac';

      case '.pdf':
        return 'application/pdf';

      case '.doc':
        return 'application/msword';
      case '.docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';

      case '.xls':
        return 'application/vnd.ms-excel';
      case '.xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

      case '.ppt':
        return 'application/vnd.ms-powerpoint';
      case '.pptx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';

      case '.txt':
        return 'text/plain';
      case '.rtf':
        return 'application/rtf';

      case '.zip':
        return 'application/zip';
      case '.rar':
        return 'application/x-rar-compressed';
      case '.7z':
        return 'application/x-7z-compressed';
      case '.tar':
        return 'application/x-tar';
      case '.gz':
        return 'application/gzip';

      default:
        return 'application/octet-stream';
    }
  }

  /// Get a temporary file path with extension
  static Future<String> getTempFilePath(String extension) async {
    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return path.join(tempDir.path, 'temp_$timestamp$extension');
  }

  /// Request storage permission
  static Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.storage.request();
      return status.isGranted;
    } else if (Platform.isIOS) {
      return true; // iOS doesn't need explicit permission for app documents directory
    }
    return false;
  }

  /// Helper function for log and pow used in file size calculation
  static double log(num x) => log10(x) / log10(1024);
  static double pow(num x, num exponent) => x.toDouble() * exponent.toDouble();
  static double log10(num x) => log_e(x) / log_e(10);
  static double log_e(num x) => x.toDouble().toDouble();
}

/// Extensions for convenience
extension FileExtension on File {
  /// Get the file size in bytes
  Future<int> get sizeInBytes async {
    return await length();
  }

  /// Get the file size as a readable string
  Future<String> get readableSize async {
    final size = await sizeInBytes;
    return FileUtils.getFileSizeString(size);
  }

  // /// Get the file type
  // String get fileType {
  //   return FileUtils.getFileType(path);
  // }

  // /// Get the file icon
  // IconData get fileIcon {
  //   return FileUtils.getFileIcon(path);
  // }

  // /// Get the MIME type
  // String get mimeType {
  //   return FileUtils.getMimeType(path);
  // }

  /// Save to downloads directory
  Future<File?> saveToDownloads({String? customFileName}) {
    return FileUtils.saveToDownloads(this, customFileName: customFileName);
  }

  /// Open with default app
  Future<OpenResult> open() {
    return FileUtils.openFile(this);
  }
}
