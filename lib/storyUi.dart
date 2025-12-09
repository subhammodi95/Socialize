import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:circular_countdown_timer/circular_countdown_timer.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:open_file/open_file.dart';
import 'package:page_route_transition/page_route_transition.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:social_media_app/colors.dart';
import 'package:social_media_app/services/database.dart';
import 'package:social_media_app/services/story_widgets.dart';

class StoryUi extends StatefulWidget {
  String myUserId;
  String myUserImg;
  String myUserName;
  String myDisplayName;
  String userImg;
  String userName;
  Timestamp time;
  String displayName;
  String imgUrl;
  String storyId;
  bool isMe;
  StoryUi({
    required this.imgUrl,
    required this.myUserId,
    required this.myUserImg,
    required this.myUserName,
    required this.myDisplayName,
    required this.time,
    required this.storyId,
    required this.isMe,
    required this.userImg,
    required this.displayName,
    required this.userName,
  });

  @override
  _StoryUiState createState() => _StoryUiState();
}

class _StoryUiState extends State<StoryUi> {
  Timer? timer;
  Future<bool> _requestpermission(Permission permission) async {
    //to check if user accepted the permissions
    if (await permission.isGranted) {
      return true;
    } else {
      var result =
          await permission.request(); //request permission again to the user
      if (result == PermissionStatus.granted) {
        return true;
      } else {
        return false;
      }
    }
  }

  Future<void> downloadFile() async {
    String name = "";
    name = "Socialize" +
        "_" +
        widget.displayName.toString() +
        widget.time.toString() +
        ".jpg";

    //===============
    try {
      Directory directory;
      if (await _requestpermission(Permission.storage)) {
        directory = (await getExternalStorageDirectory())!;
        //till now we have got the basic default address storage that is at /storage/emulated/0/Android/data/..........
        String newpath = "";
        List<String> folders =
            directory.path.split("/"); //to reach the Android folder
        for (int x = 1; x < folders.length; x++) {
          //x=1 because at x=0 is empty
          String folder = folders[x];
          if (folder != "Android") {
            newpath += "/" + folder;
          } else {
            break;
          }
        }
        newpath = newpath + "/Socialize/Stories";
        directory = Directory(newpath);

        if (!await directory.exists()) {
          //if directory extracted does not exists, create one
          await directory.create(recursive: true);
        }

        //======================================================================
        final file = File('${directory.path}/$name');
        final response = await Dio().get(
          widget.imgUrl,
          options: Options(
              responseType: ResponseType.bytes,
              followRedirects: false,
              receiveTimeout: 0),
          // onReceiveProgress: (rec, total){

          // }
        );
        final raf = file.openSync(mode: FileMode.write);
        raf.writeFromSync(response.data);
        await raf.close();
        OpenFile.open(file.path);
      } else {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Failed!! Storage Access Denied",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Downloading Failed",
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void initState() {
    if (widget.isMe == false) {
      StoryWidgets().addSeenStamp(context, widget.storyId, widget.myUserId,
          widget.myUserName, widget.myUserImg, widget.myDisplayName);
    }
    timer = Timer(Duration(seconds: 17), () {
      timer!.cancel();
      PageRouteTransition.effect = TransitionEffect.topToBottom;
      PageRouteTransition.pop(context);
    }
        // Navigator.pop(context, PageRouteTransitionBuilder(page: page, effect: TransitionEffect.leftToRight))
        );
    super.initState();
  }

  @override
  void dispose() {
    timer!.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle.dark.copyWith(
        statusBarBrightness: Brightness.dark,
        statusBarIconBrightness: Brightness.dark,
        statusBarColor: Colors.black,
        systemNavigationBarColor: Colors.black,
      ),
    );
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: SvgPicture.asset(
            'lib/assets/image/back.svg',
            color: primaryColor,
          ),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  child: CachedNetworkImage(
                    imageUrl: widget.userImg,
                    imageBuilder: (context, image) => CircleAvatar(
                      radius: 20,
                      backgroundImage: image,
                    ),
                  ),
                ),
                SizedBox(
                  width: 10,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.userName == widget.myUserName
                          ? 'You'
                          : widget.displayName,
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                      ),
                    ),
                    Text(
                      StoryWidgets().storyTimePosted(widget.time),
                      style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(
              height: 30,
              width: 30,
              child: CircularCountDownTimer(
                isTimerTextShown: false,
                duration: 15,
                fillColor: Colors.green,
                height: 20.0,
                width: 20.0,
                ringColor: Colors.grey.shade100,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () async {
              return showMenu(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 5,
                color: Colors.white,
                context: context,
                position: RelativeRect.fromLTRB(300, 70, 0.0, 0.0),
                items: [
                  PopupMenuItem(
                    onTap: () {
                      downloadFile();
                    },
                    child: Row(
                      // mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Icon(
                          Icons.download,
                          color: Colors.blue,
                        ),
                        SizedBox(
                          width: 10,
                        ),
                        Text(
                          "Download",
                          style: TextStyle(
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    onTap: () {
                      FirebaseFirestore.instance
                          .collection("stories")
                          .doc(widget.storyId)
                          .delete()
                          .whenComplete(() async {
                        await DatabaseMethods().deleteImg(widget.imgUrl);
                        PageRouteTransition.effect =
                            TransitionEffect.topToBottom;
                        PageRouteTransition.pop(context);
                      });
                    },
                    enabled: widget.isMe,
                    child: Row(
                      // mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Icon(
                          Icons.delete,
                          color: Colors.red,
                        ),
                        SizedBox(
                          width: 10,
                        ),
                        Text(
                          "Delete",
                          style: TextStyle(
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
            icon: Icon(
              Icons.more_vert,
              color: Colors.black,
            ),
          ),
        ],
      ),
      body: GestureDetector(
        onPanUpdate: (update) {
          if (update.delta.dx > 0) {
            timer!.cancel();
            PageRouteTransition.effect = TransitionEffect.topToBottom;
            PageRouteTransition.pop(context);
          }
        },
        child: Column(
          // alignment: Alignment.bottomCenter,
          children: [
            Expanded(
              child: Hero(
                tag: widget.imgUrl,
                child: Container(
                  height: double.infinity,
                  width: double.infinity,
                  child: CachedNetworkImage(
                    imageUrl: widget.imgUrl,
                    fit: BoxFit.fitWidth,
                  ),
                ),
              ),
            ),
            widget.isMe
                ? GestureDetector(
                    onTap: () {
                      showBarModalBottomSheet(
                        context: context,
                        builder: (context) {
                          return ViewList(
                            context: context,
                            myUserId: widget.myUserId,
                            storyId: widget.storyId,
                          );
                        },
                      );
                    },
                    child: Container(
                      color: Colors.transparent,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection("stories")
                                .doc(widget.storyId)
                                .collection("seen")
                                .snapshots(),
                            builder: (context,
                                AsyncSnapshot<QuerySnapshot> snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.active) {
                                if (snapshot.hasData) {
                                  return Text(
                                    snapshot.data!.docs.length.toString(),
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  );
                                } else {
                                  return Text(
                                    "0",
                                    style: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold),
                                  );
                                }
                              } else {
                                return CustomProgress();
                              }
                            },
                          ),
                          SizedBox(
                            height: 5,
                          ),
                          Icon(
                            Icons.remove_red_eye,
                          ),
                        ],
                      ),
                    ),
                  )
                : Container(),
          ],
        ),
      ),
    );
  }

  Widget ViewList({final context, storyId, myUserId}) {
    return StatefulBuilder(
      builder: (context, StateSetter setModalState) {
        return Container(
          padding: EdgeInsets.only(top: 20),
          child: Column(children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.4,
              width: MediaQuery.of(context).size.width,
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("stories")
                    .doc(storyId)
                    .collection("seen")
                    .snapshots(),
                builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.connectionState == ConnectionState.active) {
                    if (snapshot.hasData) {
                      return ListView(
                        children: snapshot.data!.docs
                            .map((DocumentSnapshot documentSnapshot) {
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage:
                                  NetworkImage(documentSnapshot["userImg"]),
                              radius: 25,
                            ),
                            // trailing: IconButton(
                            //   icon: Icon(
                            //     Icons.arrow_circle_right_rounded,
                            //   ),
                            //   onPressed: () {},
                            // ),
                            title: Text(
                              documentSnapshot["displayName"],
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Text(
                              StoryWidgets()
                                  .storyTimePosted(documentSnapshot["time"]),
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    } else {
                      return Container();
                    }
                  } else {
                    return Container();
                  }
                },
              ),
            )
          ]),
          height: MediaQuery.of(context).size.height * 0.5,
          width: MediaQuery.of(context).size.width,
        );
      },
    );
  }
}
