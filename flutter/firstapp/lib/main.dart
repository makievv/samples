import 'dart:developer';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'MesiboPlugin.dart';
import 'firebase_options.dart';

class DemoUser {
  String token;
  String address;

  DemoUser(String t, String a) {
    token = t;
    address = a;
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    announcement: true,
    badge: true,
    carPlay: true,
    criticalAlert: true,
    provisional: true,
    sound: true,
  );

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Got a message whilst in the foreground!');
    print('Message data: ${message.data}');

    if (message.notification != null) {
      print('Message also contained a notification: ${message.notification}');
    }
  });

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  print('User granted permission: ${settings.authorizationStatus}');

  runApp(FirstMesiboApp());
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  await Firebase.initializeApp();

  print("Handling a background message: ${message.messageId}");
}

/// Home widget to display video chat option.
class FirstMesiboApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mesibo Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Text("First Mesibo App"),
        ),
        body: HomeWidget(),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

/// Widget to display start video call layout.
class HomeWidget extends StatefulWidget {
  @override
  _HomeWidgetState createState() => _HomeWidgetState();
}

class _HomeWidgetState extends State<HomeWidget> {
  static MesiboPluginApi _mesibo = MesiboPluginApi();
  static const callbacks = const MethodChannel("mesibo.com/callbacks");
  String _mesiboStatus = 'Mesibo status: Not Connected.';
  Text mStatusText;

  /* Refer to the tutorial to learn about users and token
   * https://mesibo.com/documentation/tutorials/get-started/
   * 
   * Create token for com.mesibo.firstapp using above tutorial and us here
   */
  DemoUser user1 = DemoUser("77c9e95ff0056444de1fb0a995ba9dc24992193cb6a2f54eaa41d5eaya91feebe884", 'user1@example.com');
  DemoUser user2 = DemoUser("8e67f96b9880df6d5a13b70de8167e059d73e759c82d5e9941d5e9ga5f81c70f76", 'user2@example.com');

  String remoteUser;
  bool mOnline = false, mLoginDone = false;
  ElevatedButton loginButton1, loginButton2;

  @override
  void initState() {
    super.initState();
    callbacks.setMethodCallHandler(callbackHandler);
  }

  void Mesibo_onConnectionStatus(int status) {
    print('Mesibo_onConnectionStatus: ' + status.toString());
    _mesiboStatus = 'Mesibo status: ' + status.toString();
    setState(() {});

    if (1 == status) mOnline = true;
  }

  Future<dynamic> callbackHandler(MethodCall methodCall) async {
    print('Native call!');
    var args = methodCall.arguments;
    switch (methodCall.method) {
      case "Mesibo_onConnectionStatus":
        Mesibo_onConnectionStatus(args['status'] as int);
        return "";
        break;
      default:
        return "";
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        InfoTitle(),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            loginButton1 = ElevatedButton(
              child: Text("Login as User-1"),
              onPressed: _loginUser1,
            ),
            loginButton2 = ElevatedButton(
              child: Text("Login as User-2"),
              onPressed: _loginUser2,
            ),
          ],
        ),
        mStatusText = Text(_mesiboStatus),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            ElevatedButton(
              child: Text("Show Messages"),
              onPressed: _showMessages,
            ),
          ],
        ),
        ElevatedButton(
          child: Text("Show User List"),
          onPressed: _showUserList,
        ),
        ElevatedButton(
          child: Text("Audio Call"),
          onPressed: _audioCall,
        ),
        ElevatedButton(
          child: Text("Video Call"),
          onPressed: _videoCall,
        ),
        ElevatedButton(
          child: Text("Set Push Token"),
          onPressed: _getFrToken,
        ),
      ],
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  void showAlert(String title, String body) {
    AlertDialog alert = AlertDialog(
      title: Text(title),
      content: Text(body),
    );
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  bool isOnline() {
    if (mOnline) return true;
    showAlert("Not Online", "First login with a valid token");
    return false;
  }

  void _loginUser1() {
    if (mLoginDone) {
      showAlert("Failed", "You have already initiated login. If the connection status is not 1, check the token and the package name/bundle ID");
      return;
    }
    mLoginDone = true;
    _mesibo.setup(user1.token);
    remoteUser = user2.address;
  }

  void _loginUser2() {
    if (mLoginDone) {
      showAlert("Failed", "You have already initiated login. If the connection status is not 1, check the token and the package name/bundle ID");
      return;
    }
    mLoginDone = true;
    _mesibo.setup(user2.token);
    remoteUser = user1.address;
  }

  void _showMessages() {
    if (!isOnline()) return;
    _mesibo.showMessages(remoteUser);
  }

  void _showUserList() {
    if (!isOnline()) return;
    _mesibo.showUserList();
  }

  void _audioCall() {
    if (!isOnline()) return;
    _mesibo.audioCall(remoteUser);
  }

  void _videoCall() {
    if (!isOnline()) return;
    _mesibo.videoCall(remoteUser);
  }

  Future<void> _getFrToken() async {
    // if (!isOnline()) return;
    final fcmToken = await FirebaseMessaging.instance.getToken();
    _mesibo.setPushToken(fcmToken, false);
    log('TOKEN ==== $fcmToken');
  }
}

/// Widget to display start video call title.
class InfoTitle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Center(
        child: Text(
          "Login as User-1 from one device and as User-2 from another!",
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
