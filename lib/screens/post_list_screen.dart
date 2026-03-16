import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../widgets/post_card.dart';

class PostListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirestoreService().getPosts(),
      builder: (context, AsyncSnapshot snapshot) {
        if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
        return ListView(
          children: snapshot.data.map<Widget>((post) => PostCard(post: post)).toList(),
        );
      },
    );
  }
}
