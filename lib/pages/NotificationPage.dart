import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pikwi/pages/HomePage.dart';
import 'package:pikwi/pages/ProfilePage.dart';
import 'package:pikwi/widgets/HeaderWidget.dart';
import 'package:pikwi/widgets/ProgressWidget.dart';
import 'package:timeago/timeago.dart' as tAgo;

class NotificationsPage extends StatefulWidget {
  @override
  _NotificationsPageState createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: header(context, strTitle: "Notifications"),
      body: FutureBuilder(
        future: retrieveNotifications(),
        builder: (context, dataSnapshot){
          if(!dataSnapshot.hasData)
            {
              return circularProgress();
            }   
            return ListView(children: dataSnapshot.data);
            },
        ),
    );
  }

  retrieveNotifications() async {
  QuerySnapshot querySnapshot = await activityReference.document(currentUser.id )
    .collection("feedItems").orderBy("timestamp", descending: true)
    .limit(60).getDocuments();
     
  List<NotificationsItem> notificationsItems = [];

  querySnapshot.documents.forEach((document) {
    notificationsItems.add(NotificationsItem.fromDocument(document));
   });

   return notificationsItems;
}
}

String notificationsItemText;
Widget mediaPreview;


class NotificationsItem extends StatelessWidget {

  final String username;
  final String userId;
  final String type;
  final String userProfileImg;
  final String postId;
  final String url;
  final String commentData;
  final Timestamp timestamp;

  NotificationsItem({
    this.username,
    this.userId,
    this.url,
    this.timestamp,
    this.postId, 
    this.type, 
    this.userProfileImg, 
    this.commentData
  });

  factory NotificationsItem.fromDocument(DocumentSnapshot documentSnapshot){
    return NotificationsItem(
      username: documentSnapshot["username"],
      userId: documentSnapshot["userId"],
      type: documentSnapshot["type"],
      userProfileImg: documentSnapshot["userProfileImg"],
      postId: documentSnapshot["postId"],
      commentData: documentSnapshot["commentData"],
      url: documentSnapshot["url"],
      timestamp: documentSnapshot["timestamp"],
    );
  }

  @override
  Widget build(BuildContext context) {
    configureMediaPreview(context);

    return Padding(
      padding: EdgeInsets.only(bottom: 2.0),
      child: Container(
        color: Colors.white54,
        child: ListTile(
          title: GestureDetector(
            onTap: () => displayUserProfile(context, userProfileId: userId),
            child: RichText(
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                style: TextStyle(fontSize: 14.0, color: Colors.black),
                children: [
                  TextSpan(text: username, style: TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: "  $notificationsItemText")
                ]
              ),
            ),
          ),
          leading: CircleAvatar(
            backgroundImage: CachedNetworkImageProvider(userProfileImg),
          ),
          subtitle: Text(tAgo.format(timestamp.toDate()),overflow: TextOverflow.ellipsis,),
          trailing: mediaPreview,
          )
      )
      );
  }

  configureMediaPreview(context){
    if(type == "comment" || type == "like"){
      mediaPreview = GestureDetector(
        onTap: () => displayOwnProfile(context, userProfileId: currentUser.id),
        child: Container(
          height: 50.0,
          width: 50.0,
          child: AspectRatio(
            aspectRatio: 16/9,
            child: Container(
              decoration: BoxDecoration(image: DecorationImage(fit: BoxFit.cover, image: CachedNetworkImageProvider(url))
              )
            ),
          ),
        ),
      );
    }else{
      mediaPreview = Text("");
    }

    if(type == "like"){
      notificationsItemText = "liked your post";
    }
    else if(type == "comment"){
      notificationsItemText = "replied $commentData";
    }
    else if(type == "follow"){
      notificationsItemText = "is started following you";
    }
    else{
      notificationsItemText = "Error, Unknown type: $type"; 
    }
  }

  displayOwnProfile(context, {String userProfileId}){
    Navigator.push(context, MaterialPageRoute(builder: (context) => ProfilePage(userProfileId: currentUser.id,)));
  }

  displayUserProfile(BuildContext context, {String userProfileId}){
    Navigator.push(context, MaterialPageRoute(builder: (context) => ProfilePage(userProfileId: userProfileId,)));
  }
}
