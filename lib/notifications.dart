import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:social_media_app/colors.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'services/story_widgets.dart';

class Messages extends StatefulWidget {
  final userId;
  Messages({required this.userId});

  @override
  _MessagesState createState() => _MessagesState();
}

class _MessagesState extends State<Messages> {
  Stream<QuerySnapshot>? messagesStream;
  Future onLaunch() async {
    messagesStream = await FirebaseFirestore.instance
        .collection("users")
        .doc(widget.userId)
        .collection("messages")
        .orderBy("ts", descending: true)
        .snapshots();
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
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: SvgPicture.asset('lib/assets/image/back.svg'),
        ),
        title: Text(
          "Notifications",
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            StreamBuilder<dynamic>(
                stream: messagesStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.active) {
                    if (snapshot.hasData) {
                      if (snapshot.data!.docs.length == 0) {
                        return Center(
                          child: Padding(
                            padding: EdgeInsets.only(top: 100),
                            child: Text(
                              'No\nNotifications',
                              style: TextStyle(
                                color: Colors.grey.shade300,
                                fontSize: 30,
                                fontWeight: FontWeight.w900,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      } else {
                        return ListView.builder(
                          itemCount: snapshot.data!.docs.length,
                          shrinkWrap: true,
                          itemBuilder: (context, index) {
                            DocumentSnapshot ds = snapshot.data!.docs[index];
                            return NotificationBox(context, ds);
                          },
                        );
                      }
                    } else {
                      return CustomProgress();
                    }
                  } else {
                    return CustomProgress();
                  }
                }),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onPressed: () async {
          String url =
              'mailto:socialmediaapp037@gmail.com?subject=${Uri.encodeFull("Review on Socialize")}&body=${Uri.encodeFull("Write Here.........")}';
          if (await canLaunch(url)) {
            await launch(url
                // Uri.parse(url),
                // mode: LaunchMode.externalApplication,
                );
          }
        },
        elevation: 0,
        backgroundColor: primaryColor,
        label: Text(
          "Send Review",
          style: TextStyle(
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget NotificationBox(
    BuildContext context,
    DocumentSnapshot<Object?> ds,
  ) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(top: 10, bottom: 0, left: 5, right: 5),
      padding: EdgeInsets.all(15),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ds["message"],
            style: TextStyle(
              color: ds["type"] == "Casual"
                  ? Colors.blue.shade900
                  : ds["type"] == "Warning"
                      ? Colors.amber.shade700
                      : Colors.red.shade900,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(
            height: 10,
          ),
          Text(
            timeago.format(ds["ts"].toDate()),
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: ds["type"] == "Casual"
            ? Colors.blue.shade100
            : ds["type"] == "Warning"
                ? Colors.amber.shade100
                : Colors.red.shade100,
        border: Border.all(
          width: 1,
          color: ds["type"] == "Casual"
              ? Colors.blue
              : ds["type"] == "Warning"
                  ? Colors.amber.shade800
                  : Colors.red,
        ),
      ),
    );
  }
}
