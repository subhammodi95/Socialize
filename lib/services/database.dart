import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:http/http.dart';
import 'package:social_media_app/services/sharedPref_helper.dart';

class DatabaseMethods {
  Future addUserInfoToDB(
      String userId, Map<String, dynamic> userInfoMap) async {
    DocumentSnapshot snapshot =
        await FirebaseFirestore.instance.collection("users").doc(userId).get();
    // check if user details are already present in the database and also update variable details from database in shared preference
    if (snapshot.exists) {
      await SharedPreferenceHelper().saveDisplayName(snapshot["name"]);
      await SharedPreferenceHelper().savePhoneNumber(snapshot["phone"]);
      await SharedPreferenceHelper().saveUserProfileUrl(snapshot["imgUrl"]);
      return "user";
    } else {
      final snapShot = await FirebaseFirestore.instance
          .collection("admins")
          .doc(userInfoMap["username"])
          .get();
      if (snapShot.exists) {
        return "admin";
      } else {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .set(userInfoMap);
        return "user";
      }
    }
  }

  Future<Response> sendNotification(List<String> tokenIdList, String contents,
      String heading, String icon) async {
    return await post(
      Uri.parse('https://onesignal.com/api/v1/notifications'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        "app_id":
            "4d860999-7816-4eee-8c6e-656cf3e1afc9", //kAppId is the App Id that one get from the OneSignal When the application is registered.

        "include_player_ids":
            tokenIdList, //tokenIdList Is the List of All the Token Id to to Whom notification must be sent.

        // android_accent_color reprsent the color of the heading text in the notifiction
        "android_accent_color": "FF9976D2",

        "small_icon": "https://firebasestorage.googleapis.com/v0/b/social-media-app-60f40.appspot.com/o/appImg%2FlogoShort.png?alt=media&token=905b8d28-0ed0-4012-bee3-9b87a15bc10a",

        "large_icon": icon == "" ? "https://firebasestorage.googleapis.com/v0/b/social-media-app-60f40.appspot.com/o/appImg%2FlogoShort.png?alt=media&token=905b8d28-0ed0-4012-bee3-9b87a15bc10a" : icon,

        "headings": {"en": heading},

        "contents": {"en": contents},
      }),
    );
  }

  Future<Stream<QuerySnapshot>> getallposts(
      List friends, String myUserName) async {
    friends.add(myUserName);
    return await FirebaseFirestore.instance
        .collection("posts")
        .where("posted_by", whereIn: friends)
        .orderBy("ts", descending: true)
        .snapshots();
  }

  Future<Stream<QuerySnapshot>> getallstories(List friends) async {
    return await FirebaseFirestore.instance
        .collection("stories")
        .where("name", whereIn: friends)
        .orderBy("ts", descending: true)
        .snapshots();
  }

  Future<Stream<QuerySnapshot>> getMyStory(String myUserName) async {
    return await FirebaseFirestore.instance
        .collection("stories")
        .where("name", isEqualTo: myUserName)
        .snapshots();
  }

  static UploadTask? uploadStoryImg(String myUserName, File img) {
    Reference imgRef =
        FirebaseStorage.instance.ref().child('stories/$myUserName');
    return imgRef.putFile(img);
    // await imgUploadTask.whenComplete(() => null);
    // imgRef.getDownloadURL();
  }

  Future<Stream<QuerySnapshot>> getUserByname(
      String name, String myUserName) async {
    return FirebaseFirestore.instance
        .collection("users")
        .where("name", isEqualTo: name)
        .where("name", isLessThanOrEqualTo: name)
        // .where("username", isNotEqualTo: myUserName)
        .snapshots();
  }

  Future addPost(
      String myUserId, String postId, Map<String, dynamic> postInfoMap) async {
    return FirebaseFirestore.instance
        // .collection("users")
        // .doc(myUserId)
        .collection("posts")
        .doc(postId)
        .set(postInfoMap);
  }

  updateLastMessageSend(
      String chatRoomId, Map<String, dynamic> lastMessageInfoMap) {
    return FirebaseFirestore.instance
        .collection("chatrooms")
        .doc(chatRoomId)
        .update(lastMessageInfoMap);
  }

  Future<Stream<QuerySnapshot>> getChatRooms(String myUsername) async {
    print(myUsername);
    return await FirebaseFirestore.instance
        .collection("chatrooms")
        .orderBy("lastMessageSendTs", descending: true)
        .where("users", arrayContains: myUsername)
        .snapshots();
  }

  Future createChatRoom(
      String chatRoomId, Map<String, dynamic> chatRoomInfoMap) async {
    return FirebaseFirestore.instance
        .collection("chatrooms")
        .doc(chatRoomId)
        .set(chatRoomInfoMap);
  }

  Future deleteChatRoom(String chatRoomId) {
    return FirebaseFirestore.instance
        .collection("chatrooms")
        .doc(chatRoomId)
        .delete();
  }

  Future deleteThisMessage(String chatRoomId, String messageId) {
    return FirebaseFirestore.instance
        .collection("chatrooms")
        .doc(chatRoomId)
        .collection("chats")
        .doc(messageId)
        .delete();
  }

  Future addMessage(String chatRoomId, String messageId,
      Map<String, dynamic> messageInfoMap) async {
    return FirebaseFirestore.instance
        .collection("chatrooms")
        .doc(chatRoomId)
        .collection("chats")
        .doc(messageId)
        .set(messageInfoMap);
  }

  Future getChatRoomInfo(String chatRoomId) {
    return FirebaseFirestore.instance
        .collection("chatrooms")
        .doc(chatRoomId)
        .get();
  }

  // // createChatGroup(String chatRoomId, Map groupChatRoomInfoMap) async {
  // //   final snapShot = await FirebaseFirestore.instance
  // //       .collection("chatrooms")
  // //       .doc(chatRoomId)
  // //       .get();
  // // }

  Future createGroupChatRoom(
      String chatRoomId, Map<String, dynamic> chatRoomInfoMap) async {
    final snapShot = await FirebaseFirestore.instance
        .collection("chatrooms")
        .doc(chatRoomId)
        .get();
    if (snapShot.exists) {
      //chatrooom already exist

      return false;
    } else {
      return FirebaseFirestore.instance
          .collection("chatrooms")
          .doc(chatRoomId)
          .set(chatRoomInfoMap);
    }
  }

  Future<Stream<QuerySnapshot>> getChatRoomMessages(chatRoomId) async {
    return FirebaseFirestore.instance
        .collection("chatrooms")
        .doc(chatRoomId)
        .collection("chats")
        .orderBy("ts", descending: true)
        .snapshots();
  }

  Future<Stream<QuerySnapshot>> getMyPosts(String userName) async {
    // String myUsername = await SharedPreferenceHelper().getUserName();
    return FirebaseFirestore.instance
        // .collection("users")
        // .doc(userId)
        .collection("posts")
        .where("posted_by", isEqualTo: userName)
        .orderBy("ts", descending: true)
        .snapshots();
  }

  Future<Stream<QuerySnapshot>> getMyRequests(
      String myUserId, String userName) async {
    return FirebaseFirestore.instance
        .collection("users")
        .doc(myUserId)
        .collection("Requests")
        .where("userName", isEqualTo: userName)
        .snapshots();
  }

  Future getMyFriendList(String myUserId) {
    return FirebaseFirestore.instance.collection("users").doc(myUserId).get();
  }

  Future<Stream<QuerySnapshot>> getRequests(String myUserId) async {
    return FirebaseFirestore.instance
        .collection("users")
        .doc(myUserId)
        .collection("Requests")
        .snapshots();
  }

  Future<Stream<QuerySnapshot>> getFriends(String myUserId) async {
    return FirebaseFirestore.instance
        .collection("users")
        .doc(myUserId)
        .collection("Friends")
        .snapshots();
  }

  // void update(String old, String neww) async {
  //   String myUsername = await SharedPreferenceHelper().getUserName();
  //   QuerySnapshot snapshot = await FirebaseFirestore.instance
  //       .collection("chatrooms")
  //       .where("users", arrayContains: myUsername)
  //       .get();
  //   for (var i = 0; i < snapshot.docs.length; i++) {
  //     print(snapshot.docs[i].id);
  //   }
  // }
  Future updateDetails(Map<String, dynamic> userInfoMap, String userId) async {
    return FirebaseFirestore.instance
        .collection("users")
        .doc(userId)
        .update(userInfoMap);
  }

  Future<Stream<QuerySnapshot>> getUserInfo(String userName) async {
    return FirebaseFirestore.instance
        .collection("users")
        .where("username", isEqualTo: userName)
        .snapshots();
  }

  Future<QuerySnapshot> getUserInfo2(String username) async {
    return await FirebaseFirestore.instance
        .collection("users")
        .where("username", isEqualTo: username)
        .get();
  }

  Future<void> updateLike(String userId, String postId, List likes) async {
    Map<String, dynamic> likesMap = {"likes": likes};
    return FirebaseFirestore.instance
        // .collection("users")
        // .doc(userId)
        .collection("posts")
        .doc(postId)
        .update(likesMap);
  }

  Future<void> updateRequest(String userId, List requests) async {
    Map<String, dynamic> requestMap = {"requests": requests};
    return FirebaseFirestore.instance
        .collection("users")
        .doc(userId)
        .update(requestMap);
  }

  Future<void> updateRequestCollection(
    String userId,
    String operation,
    String myUserId,
    String myImgUrl,
    String myDisplayName,
    String myUserName,
    String myEmail,
  ) async {
    if (operation == "delete") {
      return await FirebaseFirestore.instance
          .collection("users")
          .doc(userId)
          .collection("Requests")
          .doc(myUserId)
          .delete();
    } else {
      Map<String, dynamic> requestMap = {
        "name": myDisplayName,
        "imgUrl": myImgUrl,
        "userName": myUserName,
        "email": myEmail,
        "ts": DateTime.now()
      };
      return FirebaseFirestore.instance
          .collection("users")
          .doc(userId)
          .collection("Requests")
          .doc(myUserId)
          .set(requestMap);
    }
  }

  Future<void> updateFriends(String userId, List friends) async {
    Map<String, dynamic> friendsMap = {"friends": friends};
    return FirebaseFirestore.instance
        .collection("users")
        .doc(userId)
        .update(friendsMap);
  }

  Future<void> updateFriendsCollection(
      String userId,
      String operation,
      String myUserId,
      String myImgUrl,
      String myDisplayName,
      String myUserName,
      String myEmail) async {
    if (operation == "delete") {
      return await FirebaseFirestore.instance
          .collection("users")
          .doc(userId)
          .collection("Friends")
          .doc(myUserId)
          .delete();
    } else {
      Map<String, dynamic> friendMap = {
        "name": myDisplayName,
        "imgUrl": myImgUrl,
        "userName": myUserName,
        "email": myEmail,
        "ts": DateTime.now()
      };
      return FirebaseFirestore.instance
          .collection("users")
          .doc(userId)
          .collection("Friends")
          .doc(myUserId)
          .set(friendMap);
    }
  }

  // Future updateImg(String myUserId, Map userInfoMap) async {
  //   return FirebaseFirestore.instance
  //       .collection("users")
  //       .doc(myUserId)
  //       .update(userInfoMap);
  // }

  Future<Stream<QuerySnapshot>> getCommentsStream(
      String userId, String postId) async {
    return await FirebaseFirestore.instance
        // .collection("users")
        // .doc(userId)
        .collection("posts")
        .doc(postId)
        .collection("Comments")
        .orderBy("ts", descending: true)
        .snapshots();
  }

  Future postDetails(String userId, String postId) async {
    return await FirebaseFirestore.instance
        // .collection("users")
        // .doc(userId)
        .collection("posts")
        .doc(postId)
        .get();
  }

  Future deleteThisPost(String userId, String postId, String url) async {
    await FirebaseFirestore.instance.collection("posts").doc(postId).delete();
    return await deleteImg(url);
  }

  Future deleteImg(String url) async {
    await FirebaseStorage.instance.refFromURL(url).delete();
  }

  Future<String> uploadImg(
      List<File> img, String myUserName, String time) async {
    final ref = FirebaseStorage.instance
        .ref()
        .child('posts')
        .child(myUserName + time + '.jpg');

    await ref.putFile(img[0]);
    final url = await ref.getDownloadURL();
    print(url);
    return url;
  }

  Future<String> uploadUserImg(List<File> img, String myUserName) async {
    final ref = FirebaseStorage.instance
        .ref()
        .child('posts')
        .child(myUserName + '.jpg');

    await ref.putFile(img[0]);
    final url = await ref.getDownloadURL();
    print(url);
    return url;
  }

  Future<String> uploadVideo(
      List<File> video, String myUserName, String time) async {
    final ref = FirebaseStorage.instance
        .ref()
        .child('posts')
        .child(myUserName + time + '.mp4');

    var status = await ref.putFile(video[0]);
    print("status: $status");
    final url = await ref.getDownloadURL();
    print(url);
    return url;
  }

  Future<String> uploadFile(
      List<File> file, String myUserName, String time, String fileType) async {
    final ref = FirebaseStorage.instance
        .ref()
        .child('posts')
        .child(myUserName + time + '_' + fileType.split('_')[0]);

    await ref.putFile(file[0]);
    final url = await ref.getDownloadURL();
    return url;
  }

  Future uploadGroupImg(File img, String groupName) async {
    final ref = FirebaseStorage.instance
        .ref()
        .child('user_image')
        .child(groupName + '.jpg');

    await ref.putFile(img);

    final url = await ref.getDownloadURL();
    return url;
  }

  Future<String> getGroupMembers(String chatRoomId) async {
    DocumentSnapshot ds = await FirebaseFirestore.instance
        .collection("chatrooms")
        .doc(chatRoomId)
        .get();
    final String names = ds["users"].join(', ');
    return names;
  }
}
