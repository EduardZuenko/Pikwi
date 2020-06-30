import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:pikwi/models/user.dart';
import 'package:pikwi/pages/CreateAccountPage.dart';
import 'package:pikwi/pages/NotificationPage.dart';
import 'package:pikwi/pages/ProfilePage.dart';
import 'package:pikwi/pages/SearchPage.dart';
import 'package:pikwi/pages/TimeLinePage.dart';
import 'package:pikwi/pages/UploadPage.dart';

final GoogleSignIn gSignIn = GoogleSignIn();
final usersReference = Firestore.instance.collection("users");
final StorageReference storageReference= FirebaseStorage.instance.ref().child("Posts Pictures");
final postReference = Firestore.instance.collection("posts");
final activityReference = Firestore.instance.collection("feed");
final commentsReference = Firestore.instance.collection("comments");
final followersReference = Firestore.instance.collection("follow");
final followingReference = Firestore.instance.collection("following");
final timelineReference = Firestore.instance.collection("timeline");

final DateTime timestamp = DateTime.now();
User currentUser;


class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isSingedIn = false;
  int getPageIndex = 0; 
  PageController pageController;
  FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  void initState(){
    super.initState();

    pageController = PageController();

    gSignIn.onCurrentUserChanged.listen((gSignInAccount) { 
      controlSingIn(gSignInAccount);
    }, onError: (gError){
      print("Error Massage: " + gError);
    });
     
    gSignIn.signInSilently(suppressErrors: false).then((gSignInAccount) {
      controlSingIn(gSignInAccount);
    }).catchError((gError){
      print("Error Message: " + gError);
    });
  }

  controlSingIn(GoogleSignInAccount signInAccount) async{
    if(signInAccount!=null){
      await saveUserInfoToFireStore();  
      setState(() {
        isSingedIn = true;
      });

      configureRealTimePushNotifications();
    }else if(signInAccount==null){
      setState(() {
        isSingedIn = false;
      });      
    }
  }

  configureRealTimePushNotifications(){
    final GoogleSignInAccount gUser = gSignIn.currentUser;
    if(Platform.isIOS){
      getIOSPermissins();
    }

    _firebaseMessaging.getToken().then((token){
      usersReference.document(gUser.id).updateData({"androidNotificationToken": token});
    });

    _firebaseMessaging.configure(
      onMessage: (Map<String, dynamic>msg)async{
        final String recipientId = msg["data"]["recipient"];
        final String body = msg["notification"]["body"];

        if(recipientId == gUser.id){
          SnackBar snackBar = SnackBar(
            backgroundColor: Colors.grey,
            content: Text(body, style: TextStyle(color: Colors.black),overflow: TextOverflow.ellipsis,),
          );
          _scaffoldKey.currentState.showSnackBar(snackBar);
        }

      }
    );
  }

  getIOSPermissins(){
    _firebaseMessaging.requestNotificationPermissions(IosNotificationSettings(alert: true, badge: true, sound: true));

    _firebaseMessaging.onIosSettingsRegistered.listen((settings) { 
      print("Settings Registered : $settings");
    });
  }

  saveUserInfoToFireStore() async{
    final GoogleSignInAccount gCurrentUser = gSignIn.currentUser;
    DocumentSnapshot documentSnapshot = await usersReference.document(gCurrentUser.id).get();
    if(!documentSnapshot.exists){
      final username = await Navigator.push(context,MaterialPageRoute(builder: (context) => CreateAccountPage()));

      usersReference.document(gCurrentUser.id).setData({
      "id": gCurrentUser.id,
      "profileName": gCurrentUser.displayName,
      "username": username,
      "url": gCurrentUser.photoUrl,
      "email": gCurrentUser.email,
      "bio": "",
      "timestamp": timestamp 
    });

    await followingReference.document(gCurrentUser.id).collection("userFollowing").document(gCurrentUser.id).setData({});

    documentSnapshot = await usersReference.document(gCurrentUser.id).get();
    }   
    currentUser = User.fromDocument(documentSnapshot);
  }

  void dispose(){
    pageController.dispose();
    super.dispose();
  }

  loginUser(){
    gSignIn.signIn();
  }

  logoutUser(){
    gSignIn.signOut();
  }

  whenPageChanges(int pageIndex){
    setState((){
      this.getPageIndex = pageIndex;
    });
  }

  onTapChangePage(int pageIndex){
    pageController.animateToPage(pageIndex, duration: Duration(milliseconds: 400), curve: Curves.bounceInOut,);
  }

  Widget buildHomeScreen(){
    return Scaffold(
      key: _scaffoldKey,
      body: PageView(
        children: <Widget>[
          TimeLinePage(gCurrentUser: currentUser),
          SearchPage(),
          UploadPage(gCurrentUser: currentUser,),
          NotificationsPage(),
          ProfilePage(userProfileId: currentUser.id,),         
        ],
        controller: pageController,
        onPageChanged: whenPageChanges,
        physics: NeverScrollableScrollPhysics(),
      ),
      bottomNavigationBar: CupertinoTabBar(
        currentIndex: getPageIndex,
        onTap: onTapChangePage,
        backgroundColor: Theme.of(context).accentColor,
        activeColor: Colors.white,
        inactiveColor: Colors.blueGrey,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home)),
          BottomNavigationBarItem(icon: Icon(Icons.search)),
          BottomNavigationBarItem(icon: Icon(Icons.camera, size: 37.0,)),
          BottomNavigationBarItem(icon: Icon(Icons.favorite)),
          BottomNavigationBarItem(icon: Icon(Icons.person)),
        ],
      ),
    );
  }

  Scaffold buildSingedInScreen(){
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin:Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Theme.of(context).accentColor, Theme.of(context).primaryColor] 
          ),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Text("Pikwi", style: TextStyle(fontSize: 92.0, color: Colors.white),),
            GestureDetector(
              onTap: loginUser,
              child: Container(
                width: 270.0,
                height: 65.0,
                decoration: BoxDecoration(
                  image: DecorationImage(image: AssetImage("assets/images/google_signin_button.png"))                 
                ),
              )
            )
        ],)
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if(isSingedIn){
      return buildHomeScreen();
    }else{
      return buildSingedInScreen();
    }
  }
}
