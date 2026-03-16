import 'package:flutter/material.dart';
import '../models/post_model.dart';

class PostCard extends StatelessWidget {
  final Post post;

  PostCard({required this.post});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(10),
      elevation: 3,
      child: Padding(
        padding: EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(post.title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 5),
            Text(post.description),
            SizedBox(height: 5),
            Text("📍 ${post.location}", style: TextStyle(color: Colors.blue)),
            Text("📞 Contact: ${post.contact}", style: TextStyle(color: Colors.green)),
          ],
        ),
      ),
    );
  }
}
