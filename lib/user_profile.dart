import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:social_media_app/home.dart';
import '/colors.dart';
import '/othersFriendList.dart';
import '/services/database.dart';
import '/services/sharedPref_helper.dart';

import 'feeds.dart';
import 'services/story_widgets.dart';

class UserProfile extends StatefulWidget {
  // const UserProfile({Key key}) : super(key: key);
  final userId;
  final userName;
  final myUserName;
  final myUserId;
  final myImgUrl;
  final myDisplayName;
  // var myFriendList;
  // var myRequestList;
  UserProfile(
      {required this.userName,
      required this.myUserName,
      required this.userId,
      required this.myDisplayName,
      // required this.myFriendList,
      // required this.myRequestList,
      required this.myImgUrl,
      required this.myUserId});
  @override
  _UserProfileState createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfile> {
  Stream<QuerySnapshot>? userProfileStream, postsStream, myRequestCollection;
  String email = "", myEmail = "";
  String tokenId = "";
  bool loading = false;

  Future manageRequest(String operation) async {
    QuerySnapshot userdetails =
        await DatabaseMethods().getUserInfo2(widget.userName);
    List<dynamic> requests = userdetails.docs[0]["requests"];
    List requestList = await requests.toList();
    if (operation == "delete") {
      requestList.remove(widget.myUserName);
      await DatabaseMethods().updateRequest(widget.userId, requestList);
      await DatabaseMethods().updateRequestCollection(
          widget.userId, "delete", widget.myUserId, "", "", "", "");
      DatabaseMethods().sendNotification(
          [tokenId],
          "${widget.myDisplayName} unsent you the friend request",
          "Heyy",
          widget.myImgUrl);
    } else {
      requestList.add(widget.myUserName);
      await DatabaseMethods().updateRequest(widget.userId, requestList);
      await DatabaseMethods().updateRequestCollection(
          widget.userId,
          "add",
          widget.myUserId,
          widget.myImgUrl,
          widget.myDisplayName,
          widget.myUserName,
          myEmail);
      DatabaseMethods().sendNotification(
          [tokenId],
          "${widget.myDisplayName} sent you a friend request",
          "Heyy",
          widget.myImgUrl);
    }
    loading = false;
    setState(() {});
  }

  Future deleteFriend() async {
    QuerySnapshot userdetails =
        await DatabaseMethods().getUserInfo2(widget.userName);
    List<dynamic> friends = userdetails.docs[0]["friends"];
    List friendList = await friends.toList();
    friendList.remove(widget.myUserName);
    await DatabaseMethods().updateFriends(widget.userId, friendList);
    await DatabaseMethods().updateFriendsCollection(
        widget.userId, "delete", widget.myUserId, "", "", "", "");

    QuerySnapshot myuserdetails =
        await DatabaseMethods().getUserInfo2(widget.myUserName);
    List<dynamic> myFriends = myuserdetails.docs[0]["friends"];

    List myFriendList = await myFriends.toList();
    myFriendList.remove(widget.userName);

    await DatabaseMethods().updateFriends(widget.myUserId, myFriendList);
    await DatabaseMethods().updateFriendsCollection(
        widget.myUserId, "delete", widget.userId, "", "", "", "");
    var chatRoomId =
        getChatRoomIdByUsernames(widget.myUserName, widget.userName);
    await DatabaseMethods().deleteChatRoom(chatRoomId);

    DatabaseMethods().sendNotification(
        [tokenId],
        "${widget.myDisplayName} removed you from his friend list",
        "Heyy",
        widget.myImgUrl);

    loading = false;
    setState(() {});
  }

  Future accept(String userImg, String displayName) async {
    QuerySnapshot userdetails =
        await DatabaseMethods().getUserInfo2(widget.userName);
    List<dynamic> friends = userdetails.docs[0]["friends"];
    await decline("1");
    List friendList = await friends.toList();
    friendList.add(widget.myUserName);
    await DatabaseMethods().updateFriends(widget.userId, friendList);
    await DatabaseMethods().updateFriendsCollection(
        widget.userId,
        "add",
        widget.myUserId,
        widget.myImgUrl,
        widget.myDisplayName,
        widget.myUserName,
        myEmail);

    QuerySnapshot myuserdetails =
        await DatabaseMethods().getUserInfo2(widget.myUserName);
    List<dynamic> myFriends = myuserdetails.docs[0]["friends"];

    List myFriendList = await myFriends.toList();
    myFriendList.add(widget.userName);

    await DatabaseMethods().updateFriends(widget.myUserId, myFriendList);
    await DatabaseMethods().updateFriendsCollection(widget.myUserId, "add",
        widget.userId, userImg, displayName, widget.userName, email);
    var chatRoomId =
        getChatRoomIdByUsernames(widget.myUserName, widget.userName);
    Map<String, dynamic> chatRoomInfoMap = {
      "users": [widget.myUserName, widget.userName],
      'profileUrls': [widget.myImgUrl, userImg],
      'lastMessage': "Send message now..",
      'lastMessageId': "",
      'lastMessageSendBy': "",
      'lastMessageSendTs': DateTime.now(),
      'displayNames': [widget.myDisplayName, displayName]
    };

    DatabaseMethods().createChatRoom(chatRoomId, chatRoomInfoMap);

    DatabaseMethods().sendNotification(
        [tokenId],
        "${widget.myDisplayName} accepted your friend request",
        "Heyy",
        widget.myImgUrl);

    loading = false;
    setState(() {});
  }

  Future decline(String stat) async {
    QuerySnapshot myuserdetails =
        await DatabaseMethods().getUserInfo2(widget.myUserName);
    List<dynamic> myRequests = myuserdetails.docs[0]["requests"];
    List myrequestList = await myRequests.toList();
    myrequestList.remove(widget.userName);

    await DatabaseMethods().updateRequest(widget.myUserId, myrequestList);
    await DatabaseMethods().updateRequestCollection(
        widget.myUserId, "delete", widget.userId, "", "", "", "");

    if (stat == "0") {
      DatabaseMethods().sendNotification(
          [tokenId],
          "${widget.myDisplayName} declined your friend request",
          "Heyy",
          widget.myImgUrl);
    }

    loading = false;
    setState(() {});
  }

  String getChatRoomIdByUsernames(String a, String b) {
    if (a.substring(0, 1).codeUnitAt(0) > b.substring(0, 1).codeUnitAt(0)) {
      return "$b\_$a";
    } else {
      return "$a\_$b";
    }
  }

  void onLaunch() async {
    userProfileStream = await DatabaseMethods().getUserInfo(widget.userName);
    postsStream = await DatabaseMethods().getMyPosts(widget.userName);
    myRequestCollection =
        await DatabaseMethods().getMyRequests(widget.myUserId, widget.userName);
    QuerySnapshot userdetails =
        await DatabaseMethods().getUserInfo2(widget.userName);
    email = userdetails.docs[0]["email"];
    tokenId = userdetails.docs[0]["tokenId"];
    myEmail = (await SharedPreferenceHelper().getUserEmail())!;
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
      SystemUiOverlayStyle.dark.copyWith(
        statusBarBrightness: Brightness.dark,
        statusBarIconBrightness: Brightness.light,
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: primaryScaffoldColor,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
    return Scaffold(
      appBar: AppBar(
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
          '@' + widget.userName,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: primaryColor,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        child: Column(
          children: [
            StreamBuilder(
              stream: userProfileStream,
              builder: (context, AsyncSnapshot<QuerySnapshot> snapShot) {
                if (snapShot.connectionState == ConnectionState.active) {
                  if (snapShot.hasData) {
                    DocumentSnapshot ds = snapShot.data!.docs[0];
                    return Column(
                      children: [
                        Stack(
                          // alignment: Alignment.bottomLeft,
                          children: [
                            Container(
                              // color: Colors.black,
                              width: double.infinity,
                              height: 205,
                            ),
                            Container(
                              alignment: Alignment.topLeft,
                              height: 160,
                              width: double.infinity,
                              decoration: const BoxDecoration(
                                image: DecorationImage(
                                  image: NetworkImage(
                                      'https://media.istockphoto.com/photos/mountain-landscape-picture-id517188688?k=20&m=517188688&s=612x612&w=0&h=i38qBm2P-6V4vZVEaMy_TaTEaoCMkYhvLCysE7yJQ5Q='),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 125,
                              left: 20,
                              child: Stack(
                                alignment: Alignment.bottomRight,
                                children: [
                                  Container(
                                    height: 70,
                                    width: 70,
                                    decoration: BoxDecoration(
                                      color: Color(0xfff2f7fa),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Color(0xfff2f7fa),
                                        width: 3.5,
                                      ),
                                      image: DecorationImage(
                                        image: NetworkImage(ds["imgUrl"]),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  CircleAvatar(
                                    backgroundColor: Color(0xfff2f7fa),
                                    radius: 10,
                                    child: CircleAvatar(
                                      radius: 6,
                                      backgroundColor: ds["active"] == "1"
                                          ? Colors.green
                                          : Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Container(
                              width: MediaQuery.of(context).size.width * 0.55,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    ds["name"],
                                    style: TextStyle(
                                      fontSize: 20,
                                      color: Colors.blueGrey.shade800,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '@' + widget.userName,
                                    style: TextStyle(
                                      color: primaryColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(
                                    height: 5,
                                  ),
                                  Text(
                                    ds["email"],
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        loading == true
                            ? Padding(
                                padding: EdgeInsets.symmetric(horizontal: 10),
                                child: MaterialButton(
                                  onPressed: () {},
                                  color: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Container(
                                    width: double.infinity,
                                    child: CustomProgress(),
                                  ),
                                ),
                              )
                            : StreamBuilder<dynamic>(
                                stream: myRequestCollection,
                                builder: (context, snapshots) {
                                  if (snapshots.connectionState !=
                                      ConnectionState.active) {
                                    return Container(
                                      child: LinearProgressIndicator(),
                                    );
                                  }
                                  if (snapshots.hasError) {
                                    return Container(
                                      child: Text("Some error occurred"),
                                    );
                                  }
                                  if (snapshots.hasData) {
                                    if (snapshots.data.docs.length != 0) {
                                      return Padding(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 8.0),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: MaterialButton(
                                                onPressed: () async {
                                                  loading = true;
                                                  setState(() {});
                                                  await accept(
                                                      ds["imgUrl"], ds["name"]);
                                                },
                                                color: primaryColor,
                                                elevation: 0,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(5),
                                                ),
                                                child: Text(
                                                  'Accept',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            SizedBox(
                                              width: 10,
                                            ),
                                            Expanded(
                                              child: MaterialButton(
                                                onPressed: () async {
                                                  loading = true;
                                                  setState(() {});
                                                  await decline("0");
                                                },
                                                color: Colors.red.shade400,
                                                elevation: 0,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(5),
                                                ),
                                                child: Text(
                                                  'Decilne',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    } else {
                                      return ds["requests"]
                                              .contains(widget.myUserName)
                                          ? Padding(
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 10),
                                              child: MaterialButton(
                                                onPressed: () async {
                                                  loading = true;
                                                  setState(() {});
                                                  await manageRequest("delete");
                                                },
                                                color: Colors.white,
                                                elevation: 0,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(5),
                                                ),
                                                child: Container(
                                                  width: double.infinity,
                                                  child: Center(
                                                    child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        Icon(Icons.done),
                                                        SizedBox(
                                                          width: 10,
                                                        ),
                                                        Text(
                                                          'Request Sent',
                                                          style: TextStyle(
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            color: Colors
                                                                .blueGrey
                                                                .shade500,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            )
                                          : ds["friends"]
                                                  .contains(widget.myUserName)
                                              ? Padding(
                                                  padding: EdgeInsets.symmetric(
                                                      horizontal: 10),
                                                  child: MaterialButton(
                                                    onPressed: () async {
                                                      loading = true;
                                                      setState(() {});
                                                      await deleteFriend();
                                                    },
                                                    color: Colors.white,
                                                    elevation: 0,
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              5),
                                                    ),
                                                    child: Container(
                                                      width: double.infinity,
                                                      child: Center(
                                                        child: Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          children: [
                                                            Icon(Icons.people),
                                                            SizedBox(
                                                              width: 10,
                                                            ),
                                                            Text(
                                                              'Friends',
                                                              style: TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                color: Colors
                                                                    .blueGrey
                                                                    .shade500,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                )
                                              : Padding(
                                                  padding: EdgeInsets.symmetric(
                                                      horizontal: 10),
                                                  child: MaterialButton(
                                                    onPressed: () async {
                                                      loading = true;
                                                      setState(() {});
                                                      await manageRequest(
                                                          "add");
                                                    },
                                                    elevation: 0,
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              5),
                                                    ),
                                                    color: primaryColor,
                                                    child: Container(
                                                      width: double.infinity,
                                                      child: Center(
                                                        child: Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          children: [
                                                            Icon(
                                                              Icons.add,
                                                              color:
                                                                  Colors.white,
                                                            ),
                                                            SizedBox(
                                                              width: 10,
                                                            ),
                                                            Text(
                                                              'Send Request',
                                                              style: TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                color: Colors
                                                                    .white,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                );
                                    }
                                  } else {
                                    return Center(
                                      child: LinearProgressIndicator(),
                                    );
                                  }
                                },
                              ),
                        Divider(
                          color: Colors.grey.shade400,
                        ),
                        Container(
                          // padding: EdgeInsets.symmetric(
                          //     horizontal: 20, vertical: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Expanded(
                                flex: 2,
                                child: Container(
                                  margin: EdgeInsets.all(10),
                                  padding: EdgeInsets.symmetric(vertical: 7),
                                  decoration: BoxDecoration(
                                    color: primaryColor,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Column(
                                    children: [
                                      StreamBuilder(
                                          stream: postsStream,
                                          builder: (context,
                                              AsyncSnapshot<QuerySnapshot>
                                                  postsnapShot) {
                                            if (postsnapShot.connectionState ==
                                                ConnectionState.active) {
                                              if (postsnapShot.hasData) {
                                                return Text(
                                                  postsnapShot.data!.docs.length
                                                      .toString(),
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.white,
                                                    fontSize: 30,
                                                  ),
                                                );
                                              } else {
                                                return Text(
                                                  "0",
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.white,
                                                    fontSize: 30,
                                                  ),
                                                );
                                              }
                                            } else {
                                              return CustomProgress();
                                            }
                                          }),
                                      const SizedBox(
                                        height: 5,
                                      ),
                                      Text(
                                        'Posts',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: MaterialButton(
                                    onPressed: () {
                                      Navigator.of(context)
                                          .push(MaterialPageRoute(
                                              builder: ((context) => FriendList(
                                                    userId: widget.userId,
                                                    name: ds["name"],
                                                    myUserName:
                                                        widget.myUserName,
                                                    myDisplayName:
                                                        widget.myDisplayName,
                                                    myUserId: widget.myUserId,
                                                    myUserImg: widget.myImgUrl,
                                                  ))));
                                    },
                                    color: primaryColor,
                                    elevation: 0,
                                    padding: EdgeInsets.symmetric(vertical: 10),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          ds["friends"].length.toString(),
                                          style: TextStyle(
                                            fontWeight: FontWeight.w900,
                                            color: Colors.white,
                                            fontSize: 30,
                                          ),
                                        ),
                                        Text(
                                          'Followers',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
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

            //===========================================================================

            SizedBox(
              height: 10,
            ),
            //===================== Your Posts=========================
            StreamBuilder(
                stream: postsStream,
                builder: (context, AsyncSnapshot<QuerySnapshot> snapShot) {
                  if (snapShot.connectionState != ConnectionState.active) {
                    return CustomProgress();
                  }
                  if (snapShot.hasError) {
                    return const Center(
                      child: Text("Error in receiving posts"),
                    );
                  } else if (snapShot.hasData) {
                    if (snapShot.data!.docs.isEmpty) {
                      return const Center(
                        child: Text("No Posts"),
                      );
                    }
                    return Column(
                      children:
                          List.generate(snapShot.data!.docs.length, (index) {
                        DocumentSnapshot ds = snapShot.data!.docs[index];
                        return FeedCard(
                          myUserName: widget.myUserName,
                          myUserId: widget.myUserId,
                          myUserImg: widget.myImgUrl,
                          myDisplayName: widget.myDisplayName,
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
                      }),
                    );
                  } else {
                    return CustomProgress();
                  }
                })
          ],
        ),
      ),
    );
  }
}
