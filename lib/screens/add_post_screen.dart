import 'package:flutter/material.dart';
import '../models/post_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class AddPostScreen extends StatefulWidget {
  @override
  _AddPostScreenState createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController contactController = TextEditingController();
  final FirestoreService firestoreService = FirestoreService();
  final AuthService authService = AuthService();

  void addPost() async {
    if (titleController.text.isEmpty ||
        descriptionController.text.isEmpty ||
        locationController.text.isEmpty ||
        contactController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Please fill all fields"))
      );
      return;
    }

    Post newPost = Post(
      title: titleController.text,
      description: descriptionController.text,
      location: locationController.text,
      contact: contactController.text,
      userId: authService.currentUser?.uid ?? "guest",  // ✅ Allows guests to post
    );

    await firestoreService.addPost(newPost);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Set background color to white
      appBar: AppBar(
        title: Text("Add New Post"),
        backgroundColor: Color(0xFF8BC928), // Set app bar color
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: "Title",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0), // Rounded corners
                  ),
                  filled: true,
                  fillColor: Colors.grey[200], // Light gray background
                ),
              ),
              SizedBox(height: 20),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(
                  labelText: "Description",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0), // Rounded corners
                  ),
                  filled: true,
                  fillColor: Colors.grey[200], // Light gray background
                ),
              ),
              SizedBox(height: 20),
              TextField(
                controller: locationController,
                decoration: InputDecoration(
                  labelText: "Location",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0), // Rounded corners
                  ),
                  filled: true,
                  fillColor: Colors.grey[200], // Light gray background
                ),
              ),
              SizedBox(height: 20),
              TextField(
                controller: contactController,
                decoration: InputDecoration(
                  labelText: "Contact",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0), // Rounded corners
                  ),
                  filled: true,
                  fillColor: Colors.grey[200], // Light gray background
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: addPost,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0), // Rounded corners
                  ),
                  backgroundColor: Color(0xFF8BC928), // Set button color
                ),
                child: Text("Submit", style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
