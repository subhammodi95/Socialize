import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:social_media_app/colors.dart';
import 'package:video_player/video_player.dart';

import 'services/story_widgets.dart';

class VideoPlayerUi extends StatefulWidget {
  // const VideoPlayerUi({Key? key}) : super(key: key);
  final videoUrl;
  VideoPlayerUi(this.videoUrl);
  @override
  _VideoPlayerUiState createState() => _VideoPlayerUiState();
}

class _VideoPlayerUiState extends State<VideoPlayerUi> {
  late VideoPlayerController controller;
  late Future<void> initializeVideoPlayerFuture;
  bool isFullscreen = false;

  @override
  void initState() {
    controller = VideoPlayerController.network(widget.videoUrl)
      ..addListener(() => setState(() {}))
      ..setLooping(true)
      ..initialize().then((value) => controller.play());
    initializeVideoPlayerFuture = controller.initialize();

    // controller.setLooping(true);
    // controller.setVolume(1.0);
    // controller.play();
    setState(() {});

    super.initState();
  }

  @override
  void dispose() {
    controller.pause();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle.light.copyWith(
        statusBarBrightness: Brightness.light,
        statusBarIconBrightness: Brightness.dark,
        // statusBarColor: isFullscreen ? Colors.black : Colors.white,
        // systemNavigationBarColor: isFullscreen ? Colors.black : Colors.white,
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
      ),
    );
    final isMuted = controller.value.volume == 0;
    return controller != null && controller.value.isInitialized
        ? Scaffold(
            backgroundColor: isFullscreen ? Colors.black : Colors.white,
            body: SafeArea(
              child: isFullscreen
                  ? Center(child: BuildVideo())
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 20,
                        ),
                        Container(
                          alignment: Alignment.center,
                          child: BuildVideo(),
                        ),
                      ],
                    ),
            ),
            floatingActionButton:
                controller != null && controller.value.isInitialized
                    ? FloatingActionButton(
                        onPressed: () {
                          setState(() {
                            controller.setVolume(isMuted ? 1 : 0);
                          });
                        },
                        child: Icon(
                          isMuted
                              ? Icons.music_note_outlined
                              : Icons.music_off_outlined,
                        ),
                      )
                    : Container(),
          )
        : CustomProgress();
  }

  Widget BuildVideo() {
    return AspectRatio(
      aspectRatio: controller.value.aspectRatio,
      child: Stack(
        children: [
          VideoPlayer(controller),
          Positioned.fill(
            child: BasicOverlayWidget(controller: controller),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: Container(
              margin: EdgeInsets.all(20),
              height: 30,
              width: 30,
              color: Colors.transparent,
              child: IconButton(
                onPressed: () {
                  setState(() {
                    isFullscreen = !isFullscreen;
                  });
                },
                icon: Icon(
                  isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BasicOverlayWidget extends StatelessWidget {
  final controller;
  BasicOverlayWidget({this.controller});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        controller.value.isPlaying ? controller.pause() : controller.play();
      },
      child: Stack(
        children: [
          buildPlay(),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: buildIndicator(),
          ),
        ],
      ),
    );
  }

  Widget buildIndicator() {
    return VideoProgressIndicator(
      controller,
      colors: VideoProgressColors(playedColor: primaryColor),
      allowScrubbing: true,
    );
  }

  Widget buildPlay() {
    return controller.value.isPlaying
        ? Container()
        : Container(
            alignment: Alignment.center,
            color: Colors.black.withOpacity(0.3),
            child: Icon(
              Icons.play_arrow,
              color: Colors.white.withOpacity(0.7),
              size: 80,
            ),
          );
  }
}
