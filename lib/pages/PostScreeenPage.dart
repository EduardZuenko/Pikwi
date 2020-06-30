import 'package:flutter/material.dart';
import 'package:pikwi/pages/HomePage.dart';
import 'package:pikwi/widgets/HeaderWidget.dart';
import 'package:pikwi/widgets/PostWidget.dart';
import 'package:pikwi/widgets/ProgressWidget.dart';

class PostScreenPage extends StatelessWidget {
final String userId;
final String postId;

PostScreenPage({
  this.postId,
  this.userId
});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: postReference.document(userId).collection("usersPosts").document(postId).get(),
      builder: (context, dataSnapshot){
        if(!dataSnapshot.hasData){
          return circularProgress();
        }

        Post post = Post.fromDocument(dataSnapshot.data);
        return Center(
          child: Scaffold(
            appBar: header(context, strTitle: post.description),
            body: ListView(
              children: <Widget>[
                Container(child: post,)
              ]
            ),
            ),
        );
      },
    );
  }
}
