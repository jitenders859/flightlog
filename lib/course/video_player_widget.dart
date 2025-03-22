import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  final bool autoPlay;
  final bool looping;
  final bool allowFullScreen;
  final bool showControls;
  final double aspectRatio;
  final Widget? placeholder;
  final Function? onFinish;

  const VideoPlayerWidget({
    Key? key,
    required this.videoUrl,
    this.autoPlay = false,
    this.looping = false,
    this.allowFullScreen = true,
    this.showControls = true,
    this.aspectRatio = 16 / 9,
    this.placeholder,
    this.onFinish,
  }) : super(key: key);

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  bool _isInitialized = false;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      _videoPlayerController = VideoPlayerController.network(widget.videoUrl);

      await _videoPlayerController.initialize();

      // Add listener for video completion
      _videoPlayerController.addListener(_videoListener);

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController,
        autoPlay: widget.autoPlay,
        looping: widget.looping,
        allowFullScreen: widget.allowFullScreen,
        showControls: widget.showControls,
        aspectRatio: widget.aspectRatio,
        placeholder: widget.placeholder,
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Error: $errorMessage',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          );
        },
      );

      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  void _videoListener() {
    // Check if video is finished
    if (_videoPlayerController.value.position >=
        _videoPlayerController.value.duration) {
      if (widget.onFinish != null && !widget.looping) {
        widget.onFinish!();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _initializePlayer,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Chewie(controller: _chewieController!);
  }

  @override
  void dispose() {
    _videoPlayerController.removeListener(_videoListener);
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }
}
// (height: 16),
//               Text(
//                 'Error loading video',
//                 style: Theme.of(context).textTheme.titleLarge?.copyWith(
//                   color: Colors.red,
//                 ),
//               ),
//               const SizedBox(height: 8),
//               Text(
//                 _errorMessage ?? 'Unknown error',
//                 textAlign: TextAlign.center,
//               ),
//               const SizedBox