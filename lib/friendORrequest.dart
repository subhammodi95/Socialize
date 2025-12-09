import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:page_route_transition/page_route_transition.dart';
import '/colors.dart';
import '/services/database.dart';
import '/user_profile.dart';
import 'services/story_widgets.dart';

class friendORrequest extends StatefulWidget {
  final operation;
  final myUserName;
  final myDisplayName;
  final myUserImg;
  final myUserId;
  friendORrequest(
      {required this.operation,
      required this.myUserId,
      required this.myDisplayName,
      required this.myUserImg,
      required this.myUserName});
  @override
  _friendORrequestState createState() => _friendORrequestState();
}

class _friendORrequestState extends State<friendORrequest> {
  Stream<QuerySnapshot>? listStream;
  onLaunch() async {
    if (widget.operation == "Friends") {
      listStream = await DatabaseMethods().getFriends(widget.myUserId);
    } else {
      listStream = await DatabaseMethods().getRequests(widget.myUserId);
    }
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
        centerTitle: true,
        title: Text(
          widget.operation,
          style: TextStyle(
            color: Colors.white,
          ),
        ),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 10,
          ),
          StreamBuilder(
            stream: listStream,
            builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (snapshot.hasData) {
                return Container(
                  child: widget.operation == "Friends"
                      ? Text(
                          "Followers: ${snapshot.data!.docs.length}",
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.grey,
                          ),
                        )
                      : Text(
                          "Requests: ${snapshot.data!.docs.length}",
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.grey,
                          ),
                        ),
                );
              } else {
                return CustomProgress();
              }
            },
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(children: [
                StreamBuilder(
                    stream: listStream,
                    builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                      if (snapshot.hasData) {
                        if (snapshot.data!.docs.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: EdgeInsets.only(top: 40),
                              child: Text(
                                "It's Empty Here!",
                                style: TextStyle(
                                  fontSize: 50,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          );
                        }
                        return ListView.builder(
                            itemCount: snapshot.data!.docs.length,
                            shrinkWrap: true,
                            itemBuilder: (context, index) {
                              DocumentSnapshot ds = snapshot.data!.docs[index];
                              return MaterialButton(
                                onPressed: () {
                                  PageRouteTransition.push(
                                    context,
                                    UserProfile(
                                      userName: ds["userName"],
                                      myUserName: widget.myUserName,
                                      myDisplayName: widget.myDisplayName,
                                      myImgUrl: widget.myUserImg,
                                      myUserId: widget.myUserId,
                                      userId: ds.id,
                                    ),
                                  );
                                },
                                child: Container(
                                  width: double.infinity,
                                  margin: const EdgeInsets.all(0),
                                  padding: const EdgeInsets.only(
                                      top: 10, bottom: 0, left: 0, right: 0),
                                  child: Row(
                                    children: [
                                      Stack(
                                          alignment: Alignment.bottomRight,
                                          children: [
                                            Container(
                                              height: 70,
                                              width: 70,
                                              decoration: BoxDecoration(
                                                color: const Color(0xfff2f7fa),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                border: Border.all(
                                                  color:
                                                      const Color(0xfff2f7fa),
                                                  width: 3.5,
                                                ),
                                                image: DecorationImage(
                                                  image: NetworkImage(
                                                      ds["imgUrl"]),
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                            ),
                                            // ds["active"] == "1"
                                            //     ? const Icon(
                                            //         Icons.circle,
                                            //         color: Colors.green,
                                            //       )
                                            //     : const Icon(
                                            //         Icons.circle,
                                            //         color: Colors.red,
                                            //         size: 20,
                                            //       )
                                          ]),
                                      const SizedBox(
                                        width: 12,
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            ds["name"],
                                            style: const TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(
                                            height: 3,
                                          ),
                                          Text(
                                            ds["email"],
                                            style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.grey),
                                          )
                                        ],
                                      )
                                    ],
                                  ),
                                ),
                              );
                            });
                      } else if (snapshot.hasError) {
                        return const Center(
                          child: Text("Error in Loading users"),
                        );
                      } else {
                        return Center(
                          child: SingleChildScrollView(),
                        );
                      }
                    })
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
