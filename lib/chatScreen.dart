import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '/colors.dart';

import './services/database.dart';
import './services/provider.dart';
import './services/sharedPref_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:random_string/random_string.dart';
import 'package:provider/provider.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';

import 'services/story_widgets.dart';

class ChatScreen extends StatefulWidget {
  final String name, profilePicUrl, chatRoomId;
  ChatScreen(this.name, this.profilePicUrl, this.chatRoomId);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  String messageId = "";
  Stream<QuerySnapshot>? messageStream, statusStream;
  String myName = "", myProfilePic = "", myUserName = "", myEmail = "";
  Map<String, dynamic> lastMessageInfoMap = {};
  String names = "";
  String phoneNumber = "";
  String active = "";
  TextEditingController messageTextEditingController = TextEditingController();

  // ScrollController _listScrollController = ScrollController();

  getMyInfoFromSharedPref() async {
    myName = (await SharedPreferenceHelper().getDisplayName())!;
    myProfilePic = (await SharedPreferenceHelper().getUserProfileUrl())!;
    myUserName = (await SharedPreferenceHelper().getUserName())!;
    myEmail = (await SharedPreferenceHelper().getUserEmail())!;
  }

  addMessage(bool sendClicked) {
    if (messageTextEditingController.text.trim() != "") {
      String message = messageTextEditingController.text;

      var lastMessageTs = DateTime.now();

      Map<String, dynamic> messageInfoMap = {
        "message": message,
        "sendBy": myUserName,
        "name": myName,
        "ts": lastMessageTs,
        "imgUrl": myProfilePic
      };

      //message id
      if (messageId == "") {
        messageId = randomAlphaNumeric(12);
      }

      DatabaseMethods()
          .addMessage(widget.chatRoomId, messageId, messageInfoMap)
          .then((value) {
        if (widget.chatRoomId.split('_').length == 2) {
          lastMessageInfoMap = {
            "lastMessage": message,
            "lastMessageId": messageId,
            "lastMessageSendTs": lastMessageTs,
            "lastMessageSendBy": myUserName
          };
        } else {
          lastMessageInfoMap = {
            "lastMessage": message,
            "lastMessageId": messageId,
            "profileUrl": widget.profilePicUrl,
            "displayName": widget.name,
            "lastMessageSendTs": lastMessageTs,
            "lastMessageSendBy": myUserName
          };
        }
        DatabaseMethods()
            .updateLastMessageSend(widget.chatRoomId, lastMessageInfoMap);

        if (sendClicked) {
          //delete if empty message was sent
          if (messageTextEditingController.text.trim().isEmpty) {
            DatabaseMethods().deleteThisMessage(widget.chatRoomId, messageId);
          }
          messageTextEditingController.text = "";
          //make message id blank to get regenerated on next message send
          messageId = "";
        }
      });
    } else {
      messageId = "";
    }
  }

  Widget chatMessageTile(
    String message,
    bool sendByMe,
    String id,
    String name,
    String imgUrl,
  ) {
    // if (sendByMe) {
    //   name = "You";
    // }
    return Dismissible(
      key: UniqueKey(),
      background: Container(
        alignment: sendByMe ? Alignment.centerRight : Alignment.centerLeft,
        child: sendByMe
            ? Padding(
                padding: EdgeInsets.only(right: 40),
                child: Icon(
                  Icons.delete,
                  color: Colors.red,
                  size: 30,
                ),
              )
            : Padding(
                padding: EdgeInsets.only(left: 40),
                child: Icon(
                  Icons.delete,
                  color: Colors.red,
                  size: 30,
                ),
              ),
      ),
      child: Column(
        crossAxisAlignment:
            sendByMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            alignment: sendByMe ? Alignment.topRight : Alignment.topLeft,
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  bottomRight:
                      sendByMe ? Radius.circular(0) : Radius.circular(24),
                  topRight: Radius.circular(24),
                  bottomLeft:
                      sendByMe ? Radius.circular(24) : Radius.circular(0),
                ),
                color: sendByMe ? primaryColor : primaryColor.withOpacity(0.2),
              ),
              child: Column(
                crossAxisAlignment: sendByMe
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  // widget.chatRoomId.split('_').length != 2
                  //     ? Text(
                  //         name,
                  //         style: TextStyle(
                  //           fontWeight: FontWeight.bold,
                  //           fontSize: 15,
                  //           color: Colors.purple,
                  //         ),
                  //       )
                  //     : Container(),
                  Text(
                    message,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: sendByMe ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
          widget.chatRoomId.split('_').length != 2
              ? Text(
                  name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Colors.purple,
                  ),
                )
              : Container(),
        ],
      ),
      onDismissed: (direction) async {
        DocumentSnapshot s =
            await DatabaseMethods().getChatRoomInfo(widget.chatRoomId);
        await DatabaseMethods()
            .deleteThisMessage(widget.chatRoomId, id)
            .then((value) {
          if (s["lastMessageId"] == id) {
            Map<String, dynamic> lastMessageInfoMap = {
              "lastMessage": "Message Deleted",
              "lastMessageId": "",
              "lastMessageSendTs": DateTime.now(),
              "lastMessageSendBy": myUserName
            };

            DatabaseMethods()
                .updateLastMessageSend(widget.chatRoomId, lastMessageInfoMap);
          }
        });
      },
    );
  }

  Widget chatMessages() {
    return StreamBuilder(
      stream: messageStream,
      builder: (context, AsyncSnapshot<QuerySnapshot> snapShot) {
        // SchedulerBinding.instance.addPostFrameCallback((_) {
        //   _listScrollController.animateTo(
        //       _listScrollController.position.minScrollExtent,
        //       duration: Duration(milliseconds: 250),
        //       curve: Curves.easeInOut);
        // });
        return snapShot.hasData
            ? ListView.builder(
                itemCount: snapShot.data!.docs.length,
                reverse: true,
                shrinkWrap: true,
                // controller: _listScrollController,
                itemBuilder: (context, index) {
                  DocumentSnapshot ds = snapShot.data!.docs[index];
                  return chatMessageTile(
                    ds["message"],
                    myUserName == ds["sendBy"],
                    ds.id,
                    ds["name"],
                    ds["imgUrl"],
                  );
                },
              )
            : CustomProgress();
      },
    );
  }

  getAndSetMessages() async {
    messageStream =
        await DatabaseMethods().getChatRoomMessages(widget.chatRoomId);
    statusStream = await FirebaseFirestore.instance
        .collection("users")
        .where("username",
            isEqualTo: widget.chatRoomId
                .replaceAll('_', '')
                .replaceAll(myUserName, ''))
        .snapshots();
    if (widget.chatRoomId.split('_').length != 2) {
      names = await DatabaseMethods().getGroupMembers(widget.chatRoomId);
    } else {
      QuerySnapshot snapshot = await DatabaseMethods().getUserInfo2(
          widget.chatRoomId.replaceAll('_', '').replaceAll(myUserName, ''));
      phoneNumber = "${snapshot.docs[0]["phone"]}";
    }

    setState(() {});
  }

  doThisOnLaunch() async {
    await getMyInfoFromSharedPref();

    getAndSetMessages();
  }

  @override
  void initState() {
    doThisOnLaunch();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle.dark.copyWith(
        statusBarBrightness: Brightness.dark,
        statusBarIconBrightness: Brightness.light,
        statusBarColor: primaryColor,
        systemNavigationBarColor: primaryScaffoldColor,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        // leading:
        automaticallyImplyLeading: false,

        // IconButton(
        //   padding: EdgeInsets.all(0),
        //   onPressed: () {
        //     Navigator.pop(context);
        //   },
        //   icon: SvgPicture.asset(
        //     'lib/assets/image/back.svg',
        //     color: primaryScaffoldColor,
        //   ),
        // ),
        elevation: 0,
        actions: [
          widget.chatRoomId.split('_').length == 2
              ? Padding(
                  padding: EdgeInsets.all(15.0),
                  child: InkWell(
                    child: SvgPicture.asset(
                      phoneNumber == "" || phoneNumber == null
                          ? 'lib/assets/image/noCall.svg'
                          : 'lib/assets/image/call.svg',
                      color: phoneNumber == ""
                          ? Colors.white60
                          : primaryScaffoldColor,
                      height: 19,
                    ),
                    onTap: () async {
                      if (phoneNumber != "" && phoneNumber != null) {
                        await FlutterPhoneDirectCaller.callNumber(phoneNumber);
                      }
                    },
                  ),
                )
              : Container()
        ],
        leading: IconButton(
          padding: EdgeInsets.all(0),
          onPressed: () {
            Navigator.pop(context);
          },
          icon: SvgPicture.asset(
            'lib/assets/image/back.svg',
            color: Colors.white,
          ),
        ),
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(40),
              child: Image.network(
                widget.profilePicUrl,
                height: 40,
                width: 40,
              ),
            ),
            SizedBox(
              width: 10,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.name,
                  style: TextStyle(
                    color: primaryScaffoldColor,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(
                  height: 4,
                ),
                names != ""
                    ? SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Text(
                          names,
                          style: TextStyle(
                            fontSize: 10,
                            color: primaryScaffoldColor,
                          ),
                        ),
                      )
                    : StreamBuilder(
                        stream: statusStream,
                        builder:
                            (context, AsyncSnapshot<QuerySnapshot> snapShot) {
                          if (snapShot.connectionState ==
                              ConnectionState.active) {
                            if (snapShot.hasData) {
                              DocumentSnapshot ds = snapShot.data!.docs[0];
                              return ds["active"] == "1"
                                  ? Row(
                                      children: [
                                        CircleAvatar(
                                          backgroundColor:
                                              Colors.green.shade300,
                                          radius: 5,
                                        ),
                                        SizedBox(
                                          width: 5,
                                        ),
                                        Text(
                                          "ONLINE",
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    )
                                  : Row(
                                      children: [
                                        CircleAvatar(
                                          backgroundColor: Colors.red.shade100,
                                          radius: 5,
                                        ),
                                        SizedBox(
                                          width: 5,
                                        ),
                                        Text(
                                          "OFFLINE",
                                          style: TextStyle(
                                            fontSize: 13,
                                            color:
                                                Colors.white.withOpacity(0.7),
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    );
                            } else {
                              return Container();
                            }
                          } else {
                            return Container();
                          }
                        },
                      ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        //wrap with container if error
        children: [
          Expanded(
            child: chatMessages(),
          ),
          Container(
            margin: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
            alignment: Alignment.bottomCenter,
            child: Row(
              children: [
                Flexible(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.white,
                    ),
                    child: TextField(
                      controller: messageTextEditingController,
                      onSubmitted: (value) async {
                        await Provider.of<Btn>(context, listen: false)
                            .changeBtn();
                        addMessage(false);
                      },
                      style: TextStyle(
                        color: Colors.black,
                      ),
                      maxLines: 3,
                      minLines: 1,
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.all(10),
                        border: InputBorder.none,
                        hintText: "Type a message...",
                        hintStyle: TextStyle(
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 10,
                ),
                GestureDetector(
                  onTap: () async {
                    addMessage(true);

                    await Provider.of<Btn>(context, listen: false).changeBtn();
                  },
                  child: CircleAvatar(
                    backgroundColor: primaryColor,
                    radius: 23,
                    child: Consumer<Btn>(
                      builder: (ctx, provider, _) =>
                          // Icon(
                          //   Icons.send,
                          //   color: messageTextEditingController.text.isEmpty
                          //       ? Colors.grey
                          //       : Colors.white,
                          // ),
                          SvgPicture.asset(
                        'lib/assets/image/send.svg',
                        height: 17,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
