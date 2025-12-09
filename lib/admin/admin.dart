import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:jiffy/jiffy.dart';
import 'package:open_file/open_file.dart';
import 'package:page_route_transition/page_route_transition.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:social_media_app/feeds.dart';
import './adminUserProfile.dart';
import 'package:social_media_app/services/database.dart';
import 'package:pdf/widgets.dart' as pw;

import '../colors.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({Key? key}) : super(key: key);

  @override
  _AdminScreenState createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  TextEditingController adminEmail = TextEditingController();
  TextEditingController searchText = TextEditingController();
  TextEditingController day = TextEditingController();
  TextEditingController month = TextEditingController();
  TextEditingController year = TextEditingController();
  Stream<QuerySnapshot>? allUserStream;
  Stream<QuerySnapshot>? allPostsStream;
  String screen = "users";
  String option = "All";
  var userList;
  bool isSearching = false;

  Future searchPost() async {
    // Size size = MediaQuery.of(context).size;
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: false,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              padding: EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  // mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Enter Time",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 30,
                      ),
                    ),
                    Text(
                      "Enter at least one field",
                      style: TextStyle(
                        fontSize: 15,
                      ),
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: TextField(
                            controller: day,
                            keyboardType: TextInputType.visiblePassword,
                            decoration: InputDecoration(
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 15,
                                vertical: 15,
                              ),
                              labelText: "Day",
                              hintText: "9th",
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: TextField(
                            controller: month,
                            textCapitalization: TextCapitalization.words,
                            keyboardType: TextInputType.text,
                            decoration: InputDecoration(
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 15,
                                vertical: 15,
                              ),
                              labelText: "Month",
                              hintText: "May",
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: TextField(
                            controller: year,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 15,
                                vertical: 15,
                              ),
                              labelText: "Year",
                              hintText: "2001",
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    MaterialButton(
                      onPressed: () {
                        setModalState(() {
                          screen = "posts";
                        });
                        setState(() {});
                        Navigator.pop(context);
                      },
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                      color: primaryColor,
                      elevation: 0,
                      padding:
                          EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                      child: Text(
                        "Search",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: MediaQuery.of(context).viewInsets.bottom,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future addAdmin() {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: false,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, StateSetter setModalState) {
            return Container(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Add Admin",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: TextField(
                      controller: adminEmail,
                      keyboardType: TextInputType.visiblePassword,
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 15,
                        ),
                        labelText: "Email",
                        hintText: "Enter email of new admin",
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  MaterialButton(
                    onPressed: () async {
                      if (adminEmail.text.trim() != "" &&
                          adminEmail.text.contains("@")) {
                        final snapShot = await FirebaseFirestore.instance
                            .collection("users")
                            .where("email", isEqualTo: adminEmail.text)
                            .get();
                        if (snapShot.docs.length == 0) {
                          final s = await FirebaseFirestore.instance
                              .collection("admins")
                              .doc(adminEmail.text
                                  .trim()
                                  .replaceAll("@gmail.com", ""))
                              .get();
                          if (s.exists) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Admin exists",
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          } else {
                            await FirebaseFirestore.instance
                                .collection("admins")
                                .doc(adminEmail.text
                                    .trim()
                                    .replaceAll("@gmail.com", ""))
                                .set({"email": adminEmail.text.trim()});
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Admin added",
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
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "User with same Email Id already exist",
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
                      } else {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              "Invalid Email Id",
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
                    },
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5)),
                    color: primaryColor,
                    elevation: 0,
                    padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                    child: Text(
                      "Submit",
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
      },
    );
  }

  Future geth() async {
    allUserStream =
        await FirebaseFirestore.instance.collection("users").snapshots();
    final data = allUserStream!.map((event) {
      userList = event.docs
          .map((e) => [
                e.id,
                e["name"],
                e["email"],
                e["phone"],
                e["friends"].length.toString(),
                e["requests"].length.toString(),
                e["imgUrl"]
              ])
          .toList();

      print('userList =========> ' + userList.toString());
    }).toList();
  }

  Future generate_userList() async {
    await geth();
    setState(() {});
    if (userList == null) {
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
      'Name',
      'Email',
      'Phone',
      'Friends',
      'Requests',
      'Image'
    ];
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Column(
            children: [
              pw.Text("Users on Socialize",
                  style: pw.TextStyle(
                    fontSize: 30,
                    fontWeight: pw.FontWeight.bold,
                    fontStyle: pw.FontStyle.italic,
                  )),
              pw.Padding(padding: const pw.EdgeInsets.all(5)),
              pw.Table.fromTextArray(
                headers: headers,
                data: userList,
                columnWidths: {
                  0: pw.FlexColumnWidth(2),
                  1: pw.FlexColumnWidth(2),
                  2: pw.FlexColumnWidth(2),
                  3: pw.FlexColumnWidth(3),
                  4: pw.FlexColumnWidth(1),
                  5: pw.FlexColumnWidth(1),
                  6: pw.FlexColumnWidth(3),
                },
                cellStyle: pw.TextStyle(fontSize: 10),
              )
            ],
          ),
        ],
      ),
    );
    //===========SAVE PDF==================
    try {
      Directory directory;
      if (await _requestpermission(Permission.storage)) {
        directory = (await getExternalStorageDirectory())!;
        print('Directory ----------> ' + directory.toString());

        String newpath = "";
        List<String> folders =
            directory.path.split("/"); //to reach the Android folder
        print('Folder ------> ' + folders.toString());
        for (int x = 1; x < folders.length; x++) {
          //x=1 because at x=0 is empty
          String folder = folders[x];
          if (folder != "Android") {
            newpath += "/" + folder;
          } else {
            break;
          }
        }
        // newpath = directory.path.replaceAll('data', 'media');

        newpath = newpath + "/Socialize/UsersList";
        print('Newpath-----> ' + newpath);
        directory = Directory(newpath);

        if (!await directory.exists()) {
          //if directory extracted does not exists, create one
          await directory.create(recursive: true);
        }
        if (await directory.exists()) {
          print('here1');
          String filename = DateTime.now().toString();
          File savedfile = File(directory.path + "/$filename.pdf");
          print('savedfile ------> ' + savedfile.toString());
          await savedfile.writeAsBytes(await pdf.save());

          OpenFile.open(directory.path + "/$filename.pdf");
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "File Saved " + savedfile.toString(),
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
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
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
      print(e);
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
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

  Widget UserCard(DocumentSnapshot ds) {
    return GestureDetector(
      onTap: () {
        PageRouteTransition.push(
          context,
          AdminUserProfile(
            ds.id,
            ds['username'],
            ds['email'],
            ds['tokenId'],
          ),
        );
      },
      child: Container(
        // padding: EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.all(
            Radius.circular(10),
          ),
        ),
        margin: EdgeInsets.only(bottom: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.all(15),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 60,
                    width: 60,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(
                        image: NetworkImage(
                          ds["imgUrl"],
                        ),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 10,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: 'Name: ',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                  fontSize: 16,
                                ),
                              ),
                              TextSpan(
                                text: ds["name"],
                                style: TextStyle(
                                  // fontWeight: FontWeight.w600,
                                  color: Colors.black, fontSize: 16,
                                ),
                              ),
                              TextSpan(
                                text: '\nEmail: ',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                  fontSize: 16,
                                ),
                              ),
                              TextSpan(
                                text: ds["email"],
                                style: TextStyle(
                                  // fontWeight: FontWeight.w600,
                                  color: Colors.black, height: 1.5,
                                  fontSize: 16,
                                ),
                              ),
                              TextSpan(
                                text: '\nUsername: ',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                  fontSize: 16,
                                ),
                              ),
                              TextSpan(
                                text: ds["username"],
                                style: TextStyle(
                                  // fontWeight: FontWeight.w600,
                                  color: Colors.black, height: 1.5,
                                  fontSize: 16,
                                ),
                              ),
                              TextSpan(
                                text: '\nUser ID: ',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                  fontSize: 16,
                                ),
                              ),
                              TextSpan(
                                text: ds.id,
                                style: TextStyle(
                                  // fontWeight: FontWeight.w600,
                                  color: Colors.black, height: 1.5,
                                  fontSize: 16,
                                ),
                              ),
                              TextSpan(
                                text: '\nStatus: ',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                  fontSize: 16,
                                ),
                              ),
                              TextSpan(
                                text:
                                    ds["active"] == "1" ? "Active" : "Inactive",
                                style: TextStyle(
                                  // fontWeight: FontWeight.w600,
                                  color: Colors.black, fontSize: 16,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
            SizedBox(
              height: 15,
            ),
            MaterialButton(
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection("users")
                    .doc(ds.id)
                    .delete()
                    .then((value) async {
                  QuerySnapshot snapshot = await FirebaseFirestore.instance
                      .collection("posts")
                      .where("posted_by", isEqualTo: ds["username"])
                      .get();
                  for (DocumentSnapshot doc in snapshot.docs) {
                    doc.reference.delete();
                  }
                });
                DatabaseMethods().sendNotification([ds["tokenId"]],
                    "Your account has been deleted by the admin", "Alert", "");
              },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(0),
              ),
              color: Colors.red.shade600,
              elevation: 0,
              child: Container(
                width: double.infinity,
                child: Text(
                  'Delete user',
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 10,
            ),
          ],
        ),
      ),
    );
  }

  onLaunch() async {
    allUserStream =
        await FirebaseFirestore.instance.collection("users").snapshots();
    allPostsStream =
        await FirebaseFirestore.instance.collection("posts").snapshots();
    // print("object");
    // final data = allUserStream!.map((event) {
    //   userList = event.docs
    //       .map((e) => [
    //             e.id,
    //             e["name"],
    //             e["username"],
    //             e["email"],
    //             e["phone"],
    //             e["friends"].length.toString(),
    //             e["requests"].length.toString(),
    //             e["imgUrl"]
    //           ])
    //       .toList();
    //   print("object2");
    //   print(userList);
    // }).toList();
    setState(() {});
  }

  @override
  void initState() {
    onLaunch();
    super.initState();
    geth();
  }

  @override
  void dispose() {
    adminEmail.dispose();
    searchText.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle.light.copyWith(
        statusBarBrightness: Brightness.light,
        statusBarIconBrightness: Brightness.dark,
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        toolbarHeight: 70,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: screen == 'posts'
            ? IconButton(
                onPressed: () {
                  setState(() {
                    screen = 'users';
                  });
                },
                icon: SvgPicture.asset(
                  'lib/assets/image/back.svg',
                  color: Colors.black,
                ),
              )
            : null,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              screen == 'users' ? "Users" : 'Posts',
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              "on Socialize",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
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
          ),
          screen == 'users'
              ? IconButton(
                  icon: SvgPicture.asset(
                    'lib/assets/image/filter.svg',
                    color: primaryColor,
                  ),
                  onPressed: () async {
                    return showMenu(
                      elevation: 10,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      color: Colors.white,
                      context: context,
                      position: RelativeRect.fromLTRB(300, 70, 0.0, 0.0),
                      items: [
                        PopupMenuButton(context, text: 'All', label: 'All'),
                        PopupMenuButton(context, text: 'Name', label: 'Name'),
                        PopupMenuButton(context, text: 'Email', label: 'Email'),
                        PopupMenuButton(context, text: '1', label: 'Active'),
                        PopupMenuButton(context, text: '0', label: 'Inactive'),
                      ],
                    );
                  },
                )
              : Container(),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          child: screen == "users"
              ? Padding(
                  padding: EdgeInsets.all(13),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (option == "Name" || option == "Email")
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 15),
                          margin: EdgeInsets.only(bottom: 15),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: Row(
                            children: [
                              InkWell(
                                onTap: () {},
                                child: SvgPicture.asset(
                                  'lib/assets/image/search.svg',
                                  color: primaryColor,
                                  height: 17,
                                ),
                              ),
                              SizedBox(
                                width: 10,
                              ),
                              Flexible(
                                child: TextFormField(
                                  controller: searchText,
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 17,
                                  ),
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    hintText: 'Search for Users',
                                    hintStyle: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                  onChanged: (value) {
                                    if (value.trim() != "") {
                                      setState(() {
                                        isSearching = true;
                                      });
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      StreamBuilder<dynamic>(
                        stream: allUserStream,
                        builder: (context, snapShot) {
                          if (snapShot.connectionState !=
                              ConnectionState.active) {
                            return Center(
                              child: CircularProgressIndicator(
                                color: primaryColor,
                                strokeWidth: 1.5,
                              ),
                            );
                          }
                          if (snapShot.hasError) {
                            return const Center(
                              child: Text("Error in receiving users"),
                            );
                          } else if (snapShot.hasData) {
                            if (snapShot.data!.docs.isEmpty) {
                              return Center(
                                child: Text(
                                  "No Users",
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
                                  DocumentSnapshot ds =
                                      snapShot.data!.docs[index];
                                  if (option == "All") {
                                    return UserCard(ds);
                                  } else if (option == "1") {
                                    if (ds["active"] == "1") {
                                      return UserCard(ds);
                                    } else {
                                      return Container();
                                    }
                                  } else if (option == "0") {
                                    if (ds["active"] == "0") {
                                      return UserCard(ds);
                                    } else {
                                      return Container();
                                    }
                                  } else if (option == "Name") {
                                    if (ds["name"]
                                        .toString()
                                        .toLowerCase()
                                        .contains(searchText.text
                                            .trim()
                                            .toLowerCase())) {
                                      return UserCard(ds);
                                    } else {
                                      return Container();
                                    }
                                  } else {
                                    if (ds["email"]
                                        .toString()
                                        .toLowerCase()
                                        .contains(searchText.text
                                            .trim()
                                            .toLowerCase())) {
                                      return UserCard(ds);
                                    } else {
                                      return Container();
                                    }
                                  }
                                },
                              ),
                            );
                          } else {
                            return Center(
                              child: CircularProgressIndicator(
                                color: primaryColor,
                                strokeWidth: 1.5,
                              ),
                            );
                          }
                        },
                      ),
                      SizedBox(
                        height: 55,
                      ),
                    ],
                  ),
                )
              :
              //============================================
              //============== POSTS ==================
              Column(
                  children: [
                    StreamBuilder<dynamic>(
                      stream: allPostsStream,
                      builder: (context, snapShot) {
                        if (snapShot.connectionState !=
                            ConnectionState.active) {
                          return Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (snapShot.hasError) {
                          return Center(
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
                                DocumentSnapshot ds =
                                    snapShot.data!.docs[index];
                                // DAY MONTH YEAR
                                if (day.text.trim() != "" &&
                                    month.text.trim() != "" &&
                                    year.text.trim() != "") {
                                  if (Jiffy(ds["ts"].toDate())
                                          .format("do-MMMM-yyyy")
                                          .toString() ==
                                      "${day.text}-${month.text}-${year.text}") {
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
                                  } else {
                                    return Container();
                                  }
                                }
                                // DAY MONTH
                                else if (day.text.trim() != "" &&
                                    month.text.trim() != "" &&
                                    year.text.trim() == "") {
                                  if (Jiffy(ds["ts"].toDate())
                                          .format("do-MMMM")
                                          .toString() ==
                                      "${day.text}-${month.text}") {
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
                                  } else {
                                    return Container();
                                  }
                                }
                                // MONTH YEAR
                                else if (day.text.trim() == "" &&
                                    month.text.trim() != "" &&
                                    year.text.trim() != "") {
                                  if (Jiffy(ds["ts"].toDate())
                                          .format("MMMM-yyyy")
                                          .toString() ==
                                      "${month.text}-${year.text}") {
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
                                  } else {
                                    return Container();
                                  }
                                }
                                // DAY YEAR
                                else if (day.text.trim() != "" &&
                                    month.text.trim() == "" &&
                                    year.text.trim() != "") {
                                  if (Jiffy(ds["ts"].toDate())
                                          .format("do-yyyy")
                                          .toString() ==
                                      "${day.text}-${year.text}") {
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
                                  } else {
                                    return Container();
                                  }
                                }
                                // DAY
                                else if (day.text.trim() != "" &&
                                    month.text.trim() == "" &&
                                    year.text.trim() == "") {
                                  if (Jiffy(ds["ts"].toDate())
                                          .format("do")
                                          .toString() ==
                                      "${day.text}") {
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
                                  } else {
                                    return Container();
                                  }
                                }
                                // MONTH
                                else if (day.text.trim() == "" &&
                                    month.text.trim() != "" &&
                                    year.text.trim() == "") {
                                  if (Jiffy(ds["ts"].toDate())
                                          .format("MMMM")
                                          .toString() ==
                                      "${month.text}") {
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
                                  } else {
                                    return Container();
                                  }
                                }
                                // YEAR
                                else if (day.text.trim() == "" &&
                                    month.text.trim() == "" &&
                                    year.text.trim() != "") {
                                  if (Jiffy(ds["ts"].toDate())
                                          .format("yyyy")
                                          .toString() ==
                                      "${year.text}") {
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
                                  } else {
                                    return Container();
                                  }
                                }
                                // NOTHING
                                else {
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
                                }
                              },
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
                    ),
                  ],
                ),
        ),
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 50),
            child: FloatingActionButton.extended(
              heroTag: 'btn1',
              onPressed: () async {
                await searchPost();
              },
              icon: SvgPicture.asset(
                'lib/assets/image/search.svg',
                height: 15,
              ),
              elevation: 2,
              label: Text(
                "Search Posts",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          FloatingActionButton(
            heroTag: 'btn2',
            onPressed: () async {
              await addAdmin();
            },
            elevation: 2,
            // backgroundColor: primaryColor,
            child: Icon(
              Icons.add_circle_outline_sharp,
              // color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  PopupMenuItem<void> PopupMenuButton(
    BuildContext context, {
    final text,
    final label,
  }) {
    return PopupMenuItem(
      onTap: () {
        setState(() {
          option = text;
        });
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.black,
              ),
            ),
          ),
          option == text
              ? Icon(
                  Icons.done_rounded,
                  color: Colors.black,
                )
              : Container()
        ],
      ),
    );
  }
}
