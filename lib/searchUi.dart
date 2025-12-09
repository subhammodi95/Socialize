import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:page_route_transition/page_route_transition.dart';
import 'package:social_media_app/colors.dart';
import 'package:social_media_app/home.dart';
import 'package:social_media_app/user_profile.dart';

import 'services/story_widgets.dart';

class SearchUI extends StatefulWidget {
  final myUsername;
  final myDisplayname;
  final myFriends;
  final myRequests;
  final myUserimg;
  final myUserId;
  SearchUI({
    this.myUsername,
    this.myDisplayname,
    this.myFriends,
    this.myRequests,
    this.myUserId,
    this.myUserimg,
  });

  @override
  State<SearchUI> createState() => _SearchUIState();
}

class _SearchUIState extends State<SearchUI> {
  bool isShowUsers = false;
  TextEditingController searchController = TextEditingController();

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        toolbarHeight: 75,
        elevation: 0,
        leading: Padding(
          padding: EdgeInsets.only(top: 10, left: 10, bottom: 10),
          child: CircleAvatar(
            radius: 20,
            backgroundColor: primaryColor,
            child: IconButton(
              onPressed: () {
                FocusScope.of(context).unfocus();
                Navigator.pop(context);
              },
              icon: SvgPicture.asset(
                'lib/assets/image/back.svg',
                color: Colors.white,
              ),
            ),
          ),
        ),
        title: Container(
          padding: EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(50),
          ),
          child: Row(
            children: [
              SvgPicture.asset(
                'lib/assets/image/search.svg',
                color: primaryColor,
                height: 20,
              ),
              SizedBox(
                width: 10,
              ),
              Flexible(
                child: TextFormField(
                  controller: searchController,
                  textCapitalization: TextCapitalization.sentences,
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w500,
                    fontSize: 17,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Search for user',
                    hintStyle: TextStyle(
                      fontWeight: FontWeight.w400,
                      color: primaryColor.withOpacity(0.5),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      isShowUsers = true;
                    });
                    if (value.isEmpty) {
                      setState(() {
                        isShowUsers = false;
                      });
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      body: isShowUsers
          ? Padding(
              padding: EdgeInsets.all(5),
              child: Column(
                children: [
                  FutureBuilder<dynamic>(
                    future:
                        FirebaseFirestore.instance.collection('users').get(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return CustomProgress();
                      }
                      return ListView.builder(
                        itemCount: snapshot.data.docs.length,
                        shrinkWrap: true,
                        itemBuilder: (context, index) {
                          DocumentSnapshot ds = snapshot.data.docs[index];

                          if (ds['name'].toString().toLowerCase().contains(
                              searchController.text.trim().toLowerCase())) {
                            return ds['name'] == widget.myDisplayname
                                ? Container()
                                : UserTile(context, ds);
                          } else if (ds['username']
                              .toString()
                              .contains(searchController.text.trim())) {
                            return ds['username'] == widget.myUsername
                                ? Container()
                                : UserTile(context, ds);
                          } else {
                            return Container();
                          }
                        },
                      );
                    },
                  ),
                  //====================================================

                  Divider(),

                  FutureBuilder<dynamic>(
                    future: FirebaseFirestore.instance
                        .collection('users')
                        .where('name',
                            isLessThanOrEqualTo: searchController.text)
                        .get(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return CustomProgress();
                      }
                      return ListView.builder(
                        itemCount: snapshot.data.docs.length,
                        shrinkWrap: true,
                        itemBuilder: (context, index) {
                          DocumentSnapshot ds = snapshot.data.docs[index];
                          // if(snapshot)
                          return UserTile(context, ds);
                        },
                      );
                    },
                  ),
                ],
              ),
            )
          : Container(
              margin: EdgeInsets.only(top: 100),
              child: Center(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      'lib/assets/image/search.svg',
                      height: 25,
                      color: Colors.grey.shade400,
                    ),
                    Text(
                      'Search',
                      style: TextStyle(
                        fontSize: 30,
                        color: Colors.grey.shade400,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'for friends',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.grey.shade400,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  GestureDetector UserTile(BuildContext context, DocumentSnapshot<Object?> ds) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();

        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => UserProfile(
                      myDisplayName: widget.myDisplayname,
                      myImgUrl: widget.myUserimg,
                      myUserId: widget.myUserId,
                      myUserName: widget.myUsername,
                      userId: ds.id,
                      userName: ds['username'],
                    )));
      },
      child: ds['username'] == widget.myUsername
          ? Container()
          : ListTile(
              leading: Container(
                height: 45,
                width: 45,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(
                    color: ds['active'] == '1' ? Colors.green : Colors.red,
                    width: 2,
                  ),
                  image: DecorationImage(
                    image: NetworkImage(
                      ds['imgUrl'],
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ds['name'],
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(
                    height: 5,
                  ),
                  Text(
                    '@' + ds['username'],
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                      color: Colors.teal.shade900,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
