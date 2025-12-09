import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '/profileUi.dart';
import '/services/database.dart';

import 'services/story_widgets.dart';
import 'user_profile.dart';

class FriendList extends StatefulWidget {
  // const FriendList({Key key}) : super(key: key);
  final userId;
  final name;
  final myDisplayName;
  final myUserName;
  final myUserImg;
  final myUserId;
  FriendList(
      {required this.userId,
      required this.name,
      required this.myUserName,
      required this.myDisplayName,
      required this.myUserId,
      required this.myUserImg});
  @override
  _FriendListState createState() => _FriendListState();
}

class _FriendListState extends State<FriendList> {
  Stream<QuerySnapshot>? friendsStream, myUserStream;
  void onLaunch() async {
    friendsStream = await DatabaseMethods().getFriends(widget.userId);
    myUserStream = await DatabaseMethods().getUserInfo(widget.myUserName);
    setState(() {});
  }

  @override
  void initState() {
    onLaunch();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              StreamBuilder(
                  stream: friendsStream,
                  builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                    if (snapshot.hasData) {
                      return Padding(
                        padding: const EdgeInsets.all(15.0),
                        child: Text(
                          "${widget.name}'s Friends: ${snapshot.data!.docs.length}",
                          style: TextStyle(
                            color: Colors.blueGrey.shade700,
                            fontWeight: FontWeight.w700,
                            fontSize: 17,
                          ),
                        ),
                      );
                    } else {
                      return Container();
                    }
                  }),
              Container(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height - 90,
                child: StreamBuilder(
                  stream: friendsStream,
                  builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                    if (snapshot.hasData) {
                      if (snapshot.data!.docs.length == 0) {
                        return const Center(
                          child: Text(
                            "No Friends Available",
                            style: TextStyle(
                              // color: Colors.blueGrey.shade200,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        );
                      } else {
                        return ListView.builder(
                          itemCount: snapshot.data!.docs.length,
                          shrinkWrap: true,
                          itemBuilder: (context, index) {
                            DocumentSnapshot ds = snapshot.data!.docs[index];
                            return Row(
                              children: [
                                Expanded(
                                  child: MaterialButton(
                                    onPressed: () {
                                      if (ds["userName"] == widget.myUserName) {
                                        // if in this is some other person's friend list and i am present there then open my profile on click
                                        // ProfileUi();
                                      } else {
                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    UserProfile(
                                                      userName: ds["userName"],
                                                      myUserName:
                                                          widget.myUserName,
                                                      myDisplayName:
                                                          widget.myDisplayName,
                                                      myImgUrl:
                                                          widget.myUserImg,
                                                      myUserId: widget.myUserId,
                                                      userId: ds.id,
                                                    )));
                                      }
                                    },
                                    child: Container(
                                      width: double.infinity,
                                      margin: const EdgeInsets.all(0),
                                      padding: const EdgeInsets.only(
                                          top: 10,
                                          bottom: 0,
                                          left: 0,
                                          right: 0),
                                      child: Row(
                                        children: [
                                          Container(
                                            height: 70,
                                            width: 70,
                                            decoration: BoxDecoration(
                                              color: const Color(0xfff2f7fa),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: const Color(0xfff2f7fa),
                                                width: 3.5,
                                              ),
                                              image: DecorationImage(
                                                image:
                                                    NetworkImage(ds["imgUrl"]),
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(
                                            width: 12,
                                          ),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                FittedBox(
                                                  child: Text(
                                                    ds["name"],
                                                    style: const TextStyle(
                                                        fontSize: 20,
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  ),
                                                ),
                                                const SizedBox(
                                                  height: 3,
                                                ),
                                                FittedBox(
                                                  child: Text(
                                                    ds["email"],
                                                    style: const TextStyle(
                                                        fontSize: 18,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.grey),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          ds["userName"] == widget.myUserName
                                              ? Text(
                                                  "YOU",
                                                  style: TextStyle(
                                                      color: Colors.green),
                                                )
                                              : Container()
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                //to check if this user in this friend list also exists in my frienflist i.e it is mutual friend
                                StreamBuilder(
                                  stream: myUserStream,
                                  builder: (context,
                                      AsyncSnapshot<QuerySnapshot> snapshot) {
                                    if (snapshot.hasData) {
                                      return snapshot.data!.docs[0]["friends"]
                                              .contains(ds["userName"])
                                          ? const Icon(
                                              Icons.people,
                                              color: Colors.blue,
                                            )
                                          : Container();
                                    } else {
                                      return CustomProgress();
                                    }
                                  },
                                ),
                              ],
                            );
                          },
                        );
                      }
                    } else {
                      return CustomProgress();
                    }
                  },
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
