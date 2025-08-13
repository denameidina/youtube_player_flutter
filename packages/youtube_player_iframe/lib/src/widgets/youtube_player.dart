// Copyright 2022 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:youtube_player_iframe/src/widgets/custom_youtube_player_controls.dart';
import 'package:youtube_player_iframe/src/widgets/fullscreen_youtube_player.dart';

import '../controller/youtube_player_controller.dart';

/// A widget to play or stream Youtube Videos.
///
/// See also:
///
///  * [FullscreenYoutubePlayer], which play or stream Youtube Videos in fullscreen mode.
class YoutubePlayer extends StatefulWidget {
  /// A widget to play or stream Youtube Videos.
  const YoutubePlayer({
    super.key,
    required this.controller,
    this.aspectRatio = 16 / 9,
    this.backgroundColor,
    this.keepAlive = false,
  });

  /// The [controller] for this player.
  final YoutubePlayerController controller;

  /// Aspect ratio for the player.
  final double aspectRatio;

  /// The background color of the [WebView].
  ///
  /// Default to [ColorScheme.surface].
  final Color? backgroundColor;

  /// Whether to keep the state of the player alive when it is not visible.
  final bool keepAlive;

  @override
  State<YoutubePlayer> createState() => _YoutubePlayerState();
}

class _YoutubePlayerState extends State<YoutubePlayer>
    with AutomaticKeepAliveClientMixin {
  late final YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller;

    _initPlayer();
  }

  @override
  void didUpdateWidget(YoutubePlayer oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.backgroundColor != oldWidget.backgroundColor) {
      _updateBackgroundColor(widget.backgroundColor);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Material(
      child: OrientationBuilder(
        builder: (context, orientation) {
          return AspectRatio(
            aspectRatio: orientation == Orientation.landscape
                ? MediaQuery.of(context).size.aspectRatio
                : widget.aspectRatio,
            child: Stack(
              children: [
                AbsorbPointer(
                  absorbing: true,
                  child: WebViewWidget(
                    controller: _controller.webViewController,
                  ),
                ),
                if (_controller.params.customControlParams != null)
                  CustomYoutubePlayerControls(
                    controller: _controller,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _updateBackgroundColor(Color? backgroundColor) {
    if (defaultTargetPlatform == TargetPlatform.macOS) return;
    final bgColor = backgroundColor ?? Theme.of(context).colorScheme.surface;
    _controller.webViewController.setBackgroundColor(bgColor);
  }

  Future<void> _initPlayer() async {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _updateBackgroundColor(widget.backgroundColor);
    });

    await _controller.init();
  }

  @override
  bool get wantKeepAlive => widget.keepAlive;
}
