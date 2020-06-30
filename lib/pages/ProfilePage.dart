import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pikwi/models/user.dart';
import 'package:pikwi/pages/EditProfilePage.dart';
import 'package:pikwi/pages/HomePage.dart';
import 'package:pikwi/widgets/HeaderWidget.dart';
import 'package:pikwi/widgets/PostTileWidget.dart';
import 'package:pikwi/widgets/PostWidget.dart';
import 'package:pikwi/widgets/ProgressWidget.dart';

class ProfilePage extends StatefulWidget {
  final String userProfileId;

  ProfilePage({this.userProfileId});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final String currentOnlineUserId = currentUser?.id;
  bool loading = false;
  int countPost = 0;
  String postOrientation = "grid";
  int countTotalFollowers = 0;
  int countTotalFollowings = 0;
  bool following = false;
  List<Post> postList = [];

  void initState(){
    super.initState();
    getAllProfilePosts();
    getAllFollowers();
    getAllFollowing();
    checkIfAlreadyFollowing();
  }

  getAllFollowers() async{
    QuerySnapshot querySnapshot = await followersReference.document(widget.userProfileId)
    .collection("userFollowers").getDocuments();

    setState(() {
      countTotalFollowers = querySnapshot.documents.length;
    });
  }

  getAllFollowing() async{
    QuerySnapshot querySnapshot = await followingReference.document(widget.userProfileId)
    .collection("userFollowing").getDocuments();

    setState(() {
      countTotalFollowings = querySnapshot.documents.length;
    });
  }

  checkIfAlreadyFollowing() async{
    DocumentSnapshot documentSnapshot = await followersReference
      .document(widget.userProfileId).collection("userFollowers")
      .document(currentOnlineUserId).get();

      setState(() {
        following = documentSnapshot.exists;
      });
  }

   createProfileTopView(){
     return FutureBuilder(
       future: usersReference.document(widget.userProfileId).get(),
       builder: (context, dataSnapshot){
         if(!dataSnapshot.hasData){
           return circularProgress();
         }
         User user = User.fromDocument(dataSnapshot.data);
         return Padding(
           padding: EdgeInsets.all(17.0),
           child: Column(
             children: <Widget>[
               Row(
                 children: <Widget>[
                   CircleAvatar(
                     radius: 45.0,
                     backgroundColor: Colors.grey,
                     backgroundImage: CachedNetworkImageProvider(user.url)
                   ),
                   Expanded(
                     flex: 1,
                     child: Column(
                       children: <Widget>[
                         Row(
                           mainAxisSize: MainAxisSize.max,
                           mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                           children: <Widget>[
                             createColums("posts", countPost),
                             createColums("followers", countTotalFollowers),
                             createColums("following", countTotalFollowings)
                           ],),
                           Row(
                             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                             children: <Widget>[
                               createButton(), 
                             ],
                           )
                       ],),)
                 ],),
                 Container(
                   alignment: Alignment.centerLeft,
                   padding: EdgeInsets.only(top: 13.0),
                   child: Text(
                     user.username,
                     style: TextStyle(fontSize: 14.0, color: Colors.white),
                   ),
                 ),
                 Container(
                   alignment: Alignment.centerLeft,
                   padding: EdgeInsets.only(top: 5.0),
                   child: Text(
                     user.profileName,
                     style: TextStyle(fontSize: 18.0, color: Colors.white),
                   ),
                 ),
                 Container(
                   alignment: Alignment.centerLeft,
                   padding: EdgeInsets.only(top: 3.0),
                   child: Text(
                     user.bio,
                     style: TextStyle(fontSize: 18.0, color: Colors.white70),
                   ),
                 ),
             ],),
         );
       },
       );
   }

   Column createColums(String title, int count){
     return Column(
       mainAxisSize: MainAxisSize.max,
       mainAxisAlignment: MainAxisAlignment.center,
       children: <Widget>[
         Text(
           count.toString(),
           style: TextStyle(fontSize: 20.0, color: Colors.white, fontWeight: FontWeight.bold),
           ),
           Container(
             margin: EdgeInsets.only(top: 5.0),
             child: Text(
               title,
               style: TextStyle(fontSize: 16.0, color: Colors.white, fontWeight: FontWeight.w400)
             ),
           )
       ],
     );
   }

   createButton(){
     bool ownProfile = currentOnlineUserId == widget.userProfileId;

     if(ownProfile){
       return createButtonTitleAndFunction(title: "Edit Profile", performFunction: editUserProfile,);
     }
     if(following){
       return createButtonTitleAndFunction(title: "Unfollow", performFunction: controlUnfollowUser,);
     }
     if(!following){
       return createButtonTitleAndFunction(title: "Follow", performFunction: controlFollowUser,);
     }
   }

   controlUnfollowUser(){
     setState(() {
       following = false;
     });

     followersReference.document(widget.userProfileId)
      .collection("userFollowers")
      .document(currentOnlineUserId)
      .get()
      .then((document){
        if(document.exists){
          document.reference.delete();
        }
      });

      followingReference.document(currentOnlineUserId)
      .collection("userFollowing")
      .document(widget.userProfileId)
      .get()
      .then((document){
        if(document.exists){
          document.reference.delete();
        }
      });

      activityReference.document(widget.userProfileId).collection("feedItems")
        .document(currentOnlineUserId).get().then((document){
          if(document.exists){
            document.reference.delete();
          }
        });
   }

   controlFollowUser(){
     setState(() {
       following = true;
     });
      followersReference.document(widget.userProfileId).collection("userFollowers")
      .document(currentOnlineUserId)
      .setData({});

      followingReference.document(currentOnlineUserId).collection("userFollowing")
      .document(widget.userProfileId)
      .setData({});

      activityReference.document(widget.userProfileId)
      .collection("feedItems").document(currentOnlineUserId)
      .setData({
        "type": "follow",
        "ownerId": widget.userProfileId,
        "username": currentUser.username,
        "timestamp": DateTime.now(),
        "userProfileImg": currentUser.url,
        "userId": currentOnlineUserId,
      });

   }

  Container createButtonTitleAndFunction({String title, Function performFunction}){
     return Container(
       padding: EdgeInsets.only(top: 3.0),
       child: FlatButton(
         onPressed: performFunction, 
         child: Container(
           width: 245.0,
           height: 26.0,
           child: Text(title, style: TextStyle(color: following ? Colors.grey : Colors.white70, fontWeight: FontWeight.bold)),
           alignment: Alignment.center,
           decoration: BoxDecoration(
             color: following ? Colors.black : Colors.white70,
             border: Border.all(color: following ? Colors.grey : Colors.grey),
             borderRadius: BorderRadius.circular(6.0)
           ),
         )),
     );
   }

   editUserProfile(){
     Navigator.push(context, MaterialPageRoute(builder: (context) => EditProfilePage(currentOnlineUserId: currentOnlineUserId)));
   }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: header(context, strTitle: "Profile"),
      body: ListView(
        children: <Widget>[
          createProfileTopView(),
          Divider(),
          createListAndGridPostOrientation(),
          Divider(height: 0.0),
          displayProfilePost()
        ]
      )
    );
  }

  displayProfilePost(){
    if(loading){
      return circularProgress();
    }else if(postList.isEmpty){
      return Container(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Padding(padding: EdgeInsets.all(30.0),
            child: Icon(Icons.photo_library, color: Colors.grey, size: 200.0,),
            ),
            Padding(padding: EdgeInsets.only(top: 20.0),
            child: Text("No Posts", style: TextStyle(color: Colors.redAccent, fontSize: 40.0, fontWeight: FontWeight.bold)),
            )
          ]
        ),
      );
    }else if(postOrientation == "grid"){
      List<GridTile> gridTilesList = [];
      postList.forEach((eachPost) { 
        gridTilesList.add(GridTile(child: PostTile(eachPost),));
      });
      return GridView.count(crossAxisCount: 3,
      childAspectRatio: 1.0,
      mainAxisSpacing: 1.5,
      crossAxisSpacing: 1.5,
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      children: gridTilesList,
      );
    }else if(postOrientation == "list"){
      return Column(
      children: postList,
      );
    }
    
  }

  getAllProfilePosts() async{
    setState(() {
      loading = true;
    });

    QuerySnapshot querySnapshot = await postReference.document(widget.userProfileId).collection("usersPosts").orderBy("timestamp", descending:true).getDocuments();
    setState(() {
      
      countPost = querySnapshot.documents.length;
      postList = querySnapshot.documents.map((documentSnapshot) => Post.fromDocument(documentSnapshot)).toList();
      loading = false;
    });
  }

  createListAndGridPostOrientation(){
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        IconButton(
          icon: Icon(Icons.grid_on),
          color: postOrientation == "grid" ? Theme.of(context).primaryColor : Colors.grey,
          onPressed: () => setOrientation("grid"),
          ),
          IconButton(
          icon: Icon(Icons.list),
          color: postOrientation == "list" ? Theme.of(context).primaryColor : Colors.grey,
          onPressed: () => setOrientation("list"),
          )],
    );
  }

  setOrientation(String orientation){
    setState(() {
      this.postOrientation = orientation;
    });
  }
}