import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  // Remove 'const' constructor or add 'const' if all fields are final/const
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
      ),
      body: const Center(
        child: Text('Home Screen'),
      ),
    );
  }
}