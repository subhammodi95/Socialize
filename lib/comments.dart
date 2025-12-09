import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:jiffy/jiffy.dart';
import 'package:provider/provider.dart';
import 'package:social_media_app/colors.dart';
import 'package:social_media_app/services/story_widgets.dart';
import '/services/database.dart';
import '/services/provider.dart';

class Comments extends StatefulWidget {
  // const Comments({ Key? key }) : super(key: key);
  final userName;
  final userId;
  final postId;
  final myUserId;
  final myImgUrl;
  final myUserName;
  final myName;
  Comments(
    this.userName,
    this.userId,
    this.postId,
    this.myUserId,
    this.myUserName,
    this.myName,
    this.myImgUrl,
  );
  @override
  _CommentsState createState() => _CommentsState();
}

class _CommentsState extends State<Comments> {
  TextEditingController commentTextEditingController =
      TextEditingController(text: "");
  Stream<QuerySnapshot>? commentStream;
  String tokenId = "";

  void addComment() async {
    DocumentSnapshot snapshot =
        await DatabaseMethods().postDetails(widget.userId, widget.postId);
    List comments = snapshot["comments"].toList();
    comments.add(widget.myUserName);
    Map<String, dynamic> CommentInfoMap = {
      "comment": commentTextEditingController.text,
      "userName": widget.myUserName,
      "imgUrl": widget.myImgUrl,
      "name": widget.myName,
      "ts": DateTime.now()
    };
    commentTextEditingController.clear();
    await FirebaseFirestore.instance
        .collection("posts")
        .doc(widget.postId)
        .collection("Comments")
        .doc(widget.myUserName + "_" + DateTime.now().toString())
        .set(CommentInfoMap);
    Map<String, dynamic> commentsMap = {"comments": comments};
    await FirebaseFirestore.instance
        .collection("posts")
        .doc(widget.postId)
        .update(commentsMap);
    if (widget.myUserName != widget.userName) {
      DatabaseMethods().sendNotification([tokenId],
          "${widget.myName} commented on your post", "Alert", widget.myImgUrl);
    }
  }

  void deleteComment(
      String commentId, String commentUserName, String comment) async {
    DocumentSnapshot snapshot =
        await DatabaseMethods().postDetails(widget.userId, widget.postId);
    List comments = snapshot["comments"].toList();
    comments.remove(commentUserName);
    await FirebaseFirestore.instance
        .collection("posts")
        .doc(widget.postId)
        .collection("Comments")
        .doc(commentId)
        .delete();
    Map<String, dynamic> commentsMap = {"comments": comments};
    await FirebaseFirestore.instance
        .collection("posts")
        .doc(widget.postId)
        .update(commentsMap);
    if (widget.myUserName != widget.userName) {
      DatabaseMethods().sendNotification(
          [tokenId], comment, "Comment Deleted", widget.myImgUrl);
    }
  }

  onLaunch() async {
    commentStream =
        await DatabaseMethods().getCommentsStream(widget.userId, widget.postId);
    QuerySnapshot userDetails =
        await DatabaseMethods().getUserInfo2(widget.userName);
    tokenId = userDetails.docs[0]["tokenId"];
    setState(() {});
  }

  @override
  void initState() {
    onLaunch();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle.light.copyWith(
        statusBarBrightness: Brightness.light,
        statusBarIconBrightness: Brightness.dark,
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: SvgPicture.asset(
            'lib/assets/image/back.svg',
            color: Colors.black,
          ),
        ),
        title: Text(
          "Comments",
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: StreamBuilder(
                  stream: commentStream,
                  builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                    if (snapshot.connectionState != ConnectionState.active) {
                      return CustomProgress();
                    }
                    if (snapshot.hasData) {
                      if (snapshot.data!.docs.length == 0) {
                        return Center(
                          child: Padding(
                            padding: EdgeInsets.only(top: 100),
                            child: Text(
                              "No comments here",
                              style: TextStyle(
                                fontSize: 25,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade400,
                              ),
                            ),
                          ),
                        );
                      } else {
                        return ListView.builder(
                          padding: const EdgeInsets.only(bottom: 70, top: 16),
                          itemCount: snapshot.data!.docs.length,
                          reverse: true,
                          shrinkWrap: true,
                          itemBuilder: (context, index) {
                            DocumentSnapshot ds = snapshot.data!.docs[index];
                            return CommentCard(ds);
                          },
                        );
                      }
                    } else {
                      return CustomProgress();
                    }
                  },
                ),
              ),
            ),
            widget.myUserId == ""
                ? Container()
                : Container(
                    margin: EdgeInsets.all(10),
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(50),
                      ),
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: commentTextEditingController,
                              style: TextStyle(color: Colors.black),
                              maxLines: 5,
                              minLines: 1,
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: "Comment Something ...",
                                hintStyle: TextStyle(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () async {
                              if (commentTextEditingController.text.trim() !=
                                  "") {
                                addComment();
                              }

                              await Provider.of<Btn>(context, listen: false)
                                  .changeBtn();
                            },
                            child: Consumer<Btn>(
                              builder: (ctx, provider, _) => CircleAvatar(
                                radius: 20,
                                backgroundColor: primaryColor,
                                child: CircleAvatar(
                                  radius: 10,
                                  backgroundColor: Colors.grey.shade100,
                                ),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget CommentCard(DocumentSnapshot<Object?> ds) {
    return Padding(
      padding: EdgeInsets.only(bottom: 20, left: 10, right: 10),
      child: Container(
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage(
                ds['imgUrl'],
              ),
            ),
            SizedBox(
              width: 10,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "${ds["name"]}",
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                      // Spacer(),
                      Container(
                        child: ds["ts"]
                                    .toDate()
                                    .add(Duration(hours: 24))
                                    .compareTo(DateTime.now()) <
                                0
                            ? Text(
                                Jiffy(ds["ts"].toDate()).format('do MMM'),
                                style: TextStyle(
                                  color: Colors.grey.shade900,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12,
                                ),
                              )
                            : Text(
                                Jiffy(ds["ts"].toDate()).format('h:mm a'),
                                style: TextStyle(
                                  color: Colors.grey.shade900,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 5,
                  ),
                  Text(
                    "${ds["comment"]}",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 10,
            ),
            (ds["userName"] == widget.myUserName) || (widget.myUserId == "")
                ? Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.red.shade100,
                    ),
                    child: GestureDetector(
                      child: Icon(
                        Icons.delete,
                        size: 20,
                        color: Colors.red,
                      ),
                      onTap: () {
                        deleteComment(ds.id, ds["userName"], ds["comment"]);
                      },
                    ),
                  )
                : Container()
          ],
        ),
      ),
    );
  }
}
