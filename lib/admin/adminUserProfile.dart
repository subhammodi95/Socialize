import 'dart:io';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:jiffy/jiffy.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:social_media_app/services/database.dart';

import 'package:pdf/widgets.dart' as pw;
import 'package:timeago/timeago.dart' as timeago;

import '../colors.dart';
import '../feeds.dart';
import '../services/provider.dart';

class AdminUserProfile extends StatefulWidget {
  // const AdminUserProfile({Key? key}) : super(key: key);
  final userId;
  final userName;
  final email;
  final tokenId;
  AdminUserProfile(this.userId, this.userName, this.email, this.tokenId);
  @override
  _AdminUserProfileState createState() => _AdminUserProfileState();
}

class _AdminUserProfileState extends State<AdminUserProfile> {
  String screen = "Posts";
  String messageType = "Casual";
  TextEditingController message = TextEditingController();
  Stream<QuerySnapshot>? postStream;
  Stream<QuerySnapshot>? friendStream;
  Stream<QuerySnapshot>? requestStream;
  Stream<QuerySnapshot>? userStream;
  Stream<QuerySnapshot>? messagesStream;

  var postList, friendList, requestList;

  Widget SendMessage(context) {
    return StatefulBuilder(
      builder: (context, StateSetter setModalState) {
        return Container(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Send Message',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 22,
                ),
              ),
              SizedBox(
                height: 15,
              ),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.grey.shade200,
                ),
                child: TextField(
                  controller: message,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                  maxLines: 4,
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.all(10),
                    border: InputBorder.none,
                    labelText: 'Message',
                    labelStyle: TextStyle(
                      color: Colors.teal.shade800,
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 10,
              ),
              Text(
                'Message Type',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              SizedBox(
                height: 15,
              ),
              MessageTypBtn(
                setModalState,
                text: 'Casual',
              ),
              MessageTypBtn(
                setModalState,
                text: 'Warning',
              ),
              MessageTypBtn(
                setModalState,
                text: 'Critical',
              ),
              MaterialButton(
                onPressed: () async {
                  if (message.text.trim() != "") {
                    var time = Timestamp.now();
                    await FirebaseFirestore.instance
                        .collection("users")
                        .doc(widget.userId)
                        .collection("messages")
                        .doc(time.toString())
                        .set({
                      "message": message.text,
                      "ts": time,
                      "type": messageType,
                    });
                    DatabaseMethods().sendNotification(
                        [widget.tokenId], "${message.text}", "Admin", "");
                    message.clear();
                    Navigator.pop(context);
                  }
                },
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5)),
                color: primaryColor,
                elevation: 0,
                padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                child: Text(
                  "Send",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(
                height: MediaQuery.of(context).viewInsets.bottom,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget MessageTypBtn(StateSetter setModalState, {final text}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: MaterialButton(
        onPressed: () {
          setModalState(() {
            messageType = text;
          });
          // messageType = "Casual";
          // await Provider.of<Btn>(context, listen: false).changeBtn();
        },
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(7),
          side: BorderSide(
            color: messageType == text
                ? text == 'Casual'
                    ? Colors.blue.shade900
                    : text == 'Warning'
                        ? Colors.amber.shade700
                        : Colors.red.shade700
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        elevation: 0,
        color: text == 'Casual'
            ? Colors.blue.shade100
            : text == 'Warning'
                ? Colors.amber.shade100
                : Colors.red.shade100,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(20),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                color: text == 'Casual'
                    ? Colors.blue.shade900
                    : text == 'Warning'
                        ? Colors.amber.shade700
                        : Colors.red.shade700,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future sendMessage(BuildContext context) {
    // TODO:
    return showModalBottomSheet(
        context: context,
        builder: (context) {
          return StatefulBuilder(builder: (context, StateSetter setModalState) {
            return Container(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    "Send Message",
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextField(
                    controller: message,
                    decoration: InputDecoration(
                      labelText: "Message",
                      hintText: "Write Message...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                    ),
                  ),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width,
                      child: Consumer<Btn>(
                        builder: (ctx, provider, _) => Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            GestureDetector(
                              onTap: () async {
                                messageType = "Casual";
                                await Provider.of<Btn>(context, listen: false)
                                    .changeBtn();
                              },
                              child: Container(
                                margin: const EdgeInsets.all(5),
                                padding: const EdgeInsets.all(10),
                                child: Text(
                                  "Casual",
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold),
                                ),
                                decoration: BoxDecoration(
                                    border: messageType == "Casual"
                                        ? Border.all(
                                            width: 3, color: Colors.blue)
                                        : Border.all(width: 0),
                                    borderRadius: const BorderRadius.all(
                                        Radius.circular(20)),
                                    color: Colors.blueAccent.withOpacity(0.6)),
                              ),
                            ),
                            GestureDetector(
                              onTap: () async {
                                messageType = "Warning";
                                await Provider.of<Btn>(context, listen: false)
                                    .changeBtn();
                              },
                              child: Container(
                                margin: const EdgeInsets.all(5),
                                padding: const EdgeInsets.all(10),
                                child: Text(
                                  "Warning",
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold),
                                ),
                                decoration: BoxDecoration(
                                    border: messageType == "Warning"
                                        ? Border.all(
                                            width: 3, color: Colors.yellow)
                                        : Border.all(width: 0),
                                    borderRadius: const BorderRadius.all(
                                        Radius.circular(20)),
                                    color:
                                        Colors.yellowAccent.withOpacity(0.6)),
                              ),
                            ),
                            GestureDetector(
                              onTap: () async {
                                messageType = "Critical";
                                await Provider.of<Btn>(context, listen: false)
                                    .changeBtn();
                              },
                              child: Container(
                                margin: const EdgeInsets.all(5),
                                padding: const EdgeInsets.all(10),
                                child: Text(
                                  "Critical",
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold),
                                ),
                                decoration: BoxDecoration(
                                    border: messageType == "Critical"
                                        ? Border.all(
                                            width: 3, color: Colors.red)
                                        : Border.all(width: 0),
                                    borderRadius: const BorderRadius.all(
                                        Radius.circular(20)),
                                    color: Colors.redAccent.withOpacity(0.6)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  MaterialButton(
                    onPressed: () async {
                      if (message.text.trim() != "") {
                        var time = Timestamp.now();
                        await FirebaseFirestore.instance
                            .collection("users")
                            .doc(widget.userId)
                            .collection("messages")
                            .doc(time.toString())
                            .set({
                          "message": message.text,
                          "ts": time,
                          "type": messageType
                        });
                        message.clear();
                        Navigator.pop(context);
                      }
                    },
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5)),
                    color: primaryColor,
                    elevation: 0,
                    padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                    child: Text(
                      "Send",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold),
                    ),
                  )
                ],
              ),
            );
          });
        });
  }

  Future geth() async {
    postStream = await DatabaseMethods().getMyPosts(widget.userName);
    final data = postStream!.map((event) {
      postList = event.docs
          .map((e) => [
                e.id,
                Jiffy(e["ts"].toDate()).format("do-MMMM-yyyy, h:mm:ss a"),
                e["desc"],
                e["url"],
                e["likes"].length.toString(),
                e["comments"].length.toString(),
              ])
          .toList();
    }).toList();
    friendStream = await DatabaseMethods().getFriends(widget.userId);
    final data1 = friendStream!.map((event) {
      friendList = event.docs
          .map((e) => [
                e.id,
                e["email"],
                e["name"],
                e["imgUrl"],
                Jiffy(e["ts"].toDate()).format("do-MMMM-yyyy, h:mm:ss a"),
              ])
          .toList();
    }).toList();
    requestStream = await DatabaseMethods().getRequests(widget.userId);
    final data2 = requestStream!.map((event) {
      requestList = event.docs
          .map((e) => [
                e.id,
                e["email"],
                e["name"],
                e["imgUrl"],
                Jiffy(e["ts"].toDate()).format("do-MMMM-yyyy, h:mm:ss a"),
              ])
          .toList();
    }).toList();
  }

  Future generate_userList() async {
    await geth();
    setState(() {});
    // Excel().createSheet(widget.userName, widget.userId, context, postList);
    if (postList == null || friendList == null || requestList == null) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Oopsy! Try again later",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    //===============CREATE PDF====================
    final headers = [
      'Id',
      'Time',
      'Desc',
      'Post Url',
      'L',
      'C',
    ];
    final headers1 = ['Id', 'Email', 'Name', 'Image Url', 'Time'];
    final pdf = pw.Document();
    pdf.addPage(pw.MultiPage(
        build: (context) => [
              pw.Column(children: [
                pw.Text("User Id: ${widget.userId}    Email: ${widget.email}"),
                pw.Text("Posts",
                    style: pw.TextStyle(
                      fontSize: 30,
                      fontWeight: pw.FontWeight.bold,
                      fontStyle: pw.FontStyle.italic,
                    )),
                pw.Padding(padding: const pw.EdgeInsets.all(10)),
                pw.Table.fromTextArray(
                    headers: headers,
                    data: postList,
                    columnWidths: {
                      0: pw.FlexColumnWidth(2),
                      1: pw.FlexColumnWidth(1),
                      2: pw.FlexColumnWidth(3),
                      3: pw.FlexColumnWidth(3),
                      4: pw.FlexColumnWidth(1),
                      5: pw.FlexColumnWidth(1)
                    },
                    cellStyle: pw.TextStyle(fontSize: 10))
              ])
            ]));

    final pdf1 = pw.Document();
    pdf1.addPage(pw.MultiPage(
        build: (context) => [
              pw.Column(children: [
                pw.Text("User Id: ${widget.userId}    Email: ${widget.email}"),
                pw.Text("Friends",
                    style: pw.TextStyle(
                      fontSize: 30,
                      fontWeight: pw.FontWeight.bold,
                      fontStyle: pw.FontStyle.italic,
                    )),
                pw.Padding(padding: const pw.EdgeInsets.all(10)),
                pw.Table.fromTextArray(
                    headers: headers1,
                    data: friendList,
                    columnWidths: {
                      0: pw.FlexColumnWidth(2),
                      1: pw.FlexColumnWidth(1),
                      2: pw.FlexColumnWidth(2),
                      3: pw.FlexColumnWidth(3),
                      4: pw.FlexColumnWidth(1),
                    },
                    cellStyle: pw.TextStyle(fontSize: 10))
              ])
            ]));

    final pdf2 = pw.Document();
    pdf2.addPage(pw.MultiPage(
        build: (context) => [
              pw.Column(children: [
                pw.Text("User Id: ${widget.userId}    Email: ${widget.email}"),
                pw.Text("Requests",
                    style: pw.TextStyle(
                      fontSize: 30,
                      fontWeight: pw.FontWeight.bold,
                      fontStyle: pw.FontStyle.italic,
                    )),
                pw.Padding(padding: const pw.EdgeInsets.all(10)),
                pw.Table.fromTextArray(
                    headers: headers1,
                    data: requestList,
                    columnWidths: {
                      0: pw.FlexColumnWidth(2),
                      1: pw.FlexColumnWidth(1),
                      2: pw.FlexColumnWidth(2),
                      3: pw.FlexColumnWidth(3),
                      4: pw.FlexColumnWidth(1),
                    },
                    cellStyle: pw.TextStyle(fontSize: 10))
              ])
            ]));
    //===========SAVE PDF==================
    try {
      Directory directory;
      if (await _requestpermission(Permission.storage)) {
        directory = (await getExternalStorageDirectory())!;
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
        newpath = newpath + "/Socialize/UserDetails/${widget.userName}";
        directory = Directory(newpath);

        if (!await directory.exists()) {
          //if directory extracted does not exists, create one
          await directory.create(recursive: true);
        }
        if (await directory.exists()) {
          String filename = DateTime.now().toString();

          File savedfile = File(directory.path + "/Posts_$filename.pdf");
          await savedfile.writeAsBytes(await pdf.save());

          File savedfile1 = File(directory.path + "/Friends_$filename.pdf");
          await savedfile1.writeAsBytes(await pdf1.save());

          File savedfile2 = File(directory.path + "/Requests_$filename.pdf");
          await savedfile2.writeAsBytes(await pdf2.save());

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "File Saved",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Failed. Permission Denied",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print(e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Failed. Some error occured",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

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

  Future onLaunch() async {
    postStream = await DatabaseMethods().getMyPosts(widget.userName);

    friendStream = await DatabaseMethods().getFriends(widget.userId);
    requestStream = await DatabaseMethods().getRequests(widget.userId);
    userStream = await DatabaseMethods().getUserInfo(widget.userName);
    messagesStream = await FirebaseFirestore.instance
        .collection("users")
        .doc(widget.userId)
        .collection("messages")
        .orderBy("ts", descending: true)
        .snapshots();
    setState(() {});
    // final k = postStream?.map((event) {
    //   print("event");
    //   final da = event.docs.map((e) => [e["posted_by"], e["type"]]).toList();
    //   print("object");
    //   print(da);
    // });
    geth();
  }

  @override
  void initState() {
    onLaunch();
    super.initState();
  }

  @override
  void dispose() {
    message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'User Details',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: SvgPicture.asset(
            'lib/assets/image/back.svg',
            color: primaryColor,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: SvgPicture.asset(
              'lib/assets/image/save.svg',
              color: primaryColor,
            ),
            onPressed: () async {
              await generate_userList();
            },
          )
        ],
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: Colors.transparent,
        ),
      ),
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        child: SingleChildScrollView(
          physics: BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          child: Column(
            children: [
              SizedBox(
                  width: MediaQuery.of(context).size.width,
                  child: StreamBuilder(
                    stream: userStream,
                    builder: (context, AsyncSnapshot<QuerySnapshot> snapShot) {
                      if (snapShot.connectionState != ConnectionState.active) {
                        return Center(
                          child: Text("Please check your network"),
                        );
                      }
                      if (snapShot.hasError) {
                        return const Center(
                          child: Text("Error in receiving posts"),
                        );
                      } else if (snapShot.hasData) {
                        DocumentSnapshot ds = snapShot.data!.docs[0];
                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: 20,
                              horizontal: 10,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                CategoryButton(
                                  text: 'Posts',
                                  label: 'Posts',
                                  count: '',
                                  snap: ds,
                                ),
                                CategoryButton(
                                  text: 'Friends',
                                  label: 'Friends',
                                  count: ds['friends'].length.toString(),
                                  snap: ds,
                                ),
                                CategoryButton(
                                  text: 'Requests',
                                  label: 'Requests',
                                  count: ds['requests'].length.toString(),
                                  snap: ds,
                                ),
                                CategoryButton(
                                  text: 'Messages',
                                  label: 'Messages',
                                  count: '',
                                  snap: ds,
                                ),
                              ],
                            ),
                          ),
                        );
                      } else {
                        return Center(
                          child: CircularProgressIndicator(
                            color: primaryColor,
                          ),
                        );
                      }
                    },
                  )

                  //==========================

                  ),
              //=========================================
              screen == "Posts"
                  ? StreamBuilder(
                      stream: postStream,
                      builder:
                          (context, AsyncSnapshot<QuerySnapshot> snapShot) {
                        if (snapShot.connectionState !=
                            ConnectionState.active) {
                          return Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (snapShot.hasError) {
                          return const Center(
                            child: Text("Error in receiving posts"),
                          );
                        } else if (snapShot.hasData) {
                          if (snapShot.data!.docs.isEmpty) {
                            return Center(
                              child: Text(
                                "No Posts",
                                style: TextStyle(
                                  fontSize: 20,
                                  color: Colors.grey.shade400,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          }

                          return Column(
                            children: [
                              Column(
                                children: List.generate(
                                  snapShot.data!.docs.length,
                                  (index) {
                                    DocumentSnapshot ds =
                                        snapShot.data!.docs[index];
                                    return FeedCard(
                                      myUserName: "",
                                      myUserId: "",
                                      myUserImg: "",
                                      myDisplayName: "",
                                      likes: ds["likes"],
                                      comments: ds["comments"],
                                      postType: ds["type"],
                                      caption: ds["desc"],
                                      userImg: ds["userImg"],
                                      userName: ds.id.split("_")[1],
                                      postUrl: ds["url"],
                                      ts: ds["ts"],
                                      postId: ds.id,
                                      posted_by: ds["posted_by"],
                                      userId: ds.id.split("_")[0],
                                    );
                                  },
                                ),
                              ),
                              SizedBox(
                                height: 70,
                              ),
                            ],
                          );
                        } else {
                          return Center(
                            child: CircularProgressIndicator(
                              color: primaryColor,
                            ),
                          );
                        }
                      },
                    )
                  : screen == "Friends"
                      ?
                      //================================================================
                      //==============================================================

                      StreamBuilder(
                          stream: friendStream,
                          builder:
                              (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.active) {
                              if (snapshot.hasData) {
                                if (snapshot.data!.docs.length == 0) {
                                  return const Center(
                                    child: Text("No Friends Available"),
                                  );
                                } else {
                                  return ListView.builder(
                                      itemCount: snapshot.data!.docs.length,
                                      shrinkWrap: true,
                                      padding: EdgeInsets.all(10),
                                      itemBuilder: (context, index) {
                                        DocumentSnapshot ds =
                                            snapshot.data!.docs[index];
                                        return Row(
                                          children: [
                                            Expanded(
                                              child: Container(
                                                margin:
                                                    EdgeInsets.only(bottom: 10),
                                                padding: EdgeInsets.all(10),
                                                decoration: BoxDecoration(
                                                  color: Colors.grey.shade200,
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                width: double.infinity,
                                                child: Row(
                                                  children: [
                                                    Container(
                                                      height: 60,
                                                      width: 60,
                                                      decoration: BoxDecoration(
                                                        color: const Color(
                                                            0xfff2f7fa),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(12),
                                                        border: Border.all(
                                                          color: const Color(
                                                              0xfff2f7fa),
                                                          width: 3.5,
                                                        ),
                                                        image: DecorationImage(
                                                          image: NetworkImage(
                                                              ds["imgUrl"]),
                                                          fit: BoxFit.cover,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(
                                                      width: 12,
                                                    ),
                                                    Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          ds["name"],
                                                          style:
                                                              const TextStyle(
                                                            fontSize: 17,
                                                            fontWeight:
                                                                FontWeight.w900,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          height: 3,
                                                        ),
                                                        Text(
                                                          ds["email"],
                                                          style: TextStyle(
                                                            fontSize: 15,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color: primaryColor,
                                                          ),
                                                        )
                                                      ],
                                                    )
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        );
                                      });
                                }
                              } else {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }
                            } else {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                          })

                      //===================================================================
                      //=================================================================
                      : screen == "Messages"
                          ?
                          //===============================================================
                          StreamBuilder(
                              stream: messagesStream,
                              builder: (context,
                                  AsyncSnapshot<QuerySnapshot> snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.active) {
                                  if (snapshot.hasData) {
                                    if (snapshot.data!.docs.length == 0) {
                                      return const Center(
                                        child: Text("No Messages Sent"),
                                      );
                                    } else {
                                      return ListView.builder(
                                        itemCount: snapshot.data!.docs.length,
                                        shrinkWrap: true,
                                        itemBuilder: (context, index) {
                                          DocumentSnapshot ds =
                                              snapshot.data!.docs[index];
                                          return NotificationBox(context, ds);
                                        },
                                      );
                                    }
                                  } else {
                                    return const Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  }
                                } else {
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                }
                              })
                          //===============================================================
                          //==============================================================
                          : StreamBuilder(
                              stream: requestStream,
                              builder: (context,
                                  AsyncSnapshot<QuerySnapshot> snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.active) {
                                  if (snapshot.hasData) {
                                    if (snapshot.data!.docs.length == 0) {
                                      return const Center(
                                        child: Text("No Requests Available"),
                                      );
                                    } else {
                                      return ListView.builder(
                                          itemCount: snapshot.data!.docs.length,
                                          shrinkWrap: true,
                                          physics:
                                              NeverScrollableScrollPhysics(),
                                          itemBuilder: (context, index) {
                                            DocumentSnapshot ds =
                                                snapshot.data!.docs[index];
                                            return Row(
                                              children: [
                                                Expanded(
                                                  child: MaterialButton(
                                                    onPressed: () {
                                                      // do nothing
                                                    },
                                                    child: Container(
                                                      padding:
                                                          EdgeInsets.all(10),
                                                      decoration: BoxDecoration(
                                                        color: Colors
                                                            .grey.shade200,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(10),
                                                      ),
                                                      width: double.infinity,
                                                      child: Row(
                                                        children: [
                                                          Container(
                                                            height: 60,
                                                            width: 60,
                                                            decoration:
                                                                BoxDecoration(
                                                              color: Color(
                                                                  0xfff2f7fa),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          12),
                                                              border:
                                                                  Border.all(
                                                                color: Color(
                                                                    0xfff2f7fa),
                                                                width: 3.5,
                                                              ),
                                                              image:
                                                                  DecorationImage(
                                                                image: NetworkImage(
                                                                    ds["imgUrl"]),
                                                                fit: BoxFit
                                                                    .cover,
                                                              ),
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            width: 12,
                                                          ),
                                                          Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Text(
                                                                ds["name"],
                                                                style:
                                                                    const TextStyle(
                                                                  fontSize: 17,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
                                                              ),
                                                              const SizedBox(
                                                                height: 3,
                                                              ),
                                                              Text(
                                                                ds["email"],
                                                                style:
                                                                    TextStyle(
                                                                  fontSize: 16,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  color:
                                                                      primaryColor,
                                                                ),
                                                              )
                                                            ],
                                                          )
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            );
                                          });
                                    }
                                  } else {
                                    return const Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  }
                                } else {
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                }
                              },
                            ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'btn1',
        onPressed: () {
          // sendMessage(context);
          showModalBottomSheet(
            context: context,
            enableDrag: true,
            isScrollControlled: true,
            builder: (context) {
              return SendMessage(context);
            },
          );
        },
        icon: SvgPicture.asset(
          'lib/assets/image/send.svg',
          height: 17,
        ),
        elevation: 2,
        label: Text(
          "Send Message",
          style: TextStyle(
            // color: Colors.white,
            fontWeight: FontWeight.w600,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                timeago.format(ds["ts"].toDate()),
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              GestureDetector(
                onTap: () async {
                  await FirebaseFirestore.instance
                      .collection("users")
                      .doc(widget.userId)
                      .collection("messages")
                      .doc(ds.id)
                      .delete();
                },
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.red.shade700,
                  child: Icon(
                    Icons.delete,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
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

  Widget CategoryButton({final text, label, count, snap}) {
    return Padding(
      padding: EdgeInsets.only(right: 10),
      child: MaterialButton(
        onPressed: () {
          setState(() {
            screen = label;
          });
        },
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          // side: BorderSide(
          //   color: screen == label ? Colors.transparent : primaryColor,
          // ),
        ),
        padding: EdgeInsets.symmetric(vertical: 15, horizontal: 10),
        color: screen == label ? primaryColor : Colors.white,
        elevation: screen == label ? 2 : 0,
        child: Row(
          children: [
            Text(
              text,
              style: TextStyle(
                color: screen == label ? Colors.white : Colors.black,
              ),
            ),
            count == ''
                ? Container()
                : Padding(
                    padding: EdgeInsets.only(left: 5),
                    child: CircleAvatar(
                      radius: 10,
                      backgroundColor: Colors.grey.shade100,
                      child: Text(
                        count,
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
            label == 'Posts'
                ? StreamBuilder<dynamic>(
                    stream: FirebaseFirestore.instance
                        .collection('posts')
                        .where('posted_by', isEqualTo: snap['username'])
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return Padding(
                          padding: EdgeInsets.only(left: 5),
                          child: CircleAvatar(
                            radius: 10,
                            backgroundColor: Colors.grey.shade100,
                            child: Text(
                              snapshot.data.docs.length.toString(),
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        );
                      }
                      return CircleAvatar(
                        radius: 10,
                        backgroundColor: Colors.grey.shade100,
                        child: CircularProgressIndicator(
                          color: primaryColor,
                        ),
                      );
                    },
                  )
                : Container(),
          ],
        ),
      ),
    );
  }
}
