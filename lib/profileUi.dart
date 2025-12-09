import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:page_route_transition/page_route_transition.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:social_media_app/services/story_widgets.dart';
import '/colors.dart';
import '/editProfile.dart';
import '/friendORrequest.dart';
import '/services/database.dart';
import '/services/sharedPref_helper.dart';
import './services/auth.dart';
import './signin.dart';
import 'feeds.dart';

class ProfileUi extends StatefulWidget {
  // const ProfileUi({Key? key}) : super(key: key);

  @override
  _ProfileUiState createState() => _ProfileUiState();
}

class _ProfileUiState extends State<ProfileUi> {
  Stream<QuerySnapshot>? myPosts, userProfileStream;
  String myUserId = "", myUserImg = "", myDisplayName = "", myUserName = "";

  List<File> storyImg = [];
  UploadTask? task;
  Future selectStoryImage(
      BuildContext context,
      ImageSource source,
      String myUserName,
      String myUserId,
      String displayName,
      String userImg) async {
    storyImg.clear();
    final pickedImg = await ImagePicker().pickImage(source: source);
    if (pickedImg != null) {
      storyImg.add(File(pickedImg.path));
      return;
    }
    print('No image selected');
    return;
  }

  previewStoryImage(
    BuildContext context,
    File? storyFile,
    String myUserName,
    String myUserId,
    String displayName,
  ) {
    return showModalBottomSheet(
      backgroundColor: Colors.grey.withOpacity(0.5),
      isScrollControlled: true,
      context: context,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          decoration: BoxDecoration(
            color: Colors.white,
          ),
          child: Stack(
            children: [
              Container(
                height: MediaQuery.of(context).size.height,
                width: MediaQuery.of(context).size.width,
                child: Image.file(storyFile!),
              ),
              task == null
                  ? Positioned(
                      top: 700.0,
                      child: Container(
                        width: MediaQuery.of(context).size.width,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            FloatingActionButton(
                                heroTag: 'Reselect Image',
                                backgroundColor: Colors.redAccent,
                                child: Icon(
                                  Icons.redo_rounded,
                                  color: Colors.white,
                                ),
                                onPressed: () {
                                  addStory(context, myUserName, myUserId,
                                      displayName, myUserImg);
                                }),
                            FloatingActionButton(
                                heroTag: 'Confirm Image',
                                backgroundColor: primaryColor,
                                child: Icon(
                                  Icons.done,
                                  color: Colors.white,
                                ),
                                onPressed: () async {
                                  task = DatabaseMethods.uploadStoryImg(
                                      myUserName, storyFile);
                                  setState(() {});
                                  final snapshot =
                                      await task!.whenComplete(() {});
                                  String downloadUrl =
                                      await snapshot.ref.getDownloadURL();
                                  try {
                                    await FirebaseFirestore.instance
                                        .collection("stories")
                                        .doc(myUserId)
                                        .set({
                                      "url": downloadUrl,
                                      "userImg": myUserImg,
                                      "displayName": displayName,
                                      "name": myUserName,
                                      "ts": Timestamp.now(),
                                      "type": "image"
                                    }).whenComplete(() async {
                                      // clear seen collection
                                      await FirebaseFirestore.instance
                                          .collection("stories")
                                          .doc(myUserId)
                                          .collection("seen")
                                          .get()
                                          .then((snapshot) {
                                        for (DocumentSnapshot doc
                                            in snapshot.docs) {
                                          doc.reference.delete();
                                        }
                                      });
                                      Navigator.pop(context);
                                    });
                                  } catch (e) {
                                    print("error here in story_widgets $e");
                                  }
                                }),
                          ],
                        ),
                      ))
                  : Positioned(
                      top: 700,
                      child: Container(
                          width: MediaQuery.of(context).size.width,
                          child: StoryWidgets().buildUploadStatus(task!)))
            ],
          ),
        );
      },
    );
  }

  Future addStory(BuildContext context, String myUserName, String myUserId,
      String displayName, String userImg) {
    return showModalBottomSheet(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
      ),
      context: context,
      builder: (context) {
        return Container(
          height: 170,
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Image',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(
                height: 20,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      GestureDetector(
                        onTap: () async {
                          selectStoryImage(context, ImageSource.gallery,
                                  myUserName, myUserId, displayName, userImg)
                              .whenComplete(() {
                            Navigator.pop(context);
                            if (storyImg.isNotEmpty) {
                              previewStoryImage(context, storyImg[0],
                                  myUserName, myUserId, displayName);
                            }
                          });
                        },
                        child: CircleAvatar(
                          backgroundColor: Color(0xFFFCE0EA),
                          radius: 30,
                          child: SvgPicture.asset(
                            'lib/assets/image/picture.svg',
                            color: Colors.pink.shade600,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 7,
                      ),
                      Text(
                        'Gallery',
                        style: TextStyle(
                          color: Colors.grey.shade800,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      GestureDetector(
                        onTap: () async {
                          selectStoryImage(context, ImageSource.camera,
                                  myUserName, myUserId, displayName, userImg)
                              .whenComplete(() {
                            Navigator.pop(context);
                            if (storyImg.isNotEmpty) {
                              previewStoryImage(
                                context,
                                storyImg[0],
                                myUserName,
                                myUserId,
                                displayName,
                              );
                            }
                          });
                        },
                        child: CircleAvatar(
                          backgroundColor: Color.fromARGB(255, 220, 239, 255),
                          radius: 30,
                          child: SvgPicture.asset(
                            'lib/assets/image/camera.svg',
                            color: Colors.blue.shade600,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 7,
                      ),
                      Text(
                        'Camera',
                        style: TextStyle(
                          color: Colors.grey.shade800,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void onLoading() async {
    myUserId = (await SharedPreferenceHelper().getUserId())!;
    myUserName = (await SharedPreferenceHelper().getUserName())!;
    myPosts = await DatabaseMethods().getMyPosts(myUserName);
    myUserImg = (await SharedPreferenceHelper().getUserProfileUrl())!;
    myDisplayName = (await SharedPreferenceHelper().getDisplayName())!;
    userProfileStream = await DatabaseMethods().getUserInfo(myUserName);
    // await FirebaseFirestore.instance
    //     .collection("users")
    //     .where("username", isEqualTo: myUserName)
    //     .snapshots();
    setState(() {});
  }

  @override
  void initState() {
    onLoading();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle.light.copyWith(
        statusBarBrightness: Brightness.dark,
        statusBarIconBrightness: Brightness.dark,
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
    return SingleChildScrollView(
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
                                  'https://media.istockphoto.com/photos/mountain-landscape-picture-id517188688?k=20&m=517188688&s=612x612&w=0&h=i38qBm2P-6V4vZVEaMy_TaTEaoCMkYhvLCysE7yJQ5Q=',
                                ),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 125,
                            left: 20,
                            child: Container(
                              height: 70,
                              width: 70,
                              decoration: BoxDecoration(
                                color: const Color(0xfff2f7fa),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xfff2f7fa),
                                  width: 3.5,
                                ),
                                image: DecorationImage(
                                  image: NetworkImage(ds["imgUrl"]),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    ds["name"],
                                    style: TextStyle(
                                      color: Colors.blueGrey.shade800,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(
                                    height: 5,
                                  ),
                                  Text(
                                    ds["email"],
                                    style: TextStyle(
                                      color: Colors.blueGrey.shade300,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            MaterialButton(
                              onPressed: () {
                                PageRouteTransition.push(
                                    context, EditProfile());
                              },
                              elevation: 0,
                              highlightElevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5),
                                side: BorderSide(
                                  color: Colors.blueGrey.shade100,
                                ),
                              ),
                              color: Color(0xfff2f7fa),
                              padding: EdgeInsets.all(14),
                              child: Text(
                                'Edit Profile',
                                style: TextStyle(
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Divider(
                        color: Colors.grey.shade400,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Expanded(
                              flex: 2,
                              child: Column(
                                children: [
                                  StreamBuilder(
                                      stream: myPosts,
                                      builder: (context,
                                          AsyncSnapshot<QuerySnapshot>
                                              snapShot) {
                                        if (snapShot.hasData) {
                                          return Text(
                                            snapShot.data!.docs.length
                                                .toString(),
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: Colors.blueGrey.shade700,
                                              fontSize: 20,
                                            ),
                                          );
                                        } else {
                                          return Text(
                                            "0",
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: Colors.blueGrey.shade700,
                                              fontSize: 20,
                                            ),
                                          );
                                        }
                                      }),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                  Text(
                                    'Posts',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: Colors.blueGrey.shade400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              height: 20,
                              width: 0.5,
                              color: Colors.blueGrey.shade300,
                            ),
                            Expanded(
                              flex: 2,
                              child: MaterialButton(
                                onPressed: () {
                                  PageRouteTransition.push(
                                    context,
                                    friendORrequest(
                                      operation: "Requests",
                                      myUserId: ds.id,
                                      myDisplayName: ds["name"],
                                      myUserImg: ds["imgUrl"],
                                      myUserName: ds["username"],
                                    ),
                                  );
                                },
                                child: Column(
                                  children: [
                                    Text(
                                      ds["requests"].length.toString(),
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.blueGrey.shade700,
                                        fontSize: 20,
                                      ),
                                    ),
                                    const SizedBox(
                                      height: 5,
                                    ),
                                    Text(
                                      'Requests',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                        color: Colors.blueGrey.shade400,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Container(
                              height: 20,
                              width: 0.5,
                              color: Colors.blueGrey.shade300,
                            ),
                            Expanded(
                              flex: 2,
                              child: MaterialButton(
                                onPressed: () {
                                  PageRouteTransition.push(
                                    context,
                                    friendORrequest(
                                      operation: "Friends",
                                      myUserId: ds.id,
                                      myDisplayName: ds["name"],
                                      myUserImg: ds["imgUrl"],
                                      myUserName: ds["username"],
                                    ),
                                  );
                                },
                                child: Column(
                                  children: [
                                    Text(
                                      ds["friends"].length.toString(),
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.blueGrey.shade700,
                                        fontSize: 20,
                                      ),
                                    ),
                                    const SizedBox(
                                      height: 5,
                                    ),
                                    Text(
                                      'Followers',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                        color: Colors.blueGrey.shade400,
                                      ),
                                    ),
                                  ],
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
          Divider(
            color: Colors.blueGrey.shade300,
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: MaterialButton(
              onPressed: () {
                addStory(
                    context, myUserName, myUserId, myDisplayName, myUserImg);
              },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
              color: primaryColor,
              elevation: 0,
              highlightElevation: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 15),
                width: double.infinity,
                child: const Center(
                  child: Text(
                    'Add to Story',
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(left: 20, right: 20, bottom: 20),
            child: MaterialButton(
              onPressed: () async {
                Map<String, dynamic> userInfo = {"active": "0"};
                await FirebaseFirestore.instance
                    .collection("users")
                    .doc(myUserId)
                    .update(userInfo);
                AuthMethods().signOut().then((value) {
                  Navigator.pushReplacement(context,
                      MaterialPageRoute(builder: (context) => SignIn()));
                });
              },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
              color: Colors.red.shade700,
              elevation: 0,
              highlightElevation: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 15),
                width: double.infinity,
                child: const Center(
                  child: Text(
                    'Logout',
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Padding(
          //   padding: EdgeInsets.only(left: 20, right: 20, bottom: 20),
          //   child: MaterialButton(
          //     onPressed: () async {
          //       await AuthMethods().signInWithGoogle(context);
          //     },
          //     shape: RoundedRectangleBorder(
          //       borderRadius: BorderRadius.circular(5),
          //     ),
          //     color: Colors.blue.shade300,
          //     elevation: 0,
          //     highlightElevation: 0,
          //     child: Container(
          //       padding: const EdgeInsets.symmetric(vertical: 15),
          //       width: double.infinity,
          //       child: const Center(
          //         child: Text(
          //           'Switch Account',
          //           style: TextStyle(
          //             color: Colors.white,
          //           ),
          //         ),
          //       ),
          //     ),
          //   ),
          // ),

          //===================== Your Posts=========================
          StreamBuilder(
            stream: myPosts,
            builder: (context, AsyncSnapshot<QuerySnapshot> snapShot) {
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
                  children: List.generate(
                    snapShot.data!.docs.length,
                    (index) {
                      DocumentSnapshot ds = snapShot.data!.docs[index];
                      return FeedCard(
                        myUserName: myUserName,
                        myUserId: myUserId,
                        myUserImg: myUserImg,
                        myDisplayName: myDisplayName,
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
                );
              } else {
                return CustomProgress();
              }
            },
          )
        ],
      ),
    );
  }
}
