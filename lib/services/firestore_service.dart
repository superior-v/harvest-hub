import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post_model.dart';

class FirestoreService {
  final CollectionReference postCollection = FirebaseFirestore.instance.collection('posts');

  Future<void> addPost(Post post) async {
    await postCollection.add(post.toMap());
  }

  Stream<List<Post>> getPosts() {
    return postCollection.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => Post.fromMap(doc.id, doc.data() as Map<String, dynamic>))
        .toList());
  }
}
