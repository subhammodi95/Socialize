import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:social_media_app/colors.dart';
import '/services/auth.dart';
import '/signin.dart';
import 'services/provider.dart';
import 'package:page_route_transition/page_route_transition.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:provider/provider.dart';
import './home.dart';
import 'package:google_fonts/google_fonts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // const MyApp({Key? key}) : super(key: key);
  void configOneSignel() {
    OneSignal.shared.setAppId("4d860999-7816-4eee-8c6e-656cf3e1afc9");
  }

  @override
  void initState() {
    configOneSignel();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    PageRouteTransition.effect = TransitionEffect.rightToLeft;

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge,
        overlays: [SystemUiOverlay.top]);

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle.dark.copyWith(
        statusBarBrightness: Brightness.dark,
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(
          value: Btn(),
        ),
        ChangeNotifierProvider.value(
          value: updateRowList(),
        )
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Socialize: A Social Media App',
        color: primaryColor,
        theme: ThemeData(
          scaffoldBackgroundColor: Color(0xfff2f7fa),
          useMaterial3: true,
          colorSchemeSeed: primaryColor,
          textTheme: GoogleFonts.manropeTextTheme(Theme.of(context).textTheme),
        ),
        home: FutureBuilder(
          future: AuthMethods().getCurrentUser(),
          builder: (context, AsyncSnapshot<dynamic> snapshot) {
            if (snapshot.hasData) {
              return Home();
            } else {
              return SignIn();
            }
          },
        ),
      ),
    );
  }
}
