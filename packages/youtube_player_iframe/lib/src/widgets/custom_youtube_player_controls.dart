// ignore_for_file: discarded_futures

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

/// A custom widget for displaying controls over the YouTube player.
///
/// This widget listens to the [YoutubePlayerController] and builds UI
/// elements to control playback, such as play/pause, seeking, progress bar,
/// playback speed, and fullscreen toggle.
class CustomYoutubePlayerControls extends StatefulWidget {
  const CustomYoutubePlayerControls({
    super.key,
    required this.controller,
  });

  final YoutubePlayerController controller;

  @override
  State<CustomYoutubePlayerControls> createState() =>
      _CustomYoutubePlayerControlsState();
}

class _CustomYoutubePlayerControlsState
    extends State<CustomYoutubePlayerControls> {
  bool _isControlsVisible = true;
  Timer? _hideControlsTimer;

  // Listens to player state changes to rebuild the UI.
  PlayerState? _seekPlayerState;
  PlayerState? _playerState;
  YoutubeMetaData? _metaData;
  bool _isFullScreen = false;
  double _playbackRate = 1.0;
  ValueNotifier<Duration> valueProgress = ValueNotifier(Duration.zero);
  bool _isMute = false;

  CustomControlParams? get customControlParams =>
      widget.controller.params.customControlParams;

  Duration get duration => _metaData?.duration ?? Duration.zero;

  @override
  void initState() {
    super.initState();
    // Listen to the controller's value stream for state changes.
    widget.controller.listen((value) {
      if (mounted) {
        // Check if any of the relevant properties have changed to avoid unnecessary rebuilds.
        if (_playerState != value.playerState ||
            _metaData != value.metaData ||
            _isFullScreen != value.fullScreenOption.enabled ||
            _playbackRate != value.playbackRate) {
          setState(() {
            _playerState = value.playerState;
            _metaData = value.metaData;
            _isFullScreen = value.fullScreenOption.enabled;
            _playbackRate = value.playbackRate;
          });
        }
      }
    });

    widget.controller.videoStateStream.listen((state) {
      if (mounted) {
        // Update the valueProgress based on the current video state.
        valueProgress.value = state.position;
      }
    });

    _isMute = widget.controller.params.mute;

    _startHideControlsTimer();
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    super.dispose();
  }

  void _toggleControlsVisibility() {
    setState(() {
      _isControlsVisible = !_isControlsVisible;
    });
    _startHideControlsTimer();
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _isControlsVisible = false;
        });
      }
    });
  }

  void _seekTo(Duration value, {bool startHideTimer = true}) {
    valueProgress.value = value;
    widget.controller.seekTo(
      seconds: valueProgress.value.inSeconds.toDouble(),
      allowSeekAhead: true,
    );
    if (startHideTimer) _startHideControlsTimer();
  }

  PopupMenuItem<double> _buildSpeedMenuItem(String text, double rate) {
    return PopupMenuItem(
      value: rate,
      child: Text(text),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleControlsVisibility,
      onDoubleTap: () {
        if (_playerState == PlayerState.playing) {
          widget.controller.pauseVideo();
        } else {
          widget.controller.playVideo();
        }
        _startHideControlsTimer();
      },
      child: AbsorbPointer(
        absorbing: !_isControlsVisible,
        child: AnimatedOpacity(
          opacity: _isControlsVisible ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.black38,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Main controls (play/pause, seek)
                if (_seekPlayerState == null)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Seek Backward Button
                      if (customControlParams?.showSeekButton ?? true)
                        IconButton(
                          icon: const Icon(Icons.replay_10,
                              color: Colors.white, size: 36),
                          onPressed: () {
                            _seekTo(
                              Duration(
                                seconds: valueProgress.value.inSeconds - 10,
                              ),
                            );
                          },
                        ),

                      // Play/Pause Button
                      if (_playerState == PlayerState.buffering)
                        IconButton(
                          icon: SizedBox(
                            width: 64,
                            height: 64,
                          ),
                          onPressed: () {},
                        )
                      else if (customControlParams?.showPlayButton ?? true)
                        IconButton(
                          icon: Icon(
                            _playerState == PlayerState.playing
                                ? Icons.pause_circle_filled
                                : Icons.play_circle_filled,
                            color: Colors.white,
                            size: 64,
                          ),
                          onPressed: () {
                            _playerState == PlayerState.playing
                                ? widget.controller.pauseVideo()
                                : widget.controller.playVideo();
                            _startHideControlsTimer();
                          },
                        ),

                      // Seek Forward Button
                      if (customControlParams?.showSeekButton ?? true)
                        IconButton(
                          icon: const Icon(Icons.forward_10,
                              color: Colors.white, size: 36),
                          onPressed: () async {
                            _seekTo(
                              Duration(
                                seconds: valueProgress.value.inSeconds + 10,
                              ),
                            );
                          },
                        ),
                    ],
                  ),

                if (customControlParams?.showPlayrateButton ?? true)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: PopupMenuButton<double>(
                      onOpened: () {
                        _hideControlsTimer?.cancel();
                      },
                      onCanceled: () {
                        _startHideControlsTimer();
                      },
                      onSelected: (value) {
                        _startHideControlsTimer();
                        widget.controller.setPlaybackRate(value);
                      },
                      itemBuilder: (context) => [
                        _buildSpeedMenuItem('0.25x', 0.25),
                        _buildSpeedMenuItem('0.5x', 0.5),
                        _buildSpeedMenuItem('0.75x', 0.75),
                        _buildSpeedMenuItem('1.0x', 1.0),
                        _buildSpeedMenuItem('1.25x', 1.25),
                        _buildSpeedMenuItem('1.5x', 1.5),
                        _buildSpeedMenuItem('1.75x', 1.75),
                        _buildSpeedMenuItem('2.0x', 2.0),
                      ],
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8.0,
                          horizontal: 16.0,
                        ),
                        child: const Icon(Icons.speed, color: Colors.white),
                      ),
                    ),
                  ),

                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            if (customControlParams?.showProgressTime ?? true)
                              ValueListenableBuilder(
                                valueListenable: valueProgress,
                                builder: (context, value, child) {
                                  final duration =
                                      _metaData?.duration ?? Duration.zero;
                                  final position = Duration(
                                      seconds: value.inSeconds
                                          .clamp(0, duration.inSeconds));

                                  return Row(
                                    children: [
                                      Text(
                                        _formatDuration(position),
                                        style: const TextStyle(
                                            color: Colors.white, fontSize: 12),
                                      ),
                                      Text(
                                        ' / ',
                                        style: const TextStyle(
                                            color: Colors.white, fontSize: 12),
                                      ),
                                      Text(
                                        _formatDuration(duration),
                                        style: const TextStyle(
                                            color: Colors.white, fontSize: 12),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            if (customControlParams?.showMuteButton ?? true)
                              IconButton(
                                icon: _isMute
                                    ? const Icon(Icons.volume_off,
                                        color: Colors.white)
                                    : const Icon(Icons.volume_up,
                                        color: Colors.white),
                                onPressed: () async {
                                  if (_isMute) {
                                    await widget.controller.unMute();
                                  } else {
                                    await widget.controller.mute();
                                  }
                                  setState(() {
                                    _isMute = !_isMute;
                                  });
                                  _startHideControlsTimer();
                                },
                              ),
                            Spacer(),
                            if (customControlParams?.showFullscreenButton ??
                                true)
                              IconButton(
                                icon: Icon(
                                  _isFullScreen
                                      ? Icons.fullscreen_exit
                                      : Icons.fullscreen,
                                  color: Colors.white,
                                ),
                                onPressed: () {
                                  widget.controller.toggleFullScreen();
                                  _startHideControlsTimer();
                                },
                              ),
                          ],
                        ),
                        if (customControlParams?.showProgressBar ?? true)
                          ValueListenableBuilder(
                            valueListenable: valueProgress,
                            builder: (context, value, child) {
                              return SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  padding: EdgeInsets.zero,
                                  trackHeight: 4.0,
                                  activeTrackColor:
                                      Theme.of(context).colorScheme.secondary,
                                  inactiveTrackColor: Theme.of(context)
                                      .disabledColor
                                      .withValues(alpha: .5),
                                  thumbColor:
                                      Theme.of(context).colorScheme.secondary,
                                  overlayColor: Theme.of(context)
                                      .colorScheme
                                      .surface
                                      .withValues(alpha: 0.5),
                                  thumbShape: RoundSliderThumbShape(
                                      enabledThumbRadius: 6.0),
                                  overlayShape: RoundSliderOverlayShape(
                                      overlayRadius: 10.0),
                                ),
                                child: Slider(
                                  value: value.inSeconds
                                      .toDouble()
                                      .clamp(0, duration.inSeconds.toDouble()),
                                  min: 0.0,
                                  max: duration.inSeconds.toDouble(),
                                  onChangeStart: (value) async {
                                    if (!(customControlParams
                                            ?.draggableProgressBar ??
                                        true)) return;
                                    _hideControlsTimer?.cancel();
                                    setState(() {
                                      _seekPlayerState = _playerState;
                                    });
                                    await widget.controller.pauseVideo();
                                  },
                                  onChangeEnd: (newValue) async {
                                    if (!(customControlParams
                                            ?.draggableProgressBar ??
                                        true)) return;

                                    if (_seekPlayerState ==
                                        PlayerState.playing) {
                                      await widget.controller.playVideo();
                                    }

                                    _startHideControlsTimer();
                                    setState(() {
                                      _seekPlayerState = null;
                                    });
                                  },
                                  onChanged: (newValue) {
                                    if (!(customControlParams
                                            ?.draggableProgressBar ??
                                        true)) return;

                                    _seekTo(
                                      Duration(
                                        seconds: newValue.toInt(),
                                      ),
                                      startHideTimer: false,
                                    );
                                  },
                                ),
                              );
                            },
                          )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
