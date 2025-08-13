import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../controller/youtube_player_controller.dart';
import '../player_params.dart';
import 'youtube_player.dart';

/// A widget that plays Youtube Video is full screen mode.
///
/// See also:
///
///  * [YoutubePlayer], which play or stream Youtube Videos in normal mode.
class FullscreenYoutubePlayer extends StatefulWidget {
  /// Creates an instance of [FullscreenYoutubePlayer].
  const FullscreenYoutubePlayer({
    super.key,
    required this.videoId,
    this.startSeconds,
    this.endSeconds,
    this.backgroundColor,
    this.aspectRatio,
  });

  /// The YouTube Video ID.
  final String videoId;

  /// The time in seconds when the video should start from.
  final double? startSeconds;

  /// The time in seconds when the video should end at.
  final double? endSeconds;

  /// The background color of the [WebView].
  ///
  /// Default to [ColorScheme.surface].
  final Color? backgroundColor;

  /// The aspect ratio of the player.
  final double? aspectRatio;

  @override
  State<FullscreenYoutubePlayer> createState() {
    return _FullscreenYoutubePlayerState();
  }

  /// Launches the [FullscreenYoutubePlayer].
  ///
  /// Returns the time in seconds at which the player was popped.
  static Future<double?> launch(
    BuildContext context, {
    required String videoId,
    double? startSeconds,
    double? endSeconds,
    Set<Factory<OneSequenceGestureRecognizer>> gestureRecognizers =
        const <Factory<OneSequenceGestureRecognizer>>{},
    Color? backgroundColor,
    double? aspectRatio,
  }) {
    return Navigator.push<double>(
      context,
      MaterialPageRoute(
        builder: (context) {
          return FullscreenYoutubePlayer(
            videoId: videoId,
            startSeconds: startSeconds,
            endSeconds: endSeconds,
            backgroundColor: backgroundColor,
            aspectRatio: aspectRatio,
          );
        },
      ),
    );
  }
}

class _FullscreenYoutubePlayerState extends State<FullscreenYoutubePlayer> {
  late final YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    final aspectRatio = widget.aspectRatio ?? 16 / 9;

    _controller = YoutubePlayerController.fromVideoId(
      videoId: widget.videoId,
      startSeconds: widget.startSeconds,
      autoPlay: true,
      params: const YoutubePlayerParams(showFullscreenButton: true),
    )..setFullScreenListener((_) async {
        final currentTime = await _controller.currentTime;
        if (!mounted) return;

        Navigator.pop(context, currentTime);
      });

    if (aspectRatio > 1) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _controller.currentTime.then(
          (time) {
            if (context.mounted) return Navigator.pop(context, time);
          },
        );
      },
      child: YoutubePlayer(
        controller: _controller,
        aspectRatio: MediaQuery.of(context).size.aspectRatio,
        backgroundColor: widget.backgroundColor,
      ),
    );
  }

  @override
  void dispose() {
    _resetOrientation();
    _controller.close();
    super.dispose();
  }

  void _resetOrientation() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }
}
