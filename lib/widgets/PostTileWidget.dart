import 'package:flutter/material.dart';
import 'package:pikwi/pages/PostScreeenPage.dart';

import 'PostWidget.dart';

class PostTile extends StatelessWidget {
final Post post;

PostTile(this.post);

displayFullPost(context){
  Navigator.push(context, MaterialPageRoute(builder: (context) => PostScreenPage(postId: post.postId, userId: post.ownerId)));
}

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => displayFullPost(context),
      child: Image.network(post.url)
    );
  }
}
