import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:social_media_app/colors.dart';
import 'package:social_media_app/user_profile.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:percent_indicator/percent_indicator.dart';

class StoryWidgets {
  Widget buildUploadStatus(UploadTask task) => StreamBuilder<TaskSnapshot>(
      stream: task.snapshotEvents,
      builder: (context, AsyncSnapshot<TaskSnapshot> snapshot) {
        if (snapshot.hasData) {
          final snap = snapshot.data;
          final progress = snap!.bytesTransferred / snap.totalBytes;
          // final percentage = (progress * 100).toStringAsFixed(2);
          final percentage = (progress * 100);
          return LinearPercentIndicator(
            width: 220,
            lineHeight: 15,
            percent: percentage,
            animation: true,
            // animationDuration: 2000,
            leading: Text(
              '${percentage.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          );
        } else {
          return Container();
        }
      });
  storyTimePosted(dynamic timeData) {
    Timestamp timestamp = timeData;
    DateTime dateTime = timestamp.toDate();
    String storyTime = timeago.format(dateTime);
    return storyTime;
  }

  Future addSeenStamp(BuildContext context, String storyId, String myUserId,
      String myUserName, String myUserImg, String myDisplayName) async {
    return FirebaseFirestore.instance
        .collection("stories")
        .doc(storyId)
        .collection("seen")
        .doc(myUserId)
        .set({
      "userName": myUserName,
      "userImg": myUserImg,
      "displayName": myDisplayName,
      "time": Timestamp.now()
    });
  }

  showViewers(BuildContext context, String storyId, String myUserId) {
    return showModalBottomSheet(
      backgroundColor: Colors.white,
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, StateSetter setModalState) {
            return Container(
              child: Column(children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 150.0),
                  child: Divider(
                    thickness: 4.0,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.4,
                  width: MediaQuery.of(context).size.width,
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection("stories")
                        .doc(storyId)
                        .collection("seen")
                        .snapshots(),
                    builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                      if (snapshot.connectionState == ConnectionState.active) {
                        if (snapshot.hasData) {
                          return ListView(
                            children: snapshot.data!.docs
                                .map((DocumentSnapshot documentSnapshot) {
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundImage:
                                      NetworkImage(documentSnapshot["userImg"]),
                                  radius: 25,
                                ),
                                trailing: IconButton(
                                  icon: Icon(
                                    Icons.arrow_circle_right_rounded,
                                  ),
                                  onPressed: () {
                                    // Navigator.of(context).push(MaterialPageRoute(
                                    //     builder: (context) => UserProfile(
                                    //         userName:
                                    //             documentSnapshot["userName"],
                                    //         myUserName: myUserName,
                                    //         userId: documentSnapshot.id,
                                    //         myDisplayName: myDisplayName,
                                    //         myFriendList: myFriendList,
                                    //         myRequestList: myRequestList,
                                    //         myImgUrl: myImgUrl,
                                    //         myUserId: myUserId)));
                                  },
                                ),
                                title: Text(
                                  documentSnapshot["displayName"],
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16),
                                ),
                                subtitle: Text(
                                  storyTimePosted(documentSnapshot["time"]),
                                  style: TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12),
                                ),
                              );
                            }).toList(),
                          );
                        } else {
                          return Center(
                            child: SingleChildScrollView(),
                          );
                        }
                      } else {
                        return Center(
                          child: SingleChildScrollView(),
                        );
                      }
                    },
                  ),
                )
              ]),
              height: MediaQuery.of(context).size.height * 0.5,
              width: MediaQuery.of(context).size.width,
            );
          },
        );
      },
    );
  }
}

class DummyStoryCard extends StatelessWidget {
  const DummyStoryCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      width: 100,
      margin: EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}

class DummyPostCard extends StatelessWidget {
  const DummyPostCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(10),
      width: double.infinity,
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              SizedBox(
                width: 10,
              ),
              Column(
                children: [
                  Container(
                    width: 200,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    width: 200,
                    height: 10,
                  ),
                ],
              ),
            ],
          ),
          Container(
            margin: EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            height: 300,
            width: double.infinity,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 60,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Container(
                width: 60,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Container(
                width: 60,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class CustomProgress extends StatelessWidget {
  const CustomProgress({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        height: 25,
        width: 25,
        child: CircularProgressIndicator(
          color: primaryColor,
          backgroundColor: primaryColor.withOpacity(0.2),
          strokeWidth: 4,
        ),
      ),
    );
  }
}
