import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:social_media_app/colors.dart';
import 'package:social_media_app/services/story_widgets.dart';
import '/services/database.dart';
import '/services/sharedPref_helper.dart';

class EditProfile extends StatefulWidget {
  // const EditProfile({ Key? key }) : super(key: key);

  @override
  _EditProfileState createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  bool isLoading = false, uploadingImg = false;
  late String userId, myUserImg = "", myName, myEmail = "";
  final TextEditingController _phone = TextEditingController(text: "");
  final TextEditingController _name = TextEditingController(text: "");
  final TextEditingController _email = TextEditingController(text: "");
  Future updateProfile() async {
    setState(() {
      isLoading = true;
    });
    Map<String, dynamic> userInfoMap = {
      "imgUrl": myUserImg,
      "name": _name.text,
      "phone": _phone.text
    };
    await DatabaseMethods()
        .updateDetails(userInfoMap, userId)
        .then((value) async {
      await SharedPreferenceHelper().savePhoneNumber(_phone.text);
      await SharedPreferenceHelper().saveDisplayName(_name.text);
      await SharedPreferenceHelper().saveUserProfileUrl(myUserImg);
    });
    setState(() {
      isLoading = false;
    });
  }

  void _pickImage(String source) async {
    var pickImageFile;
    if (source == "camera") {
      pickImageFile = (await ImagePicker().pickImage(
          source: ImageSource.camera, imageQuality: 50, maxWidth: 250))!;
    } else {
      pickImageFile = (await ImagePicker().pickImage(
          source: ImageSource.gallery, imageQuality: 50, maxWidth: 250))!;
    }
    if (pickImageFile != null) {
      uploadingImg = true;
      setState(() {});
      DatabaseMethods()
          .uploadGroupImg(File(pickImageFile.path), userId)
          .then((imgUrl) {
        Map<String, dynamic> userInfoMap = {
          "imgUrl": imgUrl,
        };
        DatabaseMethods().updateDetails(userInfoMap, userId).then((value) {
          SharedPreferenceHelper().saveUserProfileUrl(imgUrl);
          myUserImg = imgUrl;
          uploadingImg = false;
          pickImageFile = null;
          setState(() {});
        });
      });
    }
  }

  onLaunch() async {
    String phoneNumber = (await SharedPreferenceHelper().getUserPhone())!;
    userId = (await SharedPreferenceHelper().getUserId())!;
    myUserImg = (await SharedPreferenceHelper().getUserProfileUrl())!;
    myName = (await SharedPreferenceHelper().getDisplayName())!;
    myEmail = (await SharedPreferenceHelper().getUserEmail())!;
    _phone.text = phoneNumber;
    _name.text = myName;
    _email.text = myEmail;
    setState(() {});
  }

  @override
  void dispose() {
    _phone.dispose();
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  @override
  void initState() {
    onLaunch();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle.light.copyWith(
        statusBarBrightness: Brightness.light,
        statusBarIconBrightness: Brightness.light,
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
    return Scaffold(
      backgroundColor: Colors.white,
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
          'Edit Profile',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Form(
          // key: formKey,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.blueGrey.shade100,
                            backgroundImage: myUserImg != ""
                                ? NetworkImage(myUserImg)
                                : null,
                          ),
                          Positioned(
                            top: 70,
                            left: 70,
                            child: GestureDetector(
                              onTap: () {
                                showModalBottomSheet(
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
                                        filter: ImageFilter.blur(
                                          sigmaX: 5,
                                          sigmaY: 5,
                                        ),
                                        child: Container(
                                          height: 190,
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.white.withOpacity(0.8),
                                            borderRadius:
                                                BorderRadius.circular(15),
                                          ),
                                          padding: EdgeInsets.all(20),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
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
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceAround,
                                                children: [
                                                  Column(
                                                    children: [
                                                      GestureDetector(
                                                        onTap: () {
                                                          Navigator.of(context)
                                                              .pop();
                                                          _pickImage("gallery");
                                                        },
                                                        child: CircleAvatar(
                                                          backgroundColor:
                                                              Color(0xFFFCE0EA),
                                                          radius: 30,
                                                          child:
                                                              SvgPicture.asset(
                                                            'lib/assets/image/picture.svg',
                                                            color: Colors
                                                                .pink.shade600,
                                                          ),
                                                        ),
                                                      ),
                                                      SizedBox(
                                                        height: 7,
                                                      ),
                                                      Text(
                                                        'Gallery',
                                                        style: TextStyle(
                                                          color: Colors
                                                              .grey.shade800,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  Column(
                                                    children: [
                                                      GestureDetector(
                                                        onTap: () {
                                                          Navigator.of(context)
                                                              .pop();
                                                          _pickImage("camera");
                                                        },
                                                        child: CircleAvatar(
                                                          backgroundColor:
                                                              Color.fromARGB(
                                                                  255,
                                                                  220,
                                                                  239,
                                                                  255),
                                                          radius: 30,
                                                          child:
                                                              SvgPicture.asset(
                                                            'lib/assets/image/camera.svg',
                                                            color: Colors
                                                                .blue.shade600,
                                                          ),
                                                        ),
                                                      ),
                                                      SizedBox(
                                                        height: 7,
                                                      ),
                                                      Text(
                                                        'Camera',
                                                        style: TextStyle(
                                                          color: Colors
                                                              .grey.shade800,
                                                          fontWeight:
                                                              FontWeight.w500,
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
                                    });
                              },
                              child: CircleAvatar(
                                radius: 15,
                                backgroundColor: primaryScaffoldColor,
                                child: Icon(
                                  Icons.edit,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                          uploadingImg
                              ? CircleAvatar(
                                  radius: 50,
                                  backgroundColor: Colors.white54,
                                  child: CustomProgress(),
                                )
                              : SizedBox(),
                        ],
                      ),
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.05,
                      ),
                      Column(
                        children: [
                          BuildCustomTextField(
                            label: 'Name',
                            read_only: false,
                            textCapitalization: TextCapitalization.sentences,
                            textEditingController: _name,
                            keyboardType: TextInputType.text,
                          ),
                          BuildCustomTextField(
                            label: 'Phone',
                            read_only: false,
                            textCapitalization: TextCapitalization.sentences,
                            textEditingController: _phone,
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value!.isEmpty) {
                                return 'This Field is required';
                              } else if (value.toString().length != 10) {
                                return 'Phone number should be of 10 digits';
                              }
                              return null;
                            },
                          ),
                          BuildCustomTextField(
                            label: 'Email',
                            read_only: true,
                            textEditingController: _email,
                            keyboardType: TextInputType.text,
                            validator: (value) {
                              if (value!.isEmpty) {
                                return 'This Field is required';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                height: 20,
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: MaterialButton(
                  onPressed: () {
                    if (_name.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Name should not be empty")));
                    } else if (_name.text.toString().length > 20) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(
                              "Name should not be more than 20 characters")));
                    } else if (_phone.text.isNotEmpty) {
                      if (_phone.text.toString().length != 10) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content:
                                Text("Phone number should be of 10 digits")));
                      } else {
                        updateProfile();
                      }
                    } else {
                      updateProfile();
                    }
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
                    child: Center(
                      child: isLoading
                          ? CustomProgress()
                          : Text(
                              'Update Details',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget BuildCustomTextField(
      {final label,
      final textCapitalization,
      final textEditingController,
      final validator,
      final keyboardType,
      final read_only}) {
    return Container(
      margin: EdgeInsets.only(bottom: 15),
      // padding: EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade600.withOpacity(0.1),
        borderRadius: BorderRadius.circular(5),
      ),
      child: TextFormField(
        keyboardType: keyboardType,
        controller: textEditingController,
        readOnly: read_only,
        style: TextStyle(
          color: Colors.grey.shade600,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          contentPadding: EdgeInsets.all(10),
          border: InputBorder.none,
          labelText: label,
          labelStyle: TextStyle(
            color: primaryColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        validator: validator,
      ),
    );
  }
}
