import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:amazon_cognito_identity_dart_2/cognito.dart';
import 'package:amazon_cognito_identity_dart_2/sig_v4.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

class AWSService {
  // AWS Credentials
  static const String _userPoolId = 'YOUR_USER_POOL_ID';
  static const String _clientId = 'YOUR_CLIENT_ID';
  static const String _identityPoolId = 'YOUR_IDENTITY_POOL_ID';
  static const String _region = 'YOUR_REGION'; // e.g., 'us-east-1'
  static const String _s3Bucket = 'YOUR_S3_BUCKET';

  final userPool = CognitoUserPool(_userPoolId, _clientId);

  // S3 configuration
  final String s3Endpoint = 'https://$_s3Bucket.s3.$_region.amazonaws.com';

  // Singleton pattern
  static final AWSService _instance = AWSService._internal();
  factory AWSService() => _instance;
  AWSService._internal();

  String? _awsUserAccessKey;
  String? _awsSecretKey;
  String? _sessionToken;

  bool get isInitialized => _awsUserAccessKey != null && _awsSecretKey != null;

  Future<bool> initialize() async {
    if (isInitialized) return true;

    try {
      // TODO: Implement proper AWS credential fetching using Cognito
      // This is a placeholder for actual AWS authentication
      _awsUserAccessKey = 'YOUR_ACCESS_KEY';
      _awsSecretKey = 'YOUR_SECRET_KEY';
      _sessionToken = null;

      return true;
    } catch (e) {
      print('Error initializing AWS Service: $e');
      return false;
    }
  }

  Future<String?> uploadFile({
    required File file,
    required String folder,
    String? customFilename,
  }) async {
    // if (!isInitialized) {
    //   bool initialized = await initialize();
    //   if (!initialized) return null;
    // }

    // try {
    //   final String filename = customFilename ?? path.basename(file.path);
    //   final String key = '$folder/$filename';

    //   final AwsSigV4Client client = AwsSigV4Client(
    //     _awsUserAccessKey!,
    //     _awsSecretKey!,
    //     s3Endpoint,
    //     region: _region,
    //     sessionToken: _sessionToken,
    //   );

    //   final fileBytes = await file.readAsBytes();
    //   final contentType = _getContentType(filename);

    //   final SigV4Request request = SigV4Request(
    //     client,
    //     method: 'PUT',
    //     path: '/$key',
    //     headers: {
    //       'Content-Type': contentType,
    //       'Content-Length': fileBytes.length.toString(),
    //     },
    //     body: fileBytes,
    //   );

    //   final signedRequest = request.sign();

    //   final http.Response response = await http.put(
    //     Uri.parse(signedRequest.url),
    //     headers: signedRequest.headers,
    //     body: fileBytes,
    //   );

    //   if (response.statusCode == 200) {
    //     return '$s3Endpoint/$key';
    //   } else {
    //     print('S3 upload error: ${response.statusCode} - ${response.body}');
    //     return null;
    //   }
    // } catch (e) {
    //   print('Error uploading file to S3: $e');
    //   return null;
    // }
  }

  Future<List<String>> listFiles(String folder) async {
    // if (!isInitialized) {
    //   bool initialized = await initialize();
    //   if (!initialized) return [];
    // }

    // try {
    //   final AwsSigV4Client client = AwsSigV4Client(
    //     _awsUserAccessKey!,
    //     _awsSecretKey!,
    //     s3Endpoint,
    //     region: _region,
    //     sessionToken: _sessionToken,
    //   );

    //   final SigV4Request request = SigV4Request(
    //     client,
    //     method: 'GET',
    //     path: '/',
    //     queryParams: {'list-type': '2', 'prefix': folder},
    //   );

    //   final signedRequest = request.sign();

    //   final http.Response response = await http.get(
    //     Uri.parse(signedRequest.url),
    //     headers: signedRequest.headers,
    //   );

    //   if (response.statusCode == 200) {
    //     // Parse XML response to get file keys
    //     // This is a simplified example; you may want to use xml package for proper parsing
    //     final List<String> fileUrls = [];
    //     final matches = RegExp(r'<Key>(.*?)</Key>').allMatches(response.body);
    //     for (final match in matches) {
    //       final key = match.group(1);
    //       if (key != null && key.startsWith(folder)) {
    //         fileUrls.add('$s3Endpoint/$key');
    //       }
    //     }
    //     return fileUrls;
    //   } else {
    //     print('S3 list error: ${response.statusCode} - ${response.body}');
    //     return [];
    //   }
    // } catch (e) {
    //   print('Error listing files from S3: $e');
    //   return [];
    // }

    //here
    return [];
  }

  Future<bool> deleteFile(String fileUrl) async {
    // if (!isInitialized) {
    //   bool initialized = await initialize();
    //   if (!initialized) return false;
    // }

    // try {
    //   // Extract the key from the URL
    //   final uri = Uri.parse(fileUrl);
    //   final key = uri.path.substring(1); // Remove leading slash

    //   final AwsSigV4Client client = AwsSigV4Client(
    //     _awsUserAccessKey!,
    //     _awsSecretKey!,
    //     s3Endpoint,
    //     region: _region,
    //     sessionToken: _sessionToken,
    //   );

    //   final SigV4Request request = SigV4Request(
    //     client,
    //     method: 'DELETE',
    //     path: '/$key',
    //   );

    //   final signedRequest = request.sign();

    //   final http.Response response = await http.delete(
    //     Uri.parse(signedRequest.url),
    //     headers: signedRequest.headers,
    //   );

    //   return response.statusCode == 204 || response.statusCode == 200;
    // } catch (e) {
    //   print('Error deleting file from S3: $e');
    //   return false;
    // }
    //here
    return false;
  }

  String _getContentType(String filename) {
    final ext = path.extension(filename).toLowerCase();
    switch (ext) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.pdf':
        return 'application/pdf';
      case '.doc':
        return 'application/msword';
      case '.docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case '.mp4':
        return 'video/mp4';
      case '.mov':
        return 'video/quicktime';
      case '.mp3':
        return 'audio/mpeg';
      default:
        return 'application/octet-stream';
    }
  }
}
