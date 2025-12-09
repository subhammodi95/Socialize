import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jiffy/jiffy.dart';
import 'package:open_file/open_file.dart';
import 'package:page_route_transition/page_route_transition.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:social_media_app/colors.dart';
import 'package:social_media_app/photoPreview.dart';
import 'package:social_media_app/services/like_animation.dart';
import 'package:social_media_app/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import '/comments.dart';
import '/services/database.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pdf/widgets.dart' as pw;

class FeedCard extends StatefulWidget {
  final userImg;
  final userName;
  final postType;
  final caption;
  final postUrl;
  final ts;
  final postId;
  final posted_by;
  final userId;
  final likes;
  final comments;
  final myUserName;
  final myUserId;
  final myUserImg;
  final myDisplayName;
  FeedCard(
      {required this.postType,
      required this.caption,
      required this.userImg,
      required this.userName,
      required this.postUrl,
      required this.ts,
      required this.likes,
      required this.comments,
      required this.postId,
      required this.posted_by,
      required this.userId,
      required this.myUserName,
      required this.myUserId,
      required this.myUserImg,
      required this.myDisplayName});

  @override
  State<FeedCard> createState() => _FeedCardState();
}

class _FeedCardState extends State<FeedCard> {
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
    if (widget.postType == "image") {
      // image
      name = "Socialize" +
          "_" +
          widget.posted_by.toString() +
          widget.ts.toString() +
          ".jpg";
    } else if (widget.postType == "video") {
      // video
      name = "Socialize" +
          "_" +
          widget.posted_by.toString() +
          widget.ts.toString() +
          ".mp4";
    } else if (widget.postType == "text") {
      //text
      name = "Socialize" +
          "_" +
          widget.posted_by.toString() +
          widget.ts.toString() +
          ".pdf";
    } else {
      // file
      name = "Socialize" +
          "_" +
          widget.posted_by.toString() +
          widget.ts.toString() +
          "_" +
          widget.postType.toString().split('_')[0];
    }

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
        newpath = newpath + "/Socialize";
        directory = Directory(newpath);

        if (!await directory.exists()) {
          //if directory extracted does not exists, create one
          await directory.create(recursive: true);
        }

        //======================================================================
        final file = File('${directory.path}/$name');

        if (widget.postType == "text") {
          //========== CREATE PDF =================
          final pdf = pw.Document();
          pdf.addPage(pw.Page(
              build: (context) => pw.Column(children: [
                    pw.Text("SOCIALIZE",
                        style: pw.TextStyle(
                            fontSize: 30,
                            fontWeight: pw.FontWeight.bold,
                            fontStyle: pw.FontStyle.italic)),
                    pw.Padding(padding: const pw.EdgeInsets.all(20)),
                    pw.Text(widget.caption)
                  ])));
          //=============== SAVE PDF ======================
          await file.writeAsBytes(await pdf.save());
        } else {
          final response = await Dio().get(widget.postUrl,
              options: Options(
                  responseType: ResponseType.bytes,
                  followRedirects: false,
                  receiveTimeout: 0));
          final raf = file.openSync(mode: FileMode.write);
          raf.writeFromSync(response.data);
          await raf.close();
        }

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

  Future updateLike() async {
    List like = await widget.likes.toList();
    if (widget.likes.toList().contains(widget.myUserName)) {
      like.remove(widget.myUserName);
      await DatabaseMethods().updateLike(widget.userId, widget.postId, like);
    } else {
      like.add(widget.myUserName);
      await DatabaseMethods().updateLike(widget.userId, widget.postId, like);
    }
  }

  Future share() async {
    String postId = "";
    Map<String, dynamic> postInfoMap = {
      "ts": DateTime.now(),
      "posted_by": widget.myUserName,
      "userImg": widget.myUserImg,
      "url": widget.postUrl,
      "likes": [],
      "comments": [],
      "desc": widget.caption,
      "type": widget.postType,
    };
    postId = widget.myUserId +
        "_" +
        widget.myDisplayName +
        "_" +
        DateTime.now().toString();
    await DatabaseMethods()
        .addPost(widget.myUserId, postId, postInfoMap)
        .then((value) {});
  }

  void _showdialog(bool isMe) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
          title: Text('Perform an action'),
          elevation: 0,
          actions: [
            isMe == true || widget.myUserId == ""
                ? MaterialButton(
                    onPressed: () async {
                      Navigator.of(context).pop();
                      await DatabaseMethods().deleteThisPost(
                          widget.userId, widget.postId, widget.postUrl);
                    },
                    color: Colors.red.shade700,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Text(
                      'Delete',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  )
                : Container(),
            MaterialButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await downloadFile();
              },
              color: Colors.green.shade700,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(50),
              ),
              child: Text(
                'Download',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  bool isLikeAnimating = false;

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle.light.copyWith(
        statusBarBrightness: Brightness.light,
        statusBarIconBrightness: Brightness.light,
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 10),
      // padding: EdgeInsets.all(20),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 10, left: 10, right: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 50,
                  width: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.circular(10),
                    image: DecorationImage(
                      image: NetworkImage(widget.userImg),
                    ),
                  ),
                ),
                SizedBox(
                  width: 10,
                ),
                Container(
                  width: MediaQuery.of(context).size.width * 0.6,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        maxLines: 2,
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: widget.userName,
                              style: GoogleFonts.manrope(
                                fontWeight: FontWeight.w700,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            TextSpan(
                              text: widget.postType == 'image'
                                  ? ' shared an image'
                                  : widget.postType == 'text'
                                      ? ' said something'
                                      : widget.postType == 'video'
                                          ? ' shared a video'
                                          : ' shared a file',
                              style: GoogleFonts.manrope(
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 5,
                      ),
                      Text(
                        widget.ts
                                    .toDate()
                                    .add(const Duration(hours: 24))
                                    .compareTo(DateTime.now()) <
                                0
                            ? Jiffy(widget.ts.toDate()).format('do MMM')
                            : Jiffy(widget.ts.toDate()).format('h:mm a'),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Spacer(),
                IconButton(
                  onPressed: () {
                    _showdialog(
                        widget.posted_by == widget.myUserName ? true : false);
                  },
                  icon: Icon(
                    Icons.more_horiz,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 20,
          ),
          widget.caption != ''
              ? Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  child: SelectableLinkify(
                    linkStyle: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.none,
                    ),
                    onOpen: (link) async {
                      if (await canLaunch(link.url)) {
                        await launch(
                          link.url,
                          // mode: LaunchMode.externalApplication,
                        );
                      } else {
                        throw 'Could not launch $link';
                      }
                    },
                    text: widget.caption,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w600,
                      fontSize: widget.postType == 'image' ||
                              widget.postType == 'video'
                          ? 14
                          : widget.caption.length > 70
                              ? 16
                              : 20,
                    ),
                  ),
                )
              : Container(),
          widget.caption != ''
              ? SizedBox(
                  height: 10,
                )
              : Container(),
          widget.postType == 'image'
              ? GestureDetector(
                  onDoubleTap: () async {
                    setState(() {
                      isLikeAnimating = true;
                    });
                    if (widget.myUserId == "") {
                      return;
                    } else {
                      await updateLike();
                    }
                  },
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => PhotoPreview(
                                  imgUrl: widget.postUrl,
                                )));
                  },
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Image.network(
                        widget.postUrl,
                        fit: BoxFit.cover,
                      ),
                      AnimatedOpacity(
                        duration: Duration(milliseconds: 200),
                        opacity: isLikeAnimating ? 1 : 0,
                        child: LikeAnimation(
                          child: SvgPicture.asset(
                            'lib/assets/image/like_filled.svg',
                            color: Colors.white,
                            height: 100,
                          ),
                          isAnimating: isLikeAnimating,
                          duration: Duration(milliseconds: 400),
                          onEnd: () {
                            setState(() {
                              isLikeAnimating = false;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                )
              : widget.postType == 'video'
                  ? InkWell(
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) =>
                                VideoPlayerUi(widget.postUrl)));
                      },
                      child: Container(
                        width: double.infinity,
                        height: 250,
                        color: Colors.black,
                        child: Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 50,
                        ),
                      ),
                    )
                  : widget.postType == 'text'
                      ? Container()
                      : Container(
                          // height: 200,
                          padding: EdgeInsets.all(20),
                          margin: EdgeInsets.symmetric(horizontal: 10),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            // color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey.shade300,
                            ),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.shade100,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      Icons.description,
                                      color: Colors.amber.shade800,
                                    ),
                                  ),
                                  SizedBox(
                                    width: 10,
                                  ),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        // color: Colors.yellow,
                                        width:
                                            MediaQuery.of(context).size.width *
                                                0.65,
                                        child: Text(
                                          widget.postType
                                              .toString()
                                              .split('_')[1],
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(
                                        height: 7,
                                      ),
                                      Text(
                                        widget.postType
                                            .toString()
                                            .split('_')[2],
                                        // "thus",
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              SizedBox(
                                height: 15,
                              ),
                              MaterialButton(
                                onPressed: () async {
                                  if (await canLaunch(widget.postUrl)) {
                                    await launch(
                                      widget.postUrl,
                                      // forceSafariVC: true,
                                      // forceWebView: true,
                                      // enableJavaScript: true
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context)
                                        .hideCurrentSnackBar();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          "File Not Found!!",
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                },
                                color: Color(0xff299fb5).withOpacity(0.1),
                                elevation: 0,
                                highlightElevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(7),
                                ),
                                child: Container(
                                  padding: EdgeInsets.all(15),
                                  width: double.infinity,
                                  child: const Center(
                                    child: Text(
                                      'Open',
                                      style: TextStyle(
                                        color: Color(0xff299fb5),
                                        fontWeight: FontWeight.w700,
                                        fontSize: 17,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
          SizedBox(
            height: 10,
          ),
          Padding(
            padding: EdgeInsets.only(right: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                LikeAnimation(
                  isAnimating: widget.likes.contains(widget.myUserName),
                  smallLike: true,
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () async {
                          if (widget.myUserId == "") {
                            return;
                          } else {
                            await updateLike();
                          }
                        },
                        icon: SvgPicture.asset(
                          widget.likes.contains(widget.myUserName)
                              ? 'lib/assets/image/like_filled.svg'
                              : 'lib/assets/image/like.svg',
                          color: widget.myUserId == ""
                              ? Colors.pink.withOpacity(0.4)
                              : Colors.pink,
                          height: 17,
                        ),
                      ),
                      Text(
                        '${widget.likes.length}',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: widget.myUserId == ""
                              ? Colors.pink.withOpacity(0.4)
                              : Colors.pink,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                MaterialButton(
                  onPressed: () {
                    PageRouteTransition.push(
                      context,
                      Comments(
                        widget.posted_by,
                        widget.userId,
                        widget.postId,
                        widget.myUserId,
                        widget.myUserName,
                        widget.myDisplayName,
                        widget.myUserImg,
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      widget.comments.contains(widget.myUserName)
                          ? Icon(
                              Icons.chat_bubble,
                              color: Colors.amber.shade800,
                            )
                          : SvgPicture.asset(
                              'lib/assets/image/comment.svg',
                              color: Colors.amber.shade800,
                              height: 17,
                            ),
                      const SizedBox(
                        width: 10,
                      ),
                      Text(
                        '${widget.comments.length} Comments',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Colors.amber.shade800,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () async {
                    if (widget.myUserId == "") {
                      return;
                    } else {
                      await share();
                    }
                  },
                  child: Row(
                    children: [
                      SvgPicture.asset(
                        'lib/assets/image/share.svg',
                        color: widget.myUserId == ""
                            ? Colors.blue.shade800.withOpacity(0.4)
                            : Colors.blue.shade800,
                        height: 17,
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      Text(
                        'Share',
                        style: TextStyle(
                          color: widget.myUserId == ""
                              ? Colors.blue.shade800.withOpacity(0.4)
                              : Colors.blue.shade800,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PlusMinusEntry extends PopupMenuEntry<int> {
  @override
  double height = 100;
  // height doesn't matter, as long as we are not giving
  // initialValue to showMenu().

  @override
  bool represents(int? n) => n == 1 || n == -1;

  @override
  PlusMinusEntryState createState() => PlusMinusEntryState();
}

class PlusMinusEntryState extends State<PlusMinusEntry> {
  void _plus1() {
    // This is how you close the popup menu and return user selection.
    Navigator.pop<int>(context, 1);
  }

  void _minus1() {
    Navigator.pop<int>(context, -1);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(child: FlatButton(onPressed: _plus1, child: Text('+1'))),
        Expanded(child: FlatButton(onPressed: _minus1, child: Text('-1'))),
      ],
    );
  }
}
