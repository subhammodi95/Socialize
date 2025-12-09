import 'dart:io';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:page_route_transition/page_route_transition.dart';
import 'package:shimmer/shimmer.dart';
import 'package:social_media_app/notifications.dart';
import 'package:social_media_app/searchUi.dart';
import 'package:social_media_app/services/auth.dart';
import 'package:social_media_app/services/story_widgets.dart';
import 'package:social_media_app/signin.dart';
import 'package:social_media_app/video_player.dart';
import '/colors.dart';
import 'admin/admin.dart';
import './chatsUi.dart';
import 'package:video_player/video_player.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_file/open_file.dart';
import './profileUi.dart';
import './storyUi.dart';
import './services/database.dart';
import 'feeds.dart';
import 'services/sharedPref_helper.dart';

var savedScrollOffset = 0.0;

class Home extends StatefulWidget {
  // const Home({Key? key}) : super(key: key);

  @override
  _HomeUiState createState() => _HomeUiState();
}

class _HomeUiState extends State<Home> with WidgetsBindingObserver {
  String selectedScreen = 'home';
  Stream<QuerySnapshot>? usersStream, postsStream, storiesStream, myStory;
  List myFriends = [], myRequests = [];
  TextEditingController _textEditingController =
      TextEditingController(text: "");
  late VideoPlayerController _controller;
  late Future<void> _initializeVideoPlayerFuture;
  List<File> image = [];
  List<File> video = [];
  List<File> file = [];
  String fileType = "", desig = "";
  DocumentSnapshot? userList;
  bool isPosting = false;
  bool fetchingData = false;
  String myUserName = "", myUserImg = "", myUserId = "", myDisplayName = "";
  late ScrollController _scrollController;

  Future<void> getImage() async {
    try {
      final pickedfile = await ImagePicker()
          .pickImage(source: ImageSource.gallery, imageQuality: 50);
      if (pickedfile != null) {
        video.clear();
        file.clear();
        image.isEmpty
            ? image.add(File(pickedfile.path))
            : image.insert(0, File(pickedfile.path));
        setState(() {});
      } else {
        print("No image selected");
      }
    } on PlatformException catch (e) {
      print("failed to pick image $e");
    }
  }

  Future<void> getVideo() async {
    try {
      final pickedfile = await ImagePicker().pickVideo(
          source: ImageSource.gallery,
          maxDuration: Duration(minutes: 15, hours: 0));
      if (pickedfile != null) {
        image.clear();
        file.clear();
        //================================================================================
        _controller = VideoPlayerController.file(File(pickedfile.path));
        _initializeVideoPlayerFuture = _controller.initialize();
        _controller.setLooping(true);
        _controller.setVolume(1.0);
        //================================================================================
        video.isEmpty
            ? video.add(File(pickedfile.path))
            : video.insert(0, File(pickedfile.path));
        setState(() {});
      } else {
        print("No video selected");
      }
    } on PlatformException catch (e) {
      print("failed to pick video $e");
    }
  }

  Future<void> getFile() async {
    try {
      final pickedfile = await FilePicker.platform.pickFiles(
          allowMultiple: false,
          type: FileType.custom,
          allowedExtensions: [
            'pdf',
            'doc',
            'docx',
            'xls',
            'pptx',
            'xlsx',
            'csv',
            'zip'
          ]);
      if (pickedfile != null) {
        if ((pickedfile.files.single.size / (1024.0 * 1024.0)) > 20.0) {
          // if file greter than 20 mb
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Maximum size allowed for a file is 20mb",
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
            backgroundColor: Colors.red,
          ));
          return;
        }

        video.clear();
        image.clear();

        file.isEmpty
            ? file.add(File(pickedfile.files.single.path!))
            : file.insert(0, File(pickedfile.files.single.path!));
        fileType = pickedfile.files.single.name.replaceAll('_', "") +
            '_' +
            pickedfile.files.single.size.toString(); //pdf
        setState(() {});
      } else {
        print("No file selected");
      }
    } on PlatformException catch (e) {
      print("failed to pick file $e");
    }
  }

  void post() async {
    String url = "", postId = "";
    double size = 0.0;
    String ab = "";
    DateTime time = DateTime.now();
    if (image.isNotEmpty) {
      url =
          await DatabaseMethods().uploadImg(image, myUserName, time.toString());
    }
    if (video.isNotEmpty) {
      if ((await video.length / (1024 * 1024)) > 50.0) {
        // if file greter than 50 mb
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Maximum size allowed for a video is 50mb",
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.red,
        ));
        Navigator.of(context).pop();
        isPosting = false;
        setState(() {});
        return;
      } else {
        url = await DatabaseMethods()
            .uploadVideo(video, myUserName, time.toString());
      }
    }

    if (file.isNotEmpty) {
      url = await DatabaseMethods()
          .uploadFile(file, myUserName, time.toString(), fileType);
      size = double.parse(fileType.split('_')[1]);
      ab = "bytes";
      if (size >= 1024) {
        size = size / 1024; //kb
        ab = "kb";
      }
      if (size >= 1024) {
        size = size / 1024; //mb
        ab = "mb";
      }
    }
    Map<String, dynamic> postInfoMap = {
      "ts": time,
      "posted_by": myUserName,
      "userImg": myUserImg,
      "url": url,
      "likes": [],
      "comments": [],
      "desc": _textEditingController.text,
      "type": image.isNotEmpty
          ? "image"
          : video.isNotEmpty
              ? "video"
              : file.isNotEmpty
                  ? "file" +
                      '_' +
                      fileType.split('_')[0] +
                      '_' +
                      size.ceil().toString() +
                      ab
                  : "text",
    };
    postId = myUserId + "_" + myDisplayName + "_" + time.toString();
    await DatabaseMethods()
        .addPost(myUserId, postId, postInfoMap)
        .then((value) {
      image.clear();
      file.clear();
      _textEditingController.text = "";
      if (video.isNotEmpty) {
        video.clear();
        Navigator.of(context)
            .push(MaterialPageRoute(builder: (context) => VideoPlayerUi(url)));
      }
      FocusScope.of(context).unfocus();
      isPosting = false;
      setState(() {});
    });
  }

  //===================Add Story========================
  File? storyImg;
  UploadTask? task;
  Future selectStoryImage(
      BuildContext context,
      ImageSource source,
      String myUserName,
      String myUserId,
      String displayName,
      String userImg) async {
    final pickedImg = await ImagePicker().pickImage(source: source);
    if (pickedImg != null) {
      storyImg = File(pickedImg.path);
      return;
      // previewStoryImage(
      //     context, storyImg!, myUserName, myUserId, displayName, userImg);
    }
    print('No image selected');
  }

  previewStoryImage(
    BuildContext context,
    File? storyFile,
    String myUserName,
    String myUserId,
    String displayName,
    String userImg,
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
            child: Stack(children: [
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
                                      displayName, userImg);
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
                                      "userImg": userImg,
                                      "displayName": displayName,
                                      "name": myUserName,
                                      "ts": Timestamp.now(),
                                      "type": "image"
                                    }).whenComplete(() async {
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
            ]),
          );
        });
  }

  Future addStory(BuildContext context, String myUserName, String myUserId,
      String displayName, String userImg) {
    return showModalBottomSheet(
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
      ),
      context: context,
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            height: 190,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(15),
            ),
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
                          onTap: () {
                            selectStoryImage(context, ImageSource.gallery,
                                    myUserName, myUserId, displayName, userImg)
                                .whenComplete(() {
                              Navigator.pop(context);
                              previewStoryImage(context, storyImg, myUserName,
                                  myUserId, displayName, userImg);
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
                          onTap: () {
                            selectStoryImage(context, ImageSource.camera,
                                    myUserName, myUserId, displayName, userImg)
                                .whenComplete(() {
                              Navigator.pop(context);
                              previewStoryImage(
                                context,
                                storyImg,
                                myUserName,
                                myUserId,
                                displayName,
                                userImg,
                              );
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
          ),
        );
      },
    );
  }
  //===========================================

  onLoading() async {
    desig = (await SharedPreferenceHelper().getDesig())!;
    if (desig == "admin") {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => AdminScreen()));
    }
    myUserName = (await SharedPreferenceHelper().getUserName())!;
    myUserImg = (await SharedPreferenceHelper().getUserProfileUrl())!;
    myUserId = (await SharedPreferenceHelper().getUserId())!;
    myDisplayName = (await SharedPreferenceHelper().getDisplayName())!;
    userList = await DatabaseMethods().getMyFriendList(myUserId);
    //=============== if user is deleted =========================
    if (!userList!.exists) {
      AuthMethods().signOut().then((value) {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => SignIn()));
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          "Your user account has been deleted by the Admin",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue,
      ));
    }
    //====================================================================================
    Map<String, dynamic> userInfo = {"active": "1"};
    await FirebaseFirestore.instance
        .collection("users")
        .doc(myUserId)
        .update(userInfo);

    onLoading2();

    setState(() {});
  }

  onLoading2() async {
    userList = await DatabaseMethods().getMyFriendList(myUserId);
    myFriends = userList!["friends"];
    myRequests = userList!["requests"];
    postsStream = await DatabaseMethods().getallposts(myFriends, myUserName);

    storiesStream = await DatabaseMethods().getallstories(myFriends);
    myStory = await DatabaseMethods().getMyStory(myUserName);

    setState(() {});
  }

  @override
  void initState() {
    onLoading();
    WidgetsBinding.instance!.addObserver(this);
    super.initState();

    _scrollController =
        new ScrollController(initialScrollOffset: savedScrollOffset)
          ..addListener(_scrollListener);
  }

  jumpToScrollOffset() {
    _scrollController.animateTo(
      savedScrollOffset,
      duration: Duration(milliseconds: 1000),
      curve: Curves.decelerate,
    );
  }

  _scrollListener() {
    savedScrollOffset = _scrollController.offset;
    // print('Saved offset---------->' + savedScrollOffset.toString());
    // print("Scroll Offset: " + _scrollController.offset.toString());
    // print("Scroll Max Extent: " +
    //     _scrollController.position.maxScrollExtent.toString());
    // print("Scroll Out Range: " +
    //     _scrollController.position.outOfRange.toString());
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    _controller = VideoPlayerController.file(File(""));
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (desig == "user") {
      String? myUserId = await SharedPreferenceHelper().getUserId();
      if (state == AppLifecycleState.resumed) {
        Map<String, dynamic> userInfo = {"active": "1"};
        await FirebaseFirestore.instance
            .collection("users")
            .doc(myUserId)
            .update(userInfo);
      } else {
        Map<String, dynamic> userInfo = {"active": "0"};
        await FirebaseFirestore.instance
            .collection("users")
            .doc(myUserId)
            .update(userInfo);
      }
    }

    super.didChangeAppLifecycleState(state);
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle.light.copyWith(
        statusBarBrightness: Brightness.light,
        statusBarIconBrightness: Brightness.light,
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
    return Scaffold(
      appBar: AppBar(
        // toolbarHeight: isSearching ? 70 : 60,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          GestureDetector(
            onTap: () {
              PageRouteTransition.push(
                  context,
                  SearchUI(
                    myDisplayname: myDisplayName,
                    myFriends: myFriends,
                    myRequests: myRequests,
                    myUserId: myUserId,
                    myUserimg: myUserImg,
                    myUsername: myUserName,
                  )).then((value) => setState(() {
                    onLoading2();
                  }));
            },
            child: Padding(
              padding: EdgeInsets.only(right: 8.0),
              child: CircleAvatar(
                backgroundColor: primaryColor,
                child: SvgPicture.asset(
                  'lib/assets/image/search.svg',
                  height: 15,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              PageRouteTransition.push(
                context,
                Messages(userId: myUserId),
              );
            },
            child: Padding(
              padding: EdgeInsets.only(right: 8.0),
              child: CircleAvatar(
                backgroundColor: primaryColor,
                child: Icon(
                  Icons.notifications,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
        title: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Social',
                style: GoogleFonts.openSans(
                  color: primaryColor,
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                ),
              ),
              TextSpan(
                text: 'ize',
                style: GoogleFonts.manrope(
                  color: primaryColor,
                  fontSize: 25,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
        // Image.asset(
        //   'lib/assets/image/logoLong.png',
        //   height: 50,
        // ),
      ),
      body: selectedScreen == 'home'
          ? RefreshIndicator(
              onRefresh: () {
                return onLoading2();
              },
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics()),
                child: Column(
                  children: [
                    Container(
                      margin: EdgeInsets.symmetric(vertical: 10),
                      padding: EdgeInsets.symmetric(vertical: 20),
                      width: double.infinity,
                      color: Colors.white,
                      child: SingleChildScrollView(
                        physics: BouncingScrollPhysics(),
                        scrollDirection: Axis.horizontal,
                        child: Padding(
                          padding: EdgeInsets.only(left: 15),
                          child: Row(
                            children: [
                              StreamBuilder<dynamic>(
                                stream: myStory,
                                builder: (context, snapShot) {
                                  if (snapShot.connectionState ==
                                      ConnectionState.active) {
                                    if (snapShot.hasData) {
                                      if (snapShot.data!.docs.length == 0) {
                                        return Stack(
                                          children: [
                                            Container(
                                              height: 150,
                                              width: 100,
                                              margin: EdgeInsets.only(
                                                right: 10,
                                                left: 10,
                                              ),
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                color: Colors.black,
                                              ),
                                              child: Stack(
                                                children: [
                                                  Align(
                                                    alignment:
                                                        Alignment.bottomCenter,
                                                    child: Padding(
                                                      padding: EdgeInsets.only(
                                                          bottom: 10),
                                                      child: Column(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .end,
                                                        children: [
                                                          GestureDetector(
                                                            onTap: () {
                                                              addStory(
                                                                  context,
                                                                  myUserName,
                                                                  myUserId,
                                                                  myDisplayName,
                                                                  myUserImg);
                                                            },
                                                            child: Container(
                                                              padding:
                                                                  EdgeInsets
                                                                      .all(7),
                                                              decoration:
                                                                  BoxDecoration(
                                                                color: Colors
                                                                    .white,
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            7),
                                                              ),
                                                              child: Icon(
                                                                Icons.add,
                                                                color: Color(
                                                                    0xff299fb5),
                                                              ),
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            height: 5,
                                                          ),
                                                          const Text(
                                                            'Add Story',
                                                            style: TextStyle(
                                                              color:
                                                                  Colors.white,
                                                              fontSize: 12,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
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
                                        DocumentSnapshot ds =
                                            snapShot.data!.docs[0];
                                        return BuildStoriesCard(
                                            ds["url"],
                                            ds["userImg"],
                                            ds["type"],
                                            ds.id,
                                            true,
                                            ds["name"],
                                            ds["displayName"],
                                            ds["ts"]);
                                      }
                                    } else {
                                      return Text("nothing");
                                    }
                                  } else {
                                    return Shimmer(
                                      child: DummyStoryCard(),
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.grey,
                                          Colors.white,
                                        ],
                                      ),
                                    );
                                  }
                                },
                              ),

                              //////////////////

                              StreamBuilder(
                                stream: storiesStream,
                                builder: (context,
                                    AsyncSnapshot<QuerySnapshot> snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.active) {
                                    if (snapshot.hasData) {
                                      if (snapshot.data!.docs.length == 0) {
                                        return Container();
                                      }
                                      return Row(
                                        children: List.generate(
                                          snapshot.data!.docs.length,
                                          (index) {
                                            DocumentSnapshot ds =
                                                snapshot.data!.docs[index];
                                            return ds['name'] == myUserName
                                                ? Container()
                                                : BuildStoriesCard(
                                                    ds["url"],
                                                    ds["userImg"],
                                                    ds["type"],
                                                    ds.id,
                                                    false,
                                                    ds["name"],
                                                    ds["displayName"],
                                                    ds["ts"],
                                                  );
                                          },
                                        ),
                                      );
                                    } else {
                                      return Container();
                                    }
                                  } else {
                                    return Shimmer(
                                      child: DummyStoryCard(),
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.grey,
                                          Colors.white,
                                        ],
                                      ),
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      margin: EdgeInsets.only(bottom: 10),
                      color: Colors.white,
                      child: Column(
                        children: [
                          Padding(
                            padding: EdgeInsets.all(20),
                            child: Row(
                              children: [
                                Flexible(
                                  child: Container(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 10),
                                    decoration: BoxDecoration(
                                      color: Color(0xfff2f7fa),
                                      borderRadius: BorderRadius.circular(5),
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                    child: TextFormField(
                                      controller: _textEditingController,
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      textCapitalization:
                                          TextCapitalization.sentences,
                                      decoration: InputDecoration(
                                        border: InputBorder.none,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 10,
                                ),
                                isPosting == false
                                    ? MaterialButton(
                                        onPressed: () {
                                          FocusScope.of(context).unfocus();
                                          if (image.isNotEmpty ||
                                              _textEditingController.text !=
                                                  "" ||
                                              video.isNotEmpty ||
                                              file.isNotEmpty) {
                                            isPosting = true;
                                            setState(() {});
                                            post();
                                          }
                                        },
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(5),
                                        ),
                                        color: primaryColor,
                                        elevation: 0,
                                        padding: EdgeInsets.symmetric(
                                            vertical: 15, horizontal: 20),
                                        child: Text(
                                          'Post',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15.5,
                                            letterSpacing: 1,
                                          ),
                                        ),
                                      )
                                    : CustomProgress(),
                              ],
                            ),
                          ),
                          //===========================================
                          image.isNotEmpty
                              ? Stack(
                                  alignment: Alignment.topRight,
                                  children: [
                                    Container(
                                      margin:
                                          EdgeInsets.symmetric(vertical: 10),
                                      width: 150,
                                      height: 150,
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(15),
                                        child: Image.file(
                                          image[0],
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    CircleAvatar(
                                      backgroundColor: Colors.black,
                                      child: IconButton(
                                        onPressed: () {
                                          image.clear();
                                          setState(() {});
                                        },
                                        icon: Icon(
                                          Icons.close,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : video.isNotEmpty
                                  ? Stack(
                                      alignment: Alignment.topRight,
                                      children: [
                                          Stack(
                                              alignment: Alignment.center,
                                              children: [
                                                FutureBuilder(
                                                    future:
                                                        _initializeVideoPlayerFuture,
                                                    builder:
                                                        (context, snapshot) {
                                                      if (snapshot
                                                              .connectionState ==
                                                          ConnectionState
                                                              .done) {
                                                        return AspectRatio(
                                                          aspectRatio:
                                                              _controller.value
                                                                  .aspectRatio,
                                                          child: VideoPlayer(
                                                              _controller),
                                                        );
                                                      } else {
                                                        return CustomProgress();
                                                      }
                                                    }),
                                                CircleAvatar(
                                                  backgroundColor: Colors.black,
                                                  child: IconButton(
                                                      onPressed: () {
                                                        setState(() {
                                                          if (_controller.value
                                                              .isPlaying) {
                                                            _controller.pause();
                                                          } else {
                                                            _controller.play();
                                                          }
                                                        });
                                                      },
                                                      icon: Icon(
                                                        _controller
                                                                .value.isPlaying
                                                            ? Icons.pause
                                                            : Icons.play_arrow,
                                                        color: Colors.white,
                                                      )),
                                                ),
                                              ]),
                                          CircleAvatar(
                                            backgroundColor: Colors.black,
                                            child: IconButton(
                                              onPressed: () {
                                                _controller.pause();
                                                video.clear();
                                                setState(() {});
                                              },
                                              icon: Icon(
                                                Icons.close,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ])
                                  : file.isNotEmpty
                                      ? Column(
                                          children: [
                                            Stack(
                                              alignment: Alignment.topRight,
                                              children: [
                                                Container(
                                                    margin:
                                                        EdgeInsets.symmetric(
                                                            vertical: 10),
                                                    width: 120,
                                                    height: 120,
                                                    child: InkWell(
                                                        onTap: () {
                                                          OpenFile.open(
                                                              file[0].path);
                                                        },
                                                        child: Stack(
                                                          alignment:
                                                              Alignment.center,
                                                          children: [
                                                            Icon(
                                                              Icons.description,
                                                              size: 100,
                                                              color: Colors
                                                                  .lightGreen,
                                                            ),
                                                            Container(
                                                              color: Colors
                                                                  .black38,
                                                              child: Text(
                                                                "Tap to open",
                                                                style: TextStyle(
                                                                    color: Colors
                                                                        .white,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold),
                                                              ),
                                                            )
                                                          ],
                                                        ))),
                                                CircleAvatar(
                                                  backgroundColor: Colors.black,
                                                  child: IconButton(
                                                    onPressed: () {
                                                      file.clear();
                                                      setState(() {});
                                                    },
                                                    icon: Icon(
                                                      Icons.close,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Text(fileType.split('_')[0])
                                          ],
                                        )
                                      : Container(),
                          //=================================================================
                          Divider(
                            color: Colors.grey.shade400,
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    getImage();
                                  },
                                  child: Container(
                                    color: Colors.transparent,
                                    padding: EdgeInsets.all(10),
                                    child: Row(
                                      children: [
                                        SvgPicture.asset(
                                          'lib/assets/image/picture.svg',
                                          color: Colors.pink,
                                          height: 17,
                                        ),
                                        SizedBox(
                                          width: 10,
                                        ),
                                        Text(
                                          'Photo',
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Container(
                                  height: 20,
                                  width: 1,
                                  color: Colors.grey.shade400,
                                ),
                                GestureDetector(
                                  onTap: () {
                                    getVideo();
                                  },
                                  child: Container(
                                    color: Colors.transparent,
                                    padding: EdgeInsets.all(10),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.videocam,
                                          color: primaryColor,
                                        ),
                                        SizedBox(
                                          width: 10,
                                        ),
                                        Text(
                                          'Video',
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Container(
                                  height: 20,
                                  width: 1,
                                  color: Colors.grey.shade400,
                                ),
                                GestureDetector(
                                  onTap: () {
                                    getFile();
                                  },
                                  child: Container(
                                    color: Colors.transparent,
                                    padding: EdgeInsets.all(10),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.description,
                                          color: Colors.amber.shade600,
                                        ),
                                        SizedBox(
                                          width: 10,
                                        ),
                                        Text(
                                          'File',
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontWeight: FontWeight.w700,
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
                      ),
                    ),
                    StreamBuilder<dynamic>(
                      stream: postsStream,
                      builder: (context, snapShot) {
                        if (snapShot.connectionState !=
                            ConnectionState.active) {
                          return Shimmer(
                            child: DummyPostCard(),
                            gradient: LinearGradient(
                              colors: [
                                Colors.grey,
                                Colors.white,
                              ],
                            ),
                          );
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
                          jumpToScrollOffset();
                          return ListView.builder(
                            itemCount: snapShot.data.docs.length,
                            physics: NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            itemBuilder: (context, index) {
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
                          );
                        } else {
                          return Shimmer(
                            child: DummyPostCard(),
                            gradient: LinearGradient(
                              colors: [
                                Colors.grey,
                                Colors.white,
                              ],
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            )
          : selectedScreen == 'profile'
              ? ProfileUi()
              : ChatsUi(
                  myUserName: myUserName,
                  myProfilePic: myUserImg,
                  myUserId: myUserId,
                ),
      bottomNavigationBar: BottomNavigationBar(
        selectedLabelStyle: TextStyle(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontWeight: FontWeight.w600,
        ),
        backgroundColor: Colors.white,
        enableFeedback: true,
        items: [
          BottomNavigationBarItem(
            activeIcon: SvgPicture.asset(
              'lib/assets/image/home_filled.svg',
              color: primaryColor,
              height: 20,
            ),
            icon: SvgPicture.asset(
              'lib/assets/image/home.svg',
              color: primaryColor.withOpacity(0.5),
              height: 15,
            ),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            activeIcon: SvgPicture.asset(
              'lib/assets/image/chat_filled.svg',
              color: primaryColor,
              height: 20,
            ),
            icon: SvgPicture.asset(
              'lib/assets/image/chat.svg',
              color: primaryColor.withOpacity(0.5),
              height: 15,
            ),
            label: 'Chats',
          ),
          BottomNavigationBarItem(
            activeIcon: SvgPicture.asset(
              'lib/assets/image/profile_filled.svg',
              color: primaryColor,
              height: 20,
            ),
            icon: SvgPicture.asset(
              'lib/assets/image/profile.svg',
              height: 15,
              color: primaryColor.withOpacity(0.5),
            ),
            label: 'Profile',
          ),
        ],
        currentIndex: selectedScreen == 'home'
            ? 0
            : selectedScreen == 'chat'
                ? 1
                : 2,
        onTap: (value) {
          if (value == 0)
            setState(() {
              selectedScreen = 'home';
            });
          if (value == 1)
            setState(() {
              selectedScreen = 'chat';
            });
          if (value == 2)
            setState(() {
              selectedScreen = 'profile';
            });
        },
      ),

      ////////////////////////////////////////////////////
      // Container(
      //   padding: EdgeInsets.symmetric(
      //     horizontal: 20,
      //   ),
      //   margin: EdgeInsets.only(bottom: 10),
      //   width: double.infinity,
      //   height: 60,
      //   decoration: BoxDecoration(
      //     color: Colors.white,
      //   ),
      //   child: Row(
      //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
      //     children: [
      //       MaterialButton(
      //         onPressed: () async {
      //           // userList = await DatabaseMethods().getMyFriendList(myUserId);
      //           // myFriends = userList!["friends"];
      //           // myRequests = userList!["requests"];

      //           setState(() {
      //             selectedScreen = 'home';
      //           });
      //         },
      //         shape: RoundedRectangleBorder(
      //           borderRadius: BorderRadius.circular(12),
      //         ),
      //         elevation: 0,
      //         color: selectedScreen == 'home'
      //             ? primaryColor.withOpacity(0.1)
      //             : Colors.transparent,
      //         highlightElevation: 0,
      //         child: SvgPicture.asset(
      //           selectedScreen == 'home'
      //               ? 'lib/assets/image/home_filled.svg'
      //               : 'lib/assets/image/home.svg',
      //           height: 15,
      //           color: primaryColor,
      //         ),
      //       ),
      //       MaterialButton(
      //         onPressed: () {
      //           setState(() {
      //             selectedScreen = 'chat';
      //           });
      //         },
      //         shape: RoundedRectangleBorder(
      //           borderRadius: BorderRadius.circular(12),
      //         ),
      //         elevation: 0,
      //         color: selectedScreen == 'chat'
      //             ? primaryColor.withOpacity(0.1)
      //             : Colors.transparent,
      //         highlightElevation: 0,
      //         child: SvgPicture.asset(
      //           selectedScreen == 'chat'
      //               ? 'lib/assets/image/chat_filled.svg'
      //               : 'lib/assets/image/chat.svg',
      //           height: 15,
      //           color: primaryColor,
      //         ),
      //       ),
      //       MaterialButton(
      //         onPressed: () {
      //           setState(() {
      //             selectedScreen = 'profile';
      //           });
      //         },
      //         shape: RoundedRectangleBorder(
      //           borderRadius: BorderRadius.circular(12),
      //         ),
      //         elevation: 0,
      //         color: selectedScreen == 'profile'
      //             ? primaryColor.withOpacity(0.1)
      //             : Colors.transparent,
      //         highlightElevation: 0,
      //         child: SvgPicture.asset(
      //           selectedScreen == 'profile'
      //               ? 'lib/assets/image/profile_filled.svg'
      //               : 'lib/assets/image/profile.svg',
      //           height: 15,
      //           color: primaryColor,
      //         ),
      //       ),
      //     ],
      //   ),
      // ),
    );
  }

  Widget BuildStoriesCard(
      String storyUrl,
      String userImg,
      String type,
      String storyId,
      bool isMe,
      String userName,
      String displayName,
      Timestamp time) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => StoryUi(
                      myUserId: myUserId,
                      myUserImg: myUserImg,
                      myUserName: myUserName,
                      myDisplayName: myDisplayName,
                      time: time,
                      imgUrl: storyUrl,
                      storyId: storyId,
                      isMe: isMe,
                      userImg: userImg,
                      userName: userName,
                      displayName: displayName,
                    ))).then((value) => setState(() {}));
      },
      child: Container(
        height: 150,
        width: 100,
        margin: EdgeInsets.only(right: 10),
        decoration: type == "image"
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey.shade300,
                image: DecorationImage(
                  image: NetworkImage(
                    storyUrl,
                  ),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withOpacity(0.05),
                    BlendMode.darken,
                  ),
                ),
              )
            : BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.lightBlueAccent.withOpacity(0.6),
              ),
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: Container(
                margin: EdgeInsets.only(top: 10, left: 10),
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.circular(10),
                  image: DecorationImage(
                    image: NetworkImage(
                      userImg,
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            type == "video"
                ? Align(
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.fullscreen,
                      color: Colors.white,
                      size: 50,
                    ),
                  )
                : Container()
          ],
        ),
      ),
    );
  }
}
