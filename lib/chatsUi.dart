import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:jiffy/jiffy.dart';
import 'package:page_route_transition/page_route_transition.dart';
import '/colors.dart';
import '/services/database.dart';

import 'chatScreen.dart';
import 'groupChat.dart';
import 'services/story_widgets.dart';

class ChatsUi extends StatefulWidget {
  // const ChatsUi({Key? key}) : super(key: key);
  final myUserName;
  final myUserId;
  final myProfilePic;
  ChatsUi(
      {required this.myUserName,
      required this.myUserId,
      required this.myProfilePic});
  @override
  _ChatsUiState createState() => _ChatsUiState();
}

class _ChatsUiState extends State<ChatsUi> {
  Stream<QuerySnapshot>? chatRoomsStream;
  getChatRooms() async {
    chatRoomsStream = await DatabaseMethods().getChatRooms(widget.myUserName);
    setState(() {});
  }

  onScreenLoading() async {
    await getChatRooms();
  }

  @override
  void initState() {
    onScreenLoading();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          margin: EdgeInsets.only(top: 10),
          padding: EdgeInsets.all(20),
          width: double.infinity,
          color: Colors.white,
          child: Text(
            'Chats',
            style: TextStyle(
              color: Colors.blueGrey.shade700,
              fontWeight: FontWeight.w700,
              fontSize: 17,
            ),
          ),
        ),
        Expanded(
          child: Container(
            margin: EdgeInsets.symmetric(vertical: 10),
            padding: EdgeInsets.all(10),
            width: double.infinity,
            color: Colors.white,
            child: SingleChildScrollView(
              physics: BouncingScrollPhysics(),
              child: Column(
                children: [
                  StreamBuilder(
                    stream: chatRoomsStream,
                    builder: (context, AsyncSnapshot<QuerySnapshot> snapShots) {
                      if (snapShots.hasError) {
                        return Center(
                          child: Text(
                            "Error",
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        );
                      } else if (snapShots.connectionState ==
                          ConnectionState.waiting) {
                        return CustomProgress();
                      } else if (snapShots.connectionState ==
                          ConnectionState.active) {
                        if (snapShots.hasData) {
                          if (snapShots.data!.docs.length == 0) {
                            return Center(
                              child: Text(
                                'No Chats Here: Add Friends to chat with them',
                                style: TextStyle(
                                  color: Colors.blueGrey.shade200,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            );
                          }
                          return ListView.builder(
                              itemCount: snapShots.data!.docs.length,
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              itemBuilder: (context, index) {
                                QueryDocumentSnapshot s =
                                    snapShots.data!.docs[index];
                                return ChatRoomListTile(
                                  s["lastMessage"],
                                  s["lastMessageSendTs"],
                                  s.id,
                                  widget.myUserName,
                                  s.id.split('_').length == 2
                                      ? s["users"][0] == widget.myUserName
                                          ? s["displayNames"][1]
                                          : s["displayNames"][0]
                                      : s["displayName"],
                                  s.id.split('_').length == 2
                                      ? s["users"][0] == widget.myUserName
                                          ? s["profileUrls"][1]
                                          : s["profileUrls"][0]
                                      : s["profileUrl"],
                                );
                              });
                        } else {
                          return CustomProgress();
                        }
                      } else {
                        return Text(
                          "${snapShots.connectionState.toString()}",
                        );
                      }
                    },
                  )
                ],
              ),
            ),
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade200,
                spreadRadius: 5,
                blurRadius: 25,
              ),
            ],
          ),
          child: MaterialButton(
            onPressed: () {
              // Navigator.of(context).push(MaterialPageRoute(
              //     builder: (context) =>
              //         GroupChat(widget.myUserName, widget.myProfilePic)));

              PageRouteTransition.push(
                context,
                GroupChat(widget.myUserName, widget.myProfilePic),
              );
            },
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
            color: primaryColor,
            elevation: 0,
            highlightElevation: 0,
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 15),
              width: double.infinity,
              child: const Center(
                child: Text(
                  'Create Group',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class ChatRoomListTile extends StatefulWidget {
  String lastMessage;
  Timestamp lastMessageSendTs;
  String chatRoomId, myUserName, name, profileUrl;
  ChatRoomListTile(
    this.lastMessage,
    this.lastMessageSendTs,
    this.chatRoomId,
    this.myUserName,
    this.name,
    this.profileUrl,
  );
  @override
  _ChatRoomListTileState createState() => _ChatRoomListTileState();
}

class _ChatRoomListTileState extends State<ChatRoomListTile> {
  @override
  Widget build(BuildContext context) {
    return widget.profileUrl != ""
        ? InkWell(
            onTap: () {
              PageRouteTransition.push(
                context,
                ChatScreen(widget.name, widget.profileUrl, widget.chatRoomId),
              );
            },
            child: Container(
              width: MediaQuery.of(context).size.width,
              padding: EdgeInsets.all(10),
              margin: EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.blueGrey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(40),
                        child: Image.network(
                          widget.profileUrl,
                          height: 50,
                          width: 50,
                        ),
                      ),
                      SizedBox(
                        width: 12,
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: MediaQuery.of(context).size.width * 0.43,
                            child: Text(
                              widget.name,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 5,
                          ),
                          Container(
                            width: MediaQuery.of(context).size.width * 0.43,
                            child: RichText(
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              text: TextSpan(
                                text: widget.lastMessage,
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade600,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                  Container(
                    child: widget.lastMessageSendTs
                                .toDate()
                                .add(Duration(hours: 24))
                                .compareTo(DateTime.now()) <
                            0
                        ? Text(
                            Jiffy(widget.lastMessageSendTs.toDate())
                                .format('do MMM'),
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          )
                        : Text(
                            Jiffy(widget.lastMessageSendTs.toDate())
                                .format('h:mm a'),
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                  )
                ],
              ),
            ),
          )
        : Container();
  }
}
