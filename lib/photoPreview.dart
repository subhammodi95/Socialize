import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:social_media_app/services/story_widgets.dart';

class PhotoPreview extends StatefulWidget {
  final imgUrl;
  const PhotoPreview({Key? key, this.imgUrl}) : super(key: key);

  @override
  State<PhotoPreview> createState() => _PhotoPreviewState();
}

class _PhotoPreviewState extends State<PhotoPreview> {
  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle.light.copyWith(
        statusBarBrightness: Brightness.light,
        statusBarIconBrightness: Brightness.light,
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
    return Scaffold(
      backgroundColor: Colors.white,
      body: widget.imgUrl == ''
          ? CustomProgress()
          : Center(
              child: Image.network(widget.imgUrl),
            ),
    );
  }
}
