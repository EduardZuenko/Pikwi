import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pikwi/models/user.dart';
import 'package:pikwi/widgets/HeaderWidget.dart';
import 'package:pikwi/widgets/PostWidget.dart';
import 'package:pikwi/widgets/ProgressWidget.dart';
import 'package:pikwi/pages/HomePage.dart';

class TimeLinePage extends StatefulWidget {
  final User gCurrentUser;

  const TimeLinePage({this.gCurrentUser});

  @override
  _TimeLinePageState createState() => _TimeLinePageState();
}

class _TimeLinePageState extends State<TimeLinePage> {
  List<Post> posts;
  List<String> followingList =[];
  final scaffoldKey = GlobalKey<ScaffoldState>();

  void initState(){
    super.initState();

    retrieveTimeLine();
    retrieveFollowings();
  }

  retrieveTimeLine() async{
    QuerySnapshot querySnapshot = await timelineReference.document(widget.gCurrentUser.id).collection("timelinePosts").orderBy("timestamp", descending: true).getDocuments();

    List<Post> allPosts = querySnapshot.documents.map((document) => Post.fromDocument(document)).toList();

    setState(() {
      this.posts = allPosts;
    });
  }

  retrieveFollowings() async {
    QuerySnapshot querySnapshot = await followingReference.document(currentUser.id).collection("userFollowing").getDocuments();

    setState(() {
      followingList = querySnapshot.documents.map((document) => document.documentID).toList();
    });
  }

  createUserTimeLine(){
    if(posts == null){
      return circularProgress();
    }else{
      return ListView(children: posts,);
    }
  }

  @override
  Widget build(context) {
    return Scaffold (
      key: scaffoldKey,
      appBar: header(context, isAppTitle: true, ),
      body: RefreshIndicator(child: createUserTimeLine(), onRefresh: () => retrieveTimeLine()),
    );
  }
}
