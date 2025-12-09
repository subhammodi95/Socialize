// ignore_for_file: file_names

import 'dart:io';

import 'package:flutter_svg/flutter_svg.dart';
import 'package:social_media_app/colors.dart';

import './services/database.dart';
import './services/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'services/database.dart';
import 'services/story_widgets.dart';

List<String> groupList = [];
List<String> groupListImg = [];

class GroupChat extends StatefulWidget {
  String myUserName, myProfilePic;
  GroupChat(this.myUserName, this.myProfilePic);

  @override
  _GroupChatState createState() => _GroupChatState();
}

class _GroupChatState extends State<GroupChat> {
  TextEditingController groupName = TextEditingController();
  Stream<QuerySnapshot>? chatRoomsStream;
  late FocusNode myfocusNode;
  late var pickImageFile;
  var image;

  void _pickImage() async {
    pickImageFile = (await ImagePicker().pickImage(
        source: ImageSource.gallery, imageQuality: 50, maxWidth: 250))!;
    if (pickImageFile != null) {
      image = File(pickImageFile.path);
    }
    setState(() {
      // FocusScope.of(context).requestFocus(FocusNode());
      // myfocusNode.requestFocus();
    });
  }

  createGroup(List groupList) {
    Map<String, dynamic> chatRoomInfoMap = {
      "users": groupList,
    };

    showModalBottomSheet(
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
        top: Radius.circular(25.0),
      )),
      isScrollControlled: true,
      context: context,
      builder: (_) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 5),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: EdgeInsets.symmetric(vertical: 10),
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  color: Colors.grey.withOpacity(0.4),
                ),
              ),
              SizedBox(
                height: 30,
              ),
              Text(
                "New Group",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              Container(
                margin: EdgeInsets.symmetric(vertical: 20, horizontal: 8),
                padding: EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          child: image != null
                              ? CircleAvatar(
                                  radius: 30,
                                  backgroundImage: FileImage(image),
                                )
                              : Icon(Icons.image),
                          onTap: () {
                            _pickImage();
                          },
                        ),
                        SizedBox(
                          width: 10,
                        ),
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: TextField(
                              controller: groupName,
                              focusNode: myfocusNode,
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                labelText: 'Name',
                                labelStyle: TextStyle(
                                  fontSize: 20,
                                  color: Theme.of(context).primaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                                icon: Icon(Icons.person),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    Consumer<updateRowList>(
                      builder: (ctx, provider, _) => Container(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Participants: ${groupList.length}",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontStyle: FontStyle.italic),
                            ),
                            SingleChildScrollView(
                              physics: BouncingScrollPhysics(
                                  parent: AlwaysScrollableScrollPhysics()),
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children:
                                    List.generate(groupListImg.length, (index) {
                                  return Padding(
                                    padding: EdgeInsets.all(10.0),
                                    child: Stack(
                                        alignment: Alignment.bottomRight,
                                        children: [
                                          ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(40),
                                              child: Image.network(
                                                groupListImg[index],
                                                height: 50,
                                                width: 50,
                                              )),
                                          groupList[index] != widget.myUserName
                                              ? Positioned(
                                                  child: GestureDetector(
                                                  child: Icon(
                                                    Icons.remove_circle,
                                                    color: Colors.red,
                                                  ),
                                                  onTap: () async {
                                                    // if (groupList.length > 3) {
                                                    groupListImg
                                                        .removeAt(index);
                                                    groupList.removeAt(index);
                                                    await Provider.of<
                                                                updateRowList>(
                                                            context,
                                                            listen: false)
                                                        .updateList();
                                                    setState(() {});
                                                    // }
                                                  },
                                                ))
                                              : Container()
                                        ]),
                                  );
                                }),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    MaterialButton(
                      onPressed: () async {
                        if (groupList.length < 3) {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(
                              "Group should have atleast 3 members",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15),
                            ),
                            backgroundColor: Colors.red,
                          ));
                          return;
                        }
                        if (groupName.text.contains('_')) {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(
                              "Group name should not contain underscores",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15),
                            ),
                            backgroundColor: Colors.red,
                          ));
                          return;
                        }
                        if (groupName.text.isNotEmpty &&
                            groupList.length > 2 &&
                            pickImageFile != null) {
                          DatabaseMethods()
                              .createGroupChatRoom(
                                  "group\_${widget.myUserName}\_${groupName.text}",
                                  chatRoomInfoMap)
                              .then((value) async {
                            if (value == false) {
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(SnackBar(
                                content: Text(
                                  "Group with same name already exist",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15),
                                ),
                                backgroundColor: Colors.red,
                              ));
                            } else {
                              await DatabaseMethods()
                                  .uploadGroupImg(File(pickImageFile.path),
                                      "group\_${widget.myUserName}\_${groupName.text}")
                                  .then((imgUrl) {
                                Map<String, dynamic> lastMessageInfoMap = {
                                  "lastMessage": "Welcome Everyone",
                                  "lastMessageId": "",
                                  "profileUrl": imgUrl,
                                  "displayName": groupName.text,
                                  "lastMessageSendTs": DateTime.now(),
                                  "lastMessageSendBy": widget.myUserName
                                };
                                image = null;
                                pickImageFile = null;
                                DatabaseMethods().updateLastMessageSend(
                                    "group\_${widget.myUserName}\_${groupName.text}",
                                    lastMessageInfoMap);
                                setState(() {});
                              });

                              Navigator.of(context).pop();
                              groupList.clear();
                              groupList.add(widget.myUserName);
                              groupListImg.clear();
                              groupListImg.add(widget.myProfilePic);
                              setState(() {});
                            }
                          });
                        }
                      },
                      color: Theme.of(context).primaryColor,
                      elevation: 0,
                      highlightColor: Colors.red.withOpacity(0.3),
                      highlightElevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Container(
                        padding: EdgeInsets.all(10),
                        width: double.infinity,
                        child: Center(
                          child: Text(
                            "Create",
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 30,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget chatRoomsList() {
    return StreamBuilder(
      stream: chatRoomsStream,
      builder: (context, AsyncSnapshot<QuerySnapshot> snapShots) {
        return snapShots.hasData
            ? ListView.builder(
                itemCount: snapShots.data!.docs.length,
                shrinkWrap: true,
                itemBuilder: (context, index) {
                  DocumentSnapshot ds = snapShots.data!.docs[index];
                  return ds.id.toString().split('_').length == 2
                      ? ChatRoomListTile(
                          ds["lastMessageSendTs"],
                          ds.id,
                          widget.myUserName,
                        )
                      : Container();
                },
              )
            : CustomProgress();
      },
    );
  }

  onLoading() async {
    myfocusNode = FocusNode();
    groupList.clear();
    groupListImg.clear();
    groupList.add(widget.myUserName);
    groupListImg.add(widget.myProfilePic);
    chatRoomsStream = await DatabaseMethods().getChatRooms(widget.myUserName);
    setState(() {});
  }

  @override
  void initState() {
    onLoading();
    super.initState();
  }

  @override
  void dispose() {
    myfocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: SvgPicture.asset(
            'lib/assets/image/back.svg',
            color: Colors.white,
          ),
        ),
        title: Text(
          "Create Group",
          style: TextStyle(
            fontSize: 18,
            color: primaryScaffoldColor,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        child: SingleChildScrollView(
          physics: BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          child: chatRoomsList(),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(
          Icons.arrow_forward_ios,
          color: primaryScaffoldColor,
          size: 15,
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        highlightElevation: 0,
        onPressed: () {
          // groupList.sort((a, b) => a
          //     .substring(0, 1)
          //     .codeUnitAt(0)
          //     .compareTo(b.substring(0, 1).codeUnitAt(0)));
          if (groupList.length < 3) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              dismissDirection: DismissDirection.horizontal,
              behavior: SnackBarBehavior.floating,
              elevation: 0,
              content: Text(
                "A group should have atleast 3 members",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              backgroundColor: Colors.red,
            ));
          } else {
            createGroup(groupList);
          }
        },
      ),
    );
  }
}

class ChatRoomListTile extends StatefulWidget {
  Timestamp lastMessageTs;
  String chatRoomId, myUserName;
  ChatRoomListTile(
    this.lastMessageTs,
    this.chatRoomId,
    this.myUserName,
  );
  @override
  _ChatRoomListTileState createState() => _ChatRoomListTileState();
}

class _ChatRoomListTileState extends State<ChatRoomListTile> {
  String profilePicUrl = "", name = "", email = "", username = "";
  getThisUserInfo() async {
    username =
        widget.chatRoomId.replaceAll(widget.myUserName, "").replaceAll("_", "");
    QuerySnapshot querySnapshot =
        await DatabaseMethods().getUserInfo2(username);
    name = "${querySnapshot.docs[0]["name"]}";
    profilePicUrl = "${querySnapshot.docs[0]["imgUrl"]}";
    email = "${querySnapshot.docs[0]["email"]}";
    setState(() {});
  }

  @override
  void initState() {
    getThisUserInfo();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return profilePicUrl != ""
        ? InkWell(
            onTap: () {
              if (groupList.contains(username)) {
                groupList.remove(username);
                groupListImg.remove(profilePicUrl);
              } else {
                groupList.add(username);
                groupListImg.add(profilePicUrl);
              }
              setState(() {});
            },
            child: Container(
              width: MediaQuery.of(context).size.width,
              // margin: EdgeInsets.only(bottom: 10),
              padding: EdgeInsets.all(20),
              color: groupList.contains(username)
                  ? Colors.blue.withOpacity(0.4)
                  : Colors.transparent,
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      height: 50,
                      width: 50,
                      color: Colors.grey.shade300,
                      child: Image.network(
                        profilePicUrl,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 15,
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(
                        height: 5,
                      ),
                      Text(
                        email,
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          )
        : Container();
  }
}
