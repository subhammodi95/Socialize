import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:social_media_app/admin/admin.dart';

import '../home.dart';
import './database.dart';
import './sharedPref_helper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthMethods {
  final FirebaseAuth auth = FirebaseAuth.instance;

  getCurrentUser() async {
    return await auth.currentUser;
  }

  signInWithGoogle(BuildContext context) async {
    final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
    final GoogleSignIn _googleSignIn = GoogleSignIn();

    final GoogleSignInAccount? googleSignInAccount =
        await _googleSignIn.signIn();

    final GoogleSignInAuthentication? googleSignInAuthentication =
        await googleSignInAccount!.authentication;

    final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleSignInAuthentication!.idToken,
        accessToken: googleSignInAuthentication.accessToken);

    UserCredential result =
        await _firebaseAuth.signInWithCredential(credential);

    User? userDetails = result.user;

    if (result != null) {
      //       Generate Token ID :-
      // -------------------------------------------
      var status = await OneSignal.shared.getDeviceState();
      String? tokenId = status!.userId;
      // print('Token ID ---> ' + tokenId!);
      await SharedPreferenceHelper().saveUserEmail(userDetails!.email);
      await SharedPreferenceHelper().saveUserId(userDetails.uid);
      await SharedPreferenceHelper()
          .saveUserName(userDetails.email!.replaceAll("@gmail.com", ""));
      await SharedPreferenceHelper()
          .saveDisplayName(userDetails.displayName!.replaceAll('_', ""));
      // await SharedPreferenceHelper().savePhoneNumber("");
      await SharedPreferenceHelper().saveUserProfileUrl(userDetails.photoURL);
      await SharedPreferenceHelper().savePhoneNumber("");

      Map<String, dynamic> userInfoMap = {
        "email": userDetails.email,
        "username": userDetails.email!.replaceAll("@gmail.com", ""),
        "name": userDetails.displayName!.replaceAll('_', ""),
        "imgUrl": userDetails.photoURL,
        "phone": "",
        "friends": [],
        "requests": [],
        "active": "1",
        "tokenId": tokenId
      };

      DatabaseMethods()
          .addUserInfoToDB(userDetails.uid, userInfoMap)
          .then((value) async {
        if (value == "user") {
          await SharedPreferenceHelper().saveIsAdmin("user");
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (context) => Home()));
        } else {
          await SharedPreferenceHelper().saveIsAdmin("admin");
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (context) => AdminScreen()));
        }
      });
    }
  }

  Future signOut() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.clear();
    await auth.signOut();
  }
}
